import Foundation

// MARK: - Export Data Models
// These map HomeKit's object graph into a portable JSON structure
// that the web app (or any LLM) can reason about.

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
