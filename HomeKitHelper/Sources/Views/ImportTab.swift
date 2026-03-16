import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ImportTab: View {
    @Bindable var bridge: HomeKitBridge
    @Binding var importJSON: String
    @State private var isProcessing = false
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import Changes")
                        .font(.headline)
                    Text("Paste the change set JSON from the web app, then tap Apply to update your HomeKit configuration.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // JSON input area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Change Set JSON")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Button("Paste from Clipboard") {
                            pasteFromClipboard()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    TextEditor(text: $importJSON)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }

                // Preview parsed changes
                if let preview = parsePreview() {
                    ImportPreview(preview: preview)
                }

                // Apply button
                Button {
                    showConfirmation = true
                } label: {
                    if isProcessing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        Label("Apply Changes", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(importJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                .confirmationDialog("Apply Changes?", isPresented: $showConfirmation) {
                    Button("Apply") {
                        applyChanges()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will modify your HomeKit configuration. Changes cannot be undone automatically.")
                }
            }
            .padding()
        }
    }

    private func pasteFromClipboard() {
        #if canImport(UIKit)
        importJSON = UIPasteboard.general.string ?? ""
        #elseif canImport(AppKit)
        importJSON = NSPasteboard.general.string(forType: .string) ?? ""
        #endif
    }

    private func parsePreview() -> ImportPreviewData? {
        guard !importJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let data = importJSON.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(HomeImport.self, from: data)
        else { return nil }

        return ImportPreviewData(
            renameCount: parsed.renames.count,
            roomAssignmentCount: parsed.roomAssignments.count,
            newSceneCount: parsed.newScenes.count,
            newRoomCount: parsed.newRooms.count
        )
    }

    private func applyChanges() {
        isProcessing = true
        Task {
            await bridge.applyChanges(from: importJSON)
            isProcessing = false
        }
    }
}

// MARK: - Import Preview

struct ImportPreviewData {
    let renameCount: Int
    let roomAssignmentCount: Int
    let newSceneCount: Int
    let newRoomCount: Int

    var totalChanges: Int {
        renameCount + roomAssignmentCount + newSceneCount + newRoomCount
    }
}

private struct ImportPreview: View {
    let preview: ImportPreviewData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Changes to Apply")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 16) {
                if preview.renameCount > 0 {
                    Label("\(preview.renameCount) renames", systemImage: "pencil")
                }
                if preview.newRoomCount > 0 {
                    Label("\(preview.newRoomCount) new rooms", systemImage: "door.left.hand.open")
                }
                if preview.roomAssignmentCount > 0 {
                    Label("\(preview.roomAssignmentCount) moves", systemImage: "arrow.right")
                }
                if preview.newSceneCount > 0 {
                    Label("\(preview.newSceneCount) new scenes", systemImage: "theatermasks")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
