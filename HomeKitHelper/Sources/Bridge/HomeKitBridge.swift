import Foundation
import HomeKit
import Observation

// MARK: - HomeKit Bridge Manager
// The single point of contact with Apple's HomeKit framework.
// Wraps the callback-based HMHomeManager API in an @Observable class
// so SwiftUI views react automatically.

@Observable
final class HomeKitBridge: NSObject, HMHomeManagerDelegate {
    private let homeManager = HMHomeManager()

    private(set) var homes: [HMHome] = []
    var isLoading = true
    var lastExport: HomeExport?
    var importLog: [LogEntry] = []
    var errorMessage: String?

    var homeSummaries: [HomeSummary] {
        homes.map { home in
            HomeSummary(
                id: home.uniqueIdentifier.uuidString,
                name: home.name,
                accessoryCount: home.accessories.count,
                roomCount: home.rooms.count,
                sceneCount: home.actionSets.count
            )
        }
    }

    var hasHomes: Bool { !homes.isEmpty }

    override init() {
        super.init()
        homeManager.delegate = self
    }

    // MARK: - HMHomeManagerDelegate

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        homes = manager.homes
        isLoading = false
    }

    // MARK: - Refresh

    func refresh() {
        isLoading = true
        homes = homeManager.homes
        isLoading = false
    }

    // MARK: - Export

    func exportAll() -> HomeExport {
        let formatter = ISO8601DateFormatter()
        let export = HomeExport(
            exportDate: formatter.string(from: Date()),
            appVersion: "0.1.0",
            homes: homes.map { mapHome($0) }
        )
        lastExport = export
        return export
    }

    func exportJSON() -> String? {
        let export = exportAll()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(export) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func mapHome(_ home: HMHome) -> HomeData {
        HomeData(
            homeId: home.uniqueIdentifier.uuidString,
            homeName: home.name,
            rooms: home.rooms.map { room in
                RoomData(
                    roomId: room.uniqueIdentifier.uuidString,
                    roomName: room.name,
                    accessoryCount: room.accessories.count
                )
            },
            accessories: home.accessories.map { mapAccessory($0) },
            scenes: home.actionSets.map { scene in
                SceneData(
                    sceneId: scene.uniqueIdentifier.uuidString,
                    sceneName: scene.name,
                    actionCount: scene.actions.count,
                    isExecuting: scene.isExecuting
                )
            },
            zones: home.zones.map { zone in
                ZoneData(
                    zoneId: zone.uniqueIdentifier.uuidString,
                    zoneName: zone.name,
                    roomIds: zone.rooms.map { $0.uniqueIdentifier.uuidString }
                )
            }
        )
    }

    private func mapAccessory(_ acc: HMAccessory) -> AccessoryData {
        AccessoryData(
            accessoryId: acc.uniqueIdentifier.uuidString,
            name: acc.name,
            roomName: acc.room?.name ?? "Unassigned",
            roomId: acc.room?.uniqueIdentifier.uuidString ?? "",
            category: acc.category.categoryType,
            manufacturer: acc.manufacturer ?? "Unknown",
            model: acc.model ?? "Unknown",
            firmwareVersion: acc.firmwareVersion ?? "Unknown",
            isReachable: acc.isReachable,
            isBridged: acc.isBridged,
            services: acc.services.map { svc in
                ServiceData(
                    serviceId: svc.uniqueIdentifier.uuidString,
                    name: svc.name,
                    serviceType: svc.serviceType,
                    isPrimary: svc.isPrimaryService,
                    characteristics: svc.characteristics.map { chr in
                        CharacteristicData(
                            characteristicId: chr.uniqueIdentifier.uuidString,
                            description: chr.localizedDescription,
                            characteristicType: chr.characteristicType,
                            value: chr.value.map { "\($0)" },
                            isReadable: chr.properties.contains(HMCharacteristicPropertyReadable),
                            isWritable: chr.properties.contains(HMCharacteristicPropertyWritable)
                        )
                    }
                )
            }
        )
    }

    // MARK: - Import

    func applyChanges(from json: String) async -> ImportResultSummary {
        importLog = []

        guard let data = json.data(using: .utf8) else {
            appendLog(.failure, "Invalid JSON encoding")
            return currentSummary()
        }

        let importData: HomeImport
        do {
            importData = try JSONDecoder().decode(HomeImport.self, from: data)
        } catch {
            appendLog(.failure, "JSON parse error: \(error.localizedDescription)")
            return currentSummary()
        }

        guard let home = homes.first(where: { $0.uniqueIdentifier.uuidString == importData.homeId }) else {
            appendLog(.failure, "Home not found: \(importData.homeId)")
            return currentSummary()
        }

        // 1. Create new zones first (rooms may reference them)
        for newZone in importData.newZones {
            await createZone(newZone, in: home)
        }

        // 2. Create new rooms (other operations may depend on them)
        for newRoom in importData.newRooms {
            await createRoom(newRoom, in: home)
        }

        // 2.5. Zone-room assignments (add/remove rooms from zones)
        for assignment in importData.zoneRoomAssignments {
            await assignRoomToZone(assignment, in: home)
        }

        // 3. Rename accessories
        for rename in importData.renames {
            await renameAccessory(rename, in: home)
        }

        // 4. Room assignments
        for assignment in importData.roomAssignments {
            await assignRoom(assignment, in: home)
        }

        // 5. Create scenes
        for newScene in importData.newScenes {
            await createScene(newScene, in: home)
        }

        // 6. Update existing scenes
        for sceneUpdate in importData.updateScenes {
            await updateScene(sceneUpdate, in: home)
        }

        // 7. Delete scenes
        for sceneDeletion in importData.deleteScenes {
            await deleteScene(sceneDeletion, in: home)
        }

        // 8. Delete rooms
        for roomDeletion in importData.deleteRooms {
            await deleteRoom(roomDeletion, in: home)
        }

        // 9. Delete zones
        for zoneDeletion in importData.deleteZones {
            await deleteZone(zoneDeletion, in: home)
        }

        return currentSummary()
    }

    private func currentSummary() -> ImportResultSummary {
        let succeeded = importLog.filter { $0.status == .success }.count
        let failed = importLog.filter { $0.status == .failure }.count
        let skipped = importLog.filter { $0.status == .skipped }.count
        return ImportResultSummary(succeeded: succeeded, failed: failed, skipped: skipped)
    }

    // MARK: - Import Helpers
    // HomeKit uses completion-handler APIs, so we wrap them with continuations.

    private func createRoom(_ newRoom: NewRoom, in home: HMHome) async {
        do {
            let room: HMRoom = try await withCheckedThrowingContinuation { cont in
                home.addRoom(withName: newRoom.roomName) { room, error in
                    if let error { cont.resume(throwing: error) }
                    else if let room { cont.resume(returning: room) }
                    else { cont.resume(throwing: self.bridgeError("No room returned")) }
                }
            }
            appendLog(.success, "Created room '\(newRoom.roomName)'")

            if let zoneName = newRoom.zone,
               let zone = home.zones.first(where: { $0.name == zoneName }) {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    zone.addRoom(room) { error in
                        if let error { cont.resume(throwing: error) }
                        else { cont.resume() }
                    }
                }
                appendLog(.success, "Added '\(newRoom.roomName)' to zone '\(zoneName)'")
            }
        } catch {
            appendLog(.failure, "Create room '\(newRoom.roomName)': \(error.localizedDescription)")
        }
    }

    private func deleteRoom(_ deleteRoom: DeleteRoom, in home: HMHome) async {
        guard let room = home.rooms.first(where: {
            $0.uniqueIdentifier.uuidString == deleteRoom.roomId
        }) else {
            appendLog(.skipped, "Room not found for deletion: \(deleteRoom.roomId)")
            return
        }

        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                home.removeRoom(room) { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            }
            appendLog(.success, "Deleted room '\(room.name)'")
        } catch {
            appendLog(.failure, "Delete room '\(room.name)': \(error.localizedDescription)")
        }
    }

    private func renameAccessory(_ rename: RenameAction, in home: HMHome) async {
        guard let acc = home.accessories.first(where: {
            $0.uniqueIdentifier.uuidString == rename.accessoryId
        }) else {
            appendLog(.skipped, "Accessory not found: \(rename.currentName) (\(rename.accessoryId))")
            return
        }

        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                acc.updateName(rename.newName) { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            }
            appendLog(.success, "'\(rename.currentName)' → '\(rename.newName)'")
        } catch {
            appendLog(.failure, "Rename '\(rename.currentName)': \(error.localizedDescription)")
        }
    }

    private func assignRoom(_ assignment: RoomAssignment, in home: HMHome) async {
        guard let acc = home.accessories.first(where: {
            $0.uniqueIdentifier.uuidString == assignment.accessoryId
        }) else {
            appendLog(.skipped, "Accessory not found: \(assignment.accessoryId)")
            return
        }

        let room = assignment.newRoomId.flatMap { id in
            home.rooms.first { $0.uniqueIdentifier.uuidString == id }
        } ?? assignment.newRoomName.flatMap { name in
            home.rooms.first { $0.name == name }
        }

        guard let room else {
            appendLog(.failure, "Room not found for accessory '\(acc.name)'")
            return
        }

        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                home.assignAccessory(acc, to: room) { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            }
            appendLog(.success, "Moved '\(acc.name)' → '\(room.name)'")
        } catch {
            appendLog(.failure, "Move '\(acc.name)': \(error.localizedDescription)")
        }
    }

    private func createScene(_ newScene: NewScene, in home: HMHome) async {
        do {
            let actionSet: HMActionSet = try await withCheckedThrowingContinuation { cont in
                home.addActionSet(withName: newScene.sceneName) { actionSet, error in
                    if let error { cont.resume(throwing: error) }
                    else if let actionSet { cont.resume(returning: actionSet) }
                    else { cont.resume(throwing: self.bridgeError("No action set returned")) }
                }
            }
            appendLog(.success, "Created scene '\(newScene.sceneName)'")

            for sa in newScene.actions {
                guard let acc = home.accessories.first(where: {
                    $0.uniqueIdentifier.uuidString == sa.accessoryId
                }),
                let svc = acc.services.first(where: { $0.serviceType == sa.serviceType }),
                let chr = svc.characteristics.first(where: { $0.characteristicType == sa.characteristicType })
                else {
                    appendLog(.skipped, "Scene action skipped: accessory/service/characteristic not found for \(sa.accessoryId)")
                    continue
                }

                guard let targetVal = sa.targetValue.value as? NSCopying else {
                    appendLog(.failure, "Scene action failed: unsupported target value type for \(sa.accessoryId)")
                    continue
                }

                let action = HMCharacteristicWriteAction(
                    characteristic: chr,
                    targetValue: targetVal
                )
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    actionSet.addAction(action) { error in
                        if let error { cont.resume(throwing: error) }
                        else { cont.resume() }
                    }
                }
            }
        } catch {
            appendLog(.failure, "Scene '\(newScene.sceneName)': \(error.localizedDescription)")
        }
    }

    private func deleteScene(_ deleteScene: DeleteScene, in home: HMHome) async {
        guard let actionSet = home.actionSets.first(where: {
            $0.uniqueIdentifier.uuidString == deleteScene.sceneId
        }) else {
            appendLog(.skipped, "Scene not found for deletion: \(deleteScene.sceneId)")
            return
        }

        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                home.removeActionSet(actionSet) { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            }
            appendLog(.success, "Deleted scene '\(actionSet.name)'")
        } catch {
            appendLog(.failure, "Delete scene '\(actionSet.name)': \(error.localizedDescription)")
        }
    }

    private func updateScene(_ update: UpdateScene, in home: HMHome) async {
        guard let actionSet = home.actionSets.first(where: {
            $0.uniqueIdentifier.uuidString == update.sceneId
        }) else {
            appendLog(.skipped, "Scene not found for update: \(update.sceneId)")
            return
        }

        // Remove existing actions
        for action in actionSet.actions {
            do {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    actionSet.removeAction(action) { error in
                        if let error { cont.resume(throwing: error) }
                        else { cont.resume() }
                    }
                }
            } catch {
                appendLog(.failure, "Remove old action from '\(actionSet.name)': \(error.localizedDescription)")
            }
        }

        // Rename if provided
        if let newName = update.newSceneName {
            do {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    actionSet.updateName(newName) { error in
                        if let error { cont.resume(throwing: error) }
                        else { cont.resume() }
                    }
                }
                appendLog(.success, "Renamed scene to '\(newName)'")
            } catch {
                appendLog(.failure, "Rename scene '\(actionSet.name)': \(error.localizedDescription)")
            }
        }

        // Add new actions
        for sa in update.actions {
            guard let acc = home.accessories.first(where: {
                $0.uniqueIdentifier.uuidString == sa.accessoryId
            }),
            let svc = acc.services.first(where: { $0.serviceType == sa.serviceType }),
            let chr = svc.characteristics.first(where: { $0.characteristicType == sa.characteristicType })
            else {
                appendLog(.skipped, "Update scene action skipped: accessory/service/characteristic not found for \(sa.accessoryId)")
                continue
            }

            guard let targetVal = sa.targetValue.value as? NSCopying else {
                appendLog(.failure, "Update scene action failed: unsupported target value type for \(sa.accessoryId)")
                continue
            }

            let action = HMCharacteristicWriteAction(
                characteristic: chr,
                targetValue: targetVal
            )
            do {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    actionSet.addAction(action) { error in
                        if let error { cont.resume(throwing: error) }
                        else { cont.resume() }
                    }
                }
            } catch {
                appendLog(.failure, "Add action to '\(actionSet.name)': \(error.localizedDescription)")
            }
        }

        appendLog(.success, "Updated scene '\(actionSet.name)'")
    }

    private func createZone(_ newZone: NewZone, in home: HMHome) async {
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                home.addZone(withName: newZone.zoneName) { _, error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            }
            appendLog(.success, "Created zone '\(newZone.zoneName)'")
        } catch {
            appendLog(.failure, "Create zone '\(newZone.zoneName)': \(error.localizedDescription)")
        }
    }

    private func assignRoomToZone(_ assignment: ZoneRoomAssignment, in home: HMHome) async {
        guard let zone = home.zones.first(where: { $0.name == assignment.zoneName }) else {
            appendLog(.skipped, "Zone '\(assignment.zoneName)' not found for room assignment")
            return
        }

        guard let room = home.rooms.first(where: {
            $0.uniqueIdentifier.uuidString == assignment.roomId
        }) else {
            appendLog(.skipped, "Room not found: \(assignment.roomId)")
            return
        }

        do {
            if assignment.action == "add" {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    zone.addRoom(room) { error in
                        if let error { cont.resume(throwing: error) }
                        else { cont.resume() }
                    }
                }
                appendLog(.success, "Added '\(room.name)' to zone '\(assignment.zoneName)'")
            } else {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    zone.removeRoom(room) { error in
                        if let error { cont.resume(throwing: error) }
                        else { cont.resume() }
                    }
                }
                appendLog(.success, "Removed '\(room.name)' from zone '\(assignment.zoneName)'")
            }
        } catch {
            appendLog(.failure, "\(assignment.action) '\(room.name)' \(assignment.action == "add" ? "to" : "from") zone '\(assignment.zoneName)': \(error.localizedDescription)")
        }
    }

    private func deleteZone(_ deleteZone: DeleteZone, in home: HMHome) async {
        guard let zone = home.zones.first(where: {
            $0.uniqueIdentifier.uuidString == deleteZone.zoneId
        }) else {
            appendLog(.skipped, "Zone not found for deletion: \(deleteZone.zoneId)")
            return
        }

        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                home.removeZone(zone) { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            }
            appendLog(.success, "Deleted zone '\(zone.name)'")
        } catch {
            appendLog(.failure, "Delete zone '\(zone.name)': \(error.localizedDescription)")
        }
    }

    private func bridgeError(_ message: String) -> NSError {
        NSError(domain: "HomeKitBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    // MARK: - Logging

    private func appendLog(_ status: LogEntry.Status, _ message: String) {
        importLog.append(LogEntry(timestamp: Date(), status: status, message: message))
    }
}
