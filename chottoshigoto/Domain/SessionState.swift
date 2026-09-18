import Foundation

enum SessionState: Equatable {
    case idle
    case active(FocusSession)
    case completed(FocusSession)
    case logging(FocusSession)

    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.active(let a), .active(let b)):
            return a.id == b.id
        case (.completed(let a), .completed(let b)):
            return a.id == b.id
        case (.logging(let a), .logging(let b)):
            return a.id == b.id
        default:
            return false
        }
    }
}
