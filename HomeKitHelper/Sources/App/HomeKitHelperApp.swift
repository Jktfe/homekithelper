import SwiftUI

@main
struct HomeKitHelperApp: App {
    @State private var bridge = HomeKitBridge()

    var body: some Scene {
        WindowGroup {
            ContentView(bridge: bridge)
        }
    }
}
