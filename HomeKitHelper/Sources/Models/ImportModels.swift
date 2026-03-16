import Foundation

// MARK: - Import Data Models
// The web app generates these "change sets" that the bridge applies to HomeKit.

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

// MARK: - Type-erased Codable wrapper
// HomeKit characteristic values can be Bool, Int, Double, or String.
// This wrapper handles encoding/decoding any of those.

struct AnyCodableValue: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

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
