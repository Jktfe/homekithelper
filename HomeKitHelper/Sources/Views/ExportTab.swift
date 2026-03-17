import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ExportTab: View {
    @Bindable var bridge: HomeKitBridge
    @Binding var exportedJSON: String
    @Binding var showCopiedToast: Bool

    @State private var isExporting = false
    @State private var showFileExporter = false
    @State private var showSavedToast = false
    @State private var saveError: String?
    @State private var jsonDocument = JSONDocument()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(bridge.homeSummaries) { summary in
                    HomeSummaryCard(summary: summary)
                }

                Button {
                    exportConfig()
                } label: {
                    if isExporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        Label("Export Configuration", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(isExporting)

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
                                jsonDocument = JSONDocument(exportedJSON)
                                showFileExporter = true
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
        .fileExporter(
            isPresented: $showFileExporter,
            document: jsonDocument,
            contentType: .json,
            defaultFilename: "homekit_export.json"
        ) { result in
            switch result {
            case .success:
                withAnimation { showSavedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showSavedToast = false }
                }
            case .failure(let error):
                saveError = error.localizedDescription
            }
        }
        .alert("Save Failed", isPresented: .init(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "Unknown error")
        }
        .overlay(alignment: .top) {
            if showSavedToast {
                Text("Saved to file")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func exportConfig() {
        isExporting = true
        Task {
            // Run on background to avoid blocking UI for large homes
            let json = await Task.detached { bridge.exportJSON() ?? "Export failed" }.value
            exportedJSON = json
            isExporting = false
        }
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
