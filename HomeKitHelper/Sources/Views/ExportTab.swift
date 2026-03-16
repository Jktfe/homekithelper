import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ExportTab: View {
    @Bindable var bridge: HomeKitBridge
    @Binding var exportedJSON: String
    @Binding var showCopiedToast: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(bridge.homeSummaries) { summary in
                    HomeSummaryCard(summary: summary)
                }

                Button {
                    export()
                } label: {
                    Label("Export Configuration", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                if !exportedJSON.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Exported JSON")
                                .font(.headline)
                            Spacer()
                            Button("Copy", systemImage: "doc.on.doc") {
                                copyToClipboard(exportedJSON)
                            }
                            .buttonStyle(.bordered)

                            Button("Save to File", systemImage: "folder") {
                                saveToFile(exportedJSON)
                            }
                            .buttonStyle(.bordered)
                        }

                        Text(exportedJSON)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
        }
    }

    private func export() {
        exportedJSON = bridge.exportJSON() ?? "Export failed"
    }

    private func copyToClipboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif

        withAnimation { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showCopiedToast = false }
        }
    }

    private func saveToFile(_ text: String) {
        let desktopPath = NSHomeDirectory() + "/Desktop/homekit_export.json"
        try? text.write(toFile: desktopPath, atomically: true, encoding: .utf8)
    }
}

// MARK: - Home Summary Card

private struct HomeSummaryCard: View {
    let summary: HomeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text(summary.name)
                    .font(.title2.weight(.semibold))
            }

            HStack(spacing: 24) {
                StatBadge(count: summary.accessoryCount, label: "Accessories", icon: "lightbulb")
                StatBadge(count: summary.roomCount, label: "Rooms", icon: "door.left.hand.open")
                StatBadge(count: summary.sceneCount, label: "Scenes", icon: "theatermasks")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatBadge: View {
    let count: Int
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.title3.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
