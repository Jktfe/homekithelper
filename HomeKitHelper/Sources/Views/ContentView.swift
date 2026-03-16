import SwiftUI

struct ContentView: View {
    @Bindable var bridge: HomeKitBridge
    @State private var selectedTab: Tab = .export
    @State private var exportedJSON: String = ""
    @State private var importJSON: String = ""
    @State private var showCopiedToast = false

    enum Tab: String, CaseIterable {
        case export = "Export"
        case `import` = "Import"
        case log = "Log"
    }

    var body: some View {
        NavigationStack {
            Group {
                if bridge.isLoading {
                    LoadingView()
                } else if !bridge.hasHomes {
                    NoHomesView()
                } else {
                    TabView(selection: $selectedTab) {
                        ExportTab(
                            bridge: bridge,
                            exportedJSON: $exportedJSON,
                            showCopiedToast: $showCopiedToast
                        )
                        .tag(Tab.export)
                        .tabItem { Label("Export", systemImage: "square.and.arrow.up") }

                        ImportTab(
                            bridge: bridge,
                            importJSON: $importJSON
                        )
                        .tag(Tab.import)
                        .tabItem { Label("Import", systemImage: "square.and.arrow.down") }

                        LogTab(entries: bridge.importLog)
                            .tag(Tab.log)
                            .tabItem { Label("Log", systemImage: "list.bullet.clipboard") }
                    }
                }
            }
            .navigationTitle("HomeKit Helper")
            .overlay(alignment: .top) {
                if showCopiedToast {
                    CopiedToast()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
}

// MARK: - Loading State

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Connecting to HomeKit…")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty State

private struct NoHomesView: View {
    var body: some View {
        ContentUnavailableView(
            "No Homes Found",
            systemImage: "house.slash",
            description: Text("Make sure you have at least one home set up in the Home app, and that you've granted HomeKit access.")
        )
    }
}

// MARK: - Copied Toast

private struct CopiedToast: View {
    var body: some View {
        Text("Copied to clipboard")
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: Capsule())
            .padding(.top, 8)
    }
}
