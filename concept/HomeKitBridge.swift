// HomeKitBridge.swift
// HomeKit Helper - Native Bridge App
//
// PURPOSE: This is the native macOS/iOS component that talks to HomeKit.
// It exports the full home config as JSON and imports rename/scene changes back.
//
// BUILD REQUIREMENTS:
//   - Xcode project with Mac Catalyst target (HomeKit is iOS-origin framework)
//   - Entitlement: com.apple.developer.homekit = true
//   - Info.plist: NSHomeKitUsageDescription
//   - Signing: Development team with HomeKit capability enabled
//   - Minimum: macOS 14+ / iOS 17+

import Foundation
import HomeKit

// MARK: - Export Data Models

struct HomeExport: Codable {
    let exportDate: String
    let appVersion: String
    let homes: [HomeData]
}

struct HomeData: Codable {
    let homeId: String
    let homeName: String
    let rooms: [RoomData]
    let accessories: [AccessoryData]
    let scenes: [SceneData]
    let zones: [ZoneData]
}

struct RoomData: Codable {
    let roomId: String
    let roomName: String
    let accessoryCount: Int
}

struct ZoneData: Codable {
    let zoneId: String
    let zoneName: String
    let roomIds: [String]
}

struct AccessoryData: Codable {
    let accessoryId: String
    let name: String
    let roomName: String
    let roomId: String
    let category: String
    let manufacturer: String
    let model: String
    let firmwareVersion: String
    let isReachable: Bool
    let isBridged: Bool
    let services: [ServiceData]
}

struct ServiceData: Codable {
    let serviceId: String
    let name: String
    let serviceType: String
    let isPrimary: Bool
    let characteristics: [CharacteristicData]
}

struct CharacteristicData: Codable {
    let characteristicId: String
    let description: String
    let characteristicType: String
    let value: String?
    let isReadable: Bool
    let isWritable: Bool
}

struct SceneData: Codable {
    let sceneId: String
    let sceneName: String
    let actionCount: Int
    let isExecuting: Bool
}

// MARK: - Import Data Models

struct HomeImport: Codable {
    let homeId: String
    let renames: [RenameAction]
    let roomAssignments: [RoomAssignment]
    let newScenes: [NewScene]
    let newRooms: [NewRoom]
}

struct RenameAction: Codable {
    let accessoryId: String
    let currentName: String
    let newName: String
}

struct RoomAssignment: Codable {
    let accessoryId: String
    let newRoomId: String?
    let newRoomName: String?
}

struct NewScene: Codable {
    let sceneName: String
    let actions: [SceneAction]
}

struct SceneAction: Codable {
    let accessoryId: String
    let serviceType: String
    let characteristicType: String
    let targetValue: AnyCodableValue
}

struct NewRoom: Codable {
    let roomName: String
    let zone: String?
}

struct AnyCodableValue: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) { value = b }
        else if let i = try? container.decode(Int.self) { value = i }
        else if let d = try? container.decode(Double.self) { value = d }
        else if let s = try? container.decode(String.self) { value = s }
        else { value = "null" }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let b as Bool: try container.encode(b)
        case let i as Int: try container.encode(i)
        case let d as Double: try container.encode(d)
        case let s as String: try container.encode(s)
        default: try container.encode("null")
        }
    }
}

// MARK: - HomeKit Bridge Manager

final class HomeKitBridge: NSObject, HMHomeManagerDelegate {
    private let homeManager = HMHomeManager()
    private var onHomesReady: (([HMHome]) -> Void)?

    override init() {
        super.init()
        homeManager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        onHomesReady?(manager.homes)
    }

    // MARK: Export

    func exportAll(completion: @escaping (HomeExport) -> Void) {
        onHomesReady = { homes in
            let formatter = ISO8601DateFormatter()
            let export = HomeExport(
                exportDate: formatter.string(from: Date()),
                appVersion: "1.0.0",
                homes: homes.map { self.mapHome($0) }
            )
            completion(export)
        }
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
            accessories: home.accessories.map { acc in
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
                            characteristics: svc.characteristics.map { char in
                                CharacteristicData(
                                    characteristicId: char.uniqueIdentifier.uuidString,
                                    description: char.localizedDescription,
                                    characteristicType: char.characteristicType,
                                    value: char.value.map { "\($0)" },
                                    isReadable: char.properties.contains(HMCharacteristicPropertyReadable),
                                    isWritable: char.properties.contains(HMCharacteristicPropertyWritable)
                                )
                            }
                        )
                    }
                )
            },
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

    // MARK: Import

    func applyChanges(_ importData: HomeImport, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let home = homeManager.homes.first(where: { $0.uniqueIdentifier.uuidString == importData.homeId }) else {
            completion(.failure(NSError(domain: "HomeKitBridge", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Home not found"])))
            return
        }

        var log: [String] = []
        let group = DispatchGroup()

        // 1. Create new rooms
        for newRoom in importData.newRooms {
            group.enter()
            home.addRoom(withName: newRoom.roomName) { room, error in
                if let error = error {
                    log.append("FAIL: Create room '\(newRoom.roomName)' - \(error.localizedDescription)")
                } else {
                    log.append("OK: Created room '\(newRoom.roomName)'")
                    if let zoneName = newRoom.zone, let room = room,
                       let zone = home.zones.first(where: { $0.name == zoneName }) {
                        group.enter()
                        zone.addRoom(room) { error in
                            if let e = error { log.append("FAIL: Zone assign - \(e.localizedDescription)") }
                            else { log.append("OK: Added to zone '\(zoneName)'") }
                            group.leave()
                        }
                    }
                }
                group.leave()
            }
        }

        // 2. Rename accessories
        for rename in importData.renames {
            if let acc = home.accessories.first(where: { $0.uniqueIdentifier.uuidString == rename.accessoryId }) {
                group.enter()
                acc.updateName(rename.newName) { error in
                    if let e = error { log.append("FAIL: Rename '\(rename.currentName)' - \(e.localizedDescription)") }
                    else { log.append("OK: '\(rename.currentName)' -> '\(rename.newName)'") }
                    group.leave()
                }
            } else { log.append("SKIP: Not found \(rename.accessoryId)") }
        }

        // 3. Room assignments
        for assignment in importData.roomAssignments {
            if let acc = home.accessories.first(where: { $0.uniqueIdentifier.uuidString == assignment.accessoryId }) {
                let room = assignment.newRoomId.flatMap { id in home.rooms.first { $0.uniqueIdentifier.uuidString == id } }
                    ?? assignment.newRoomName.flatMap { name in home.rooms.first { $0.name == name } }
                if let room = room {
                    group.enter()
                    home.assignAccessory(acc, to: room) { error in
                        if let e = error { log.append("FAIL: Move '\(acc.name)' - \(e.localizedDescription)") }
                        else { log.append("OK: Moved '\(acc.name)' to '\(room.name)'") }
                        group.leave()
                    }
                }
            }
        }

        // 4. Create scenes
        for newScene in importData.newScenes {
            group.enter()
            home.addActionSet(withName: newScene.sceneName, type: .userDefined) { actionSet, error in
                if let error = error {
                    log.append("FAIL: Scene '\(newScene.sceneName)' - \(error.localizedDescription)")
                    group.leave()
                    return
                }
                guard let actionSet = actionSet else { group.leave(); return }
                log.append("OK: Created scene '\(newScene.sceneName)'")
                for sa in newScene.actions {
                    if let acc = home.accessories.first(where: { $0.uniqueIdentifier.uuidString == sa.accessoryId }),
                       let svc = acc.services.first(where: { $0.serviceType == sa.serviceType }),
                       let chr = svc.characteristics.first(where: { $0.characteristicType == sa.characteristicType }) {
                        let action = HMCharacteristicWriteAction(characteristic: chr, targetValue: sa.targetValue.value as! NSCopying)
                        group.enter()
                        actionSet.addAction(action) { error in
                            if let e = error { log.append("FAIL: Action - \(e.localizedDescription)") }
                            group.leave()
                        }
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { completion(.success(log)) }
    }
}

// MARK: - CLI Entry Point

let bridge = HomeKitBridge()
bridge.exportAll { export in
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(export),
       let json = String(data: data, encoding: .utf8) {
        let path = NSHomeDirectory() + "/Desktop/homekit_export.json"
        try? json.write(toFile: path, atomically: true, encoding: .utf8)
        print("Exported to: " + path)
        print(json)
    }
    exit(0)
}

RunLoop.main.run(until: Date(timeIntervalSinceNow: 30))
print("Timeout: No HomeKit data received.")
exit(1)
