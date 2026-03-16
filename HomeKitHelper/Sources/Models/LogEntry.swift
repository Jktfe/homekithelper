import Foundation

// MARK: - Operation Log
// Tracks what happened during import so the user gets clear feedback.

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let status: Status
    let message: String

    enum Status {
        case success
        case failure
        case skipped

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .failure: return "xmark.circle.fill"
            case .skipped: return "arrow.right.circle.fill"
            }
        }
    }
}
