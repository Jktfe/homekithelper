import SwiftUI

struct LogTab: View {
    let entries: [LogEntry]

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Operations Yet",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Import a change set to see operation results here.")
                )
            } else {
                List(entries) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: entry.status.icon)
                            .foregroundStyle(iconColour(for: entry.status))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.message)
                                .font(.subheadline)
                            Text(entry.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }

    private func iconColour(for status: LogEntry.Status) -> Color {
        switch status {
        case .success: return .green
        case .failure: return .red
        case .skipped: return .orange
        }
    }
}
