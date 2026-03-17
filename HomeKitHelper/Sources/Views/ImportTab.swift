import SwiftUI
import UniformTypeIdentifiers
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
    @State private var showFileImporter = false
    @State private var importResult: ImportResultSummary?
    @State private var parseError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import Changes")
                        .font(.headline)
                    Text("Paste the change set JSON from the web app, or load from a file, then tap Apply to update your HomeKit configuration.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // JSON input area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Change Set JSON")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Button("Load from File", systemImage: "folder") {
                            showFileImporter = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

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
                        .onChange(of: importJSON) {
                            // Clear previous results when JSON changes
                            importResult = nil
                            parseError = nil
                        }
                }

                // Parse error banner
                if let parseError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.white)
                        Text(parseError)
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Preview parsed changes
                switch parsePreview() {
                case .empty:
                    EmptyView()
                case .success(let preview):
                    ImportPreview(preview: preview)
                case .error(let message):
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.white)
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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

                // Post-apply result summary
                if let result = importResult {
                    ImportResultBanner(result: result)
                }
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                do {
                    importJSON = try String(contentsOf: url, encoding: .utf8)
                } catch {
                    parseError = "Failed to read file: \(error.localizedDescription)"
                }
            case .failure(let error):
                parseError = "File selection failed: \(error.localizedDescription)"
            }
        }
    }

    private func pasteFromClipboard() {
        #if canImport(UIKit)
        importJSON = UIPasteboard.general.string ?? ""
        #elseif canImport(AppKit)
        importJSON = NSPasteboard.general.string(forType: .string) ?? ""
        #endif
    }

    private enum PreviewResult {
        case empty
        case success(ImportPreviewData)
        case error(String)
    }

    private func parsePreview() -> PreviewResult {
        let trimmed = importJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }

        guard let data = importJSON.data(using: .utf8) else {
            return .error("Invalid text encoding")
        }

        do {
            let parsed = try JSONDecoder().decode(HomeImport.self, from: data)
            return .success(ImportPreviewData(
                renameCount: parsed.renames.count,
                roomAssignmentCount: parsed.roomAssignments.count,
                newSceneCount: parsed.newScenes.count,
                newRoomCount: parsed.newRooms.count,
                deleteRoomCount: parsed.deleteRooms.count,
                deleteSceneCount: parsed.deleteScenes.count,
                newZoneCount: parsed.newZones.count,
                deleteZoneCount: parsed.deleteZones.count,
                updateSceneCount: parsed.updateScenes.count
            ))
        } catch {
            return .error("Invalid JSON: \(error.localizedDescription)")
        }
    }

    private func applyChanges() {
        isProcessing = true
        importResult = nil
        Task {
            let result = await bridge.applyChanges(from: importJSON)
            importResult = result
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
    let deleteRoomCount: Int
    let deleteSceneCount: Int
    let newZoneCount: Int
    let deleteZoneCount: Int
    let updateSceneCount: Int

    var totalChanges: Int {
        renameCount + roomAssignmentCount + newSceneCount + newRoomCount
        + deleteRoomCount + deleteSceneCount + newZoneCount + deleteZoneCount
        + updateSceneCount
    }
}

private struct ImportPreview: View {
    let preview: ImportPreviewData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Changes to Apply")
                .font(.subheadline.weight(.medium))

            FlowLayout(spacing: 12) {
                if preview.renameCount > 0 {
                    Label("\(preview.renameCount) renames", systemImage: "pencil")
                }
                if preview.newRoomCount > 0 {
                    Label("\(preview.newRoomCount) new rooms", systemImage: "door.left.hand.open")
                }
                if preview.deleteRoomCount > 0 {
                    Label("\(preview.deleteRoomCount) room deletions", systemImage: "door.left.hand.closed")
                }
                if preview.roomAssignmentCount > 0 {
                    Label("\(preview.roomAssignmentCount) moves", systemImage: "arrow.right")
                }
                if preview.newSceneCount > 0 {
                    Label("\(preview.newSceneCount) new scenes", systemImage: "theatermasks")
                }
                if preview.updateSceneCount > 0 {
                    Label("\(preview.updateSceneCount) scene updates", systemImage: "theatermasks.fill")
                }
                if preview.deleteSceneCount > 0 {
                    Label("\(preview.deleteSceneCount) scene deletions", systemImage: "theatermasks")
                }
                if preview.newZoneCount > 0 {
                    Label("\(preview.newZoneCount) new zones", systemImage: "map")
                }
                if preview.deleteZoneCount > 0 {
                    Label("\(preview.deleteZoneCount) zone deletions", systemImage: "map")
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

// Simple flow layout for wrapping labels
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { break }
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

// MARK: - Import Result Banner

private struct ImportResultBanner: View {
    let result: ImportResultSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: result.failed == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(result.failed == 0 ? .green : .orange)
                Text(result.failed == 0 ? "All changes applied" : "Completed with issues")
                    .font(.subheadline.weight(.medium))
            }

            HStack(spacing: 16) {
                if result.succeeded > 0 {
                    Label("\(result.succeeded) succeeded", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
                if result.failed > 0 {
                    Label("\(result.failed) failed", systemImage: "xmark.circle")
                        .foregroundStyle(.red)
                }
                if result.skipped > 0 {
                    Label("\(result.skipped) skipped", systemImage: "arrow.right.circle")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)

            if result.failed > 0 || result.skipped > 0 {
                Text("See Log tab for details")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(result.failed == 0 ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
