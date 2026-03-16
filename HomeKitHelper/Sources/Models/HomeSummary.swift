import Foundation

// View-friendly summary of a HomeKit home.
// Decouples views from the HomeKit framework.

struct HomeSummary: Identifiable {
    let id: String
    let name: String
    let accessoryCount: Int
    let roomCount: Int
    let sceneCount: Int
}
