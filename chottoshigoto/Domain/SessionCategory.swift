import Foundation

enum SessionCategory: String, CaseIterable, Codable, Identifiable {
    case reading
    case coding
    case writing
    case learning
    case work
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reading:  return "Reading"
        case .coding:   return "Coding"
        case .writing:  return "Writing"
        case .learning: return "Learning"
        case .work:     return "Work"
        case .other:    return "Other"
        }
    }

    var icon: String {
        switch self {
        case .reading:  return "book"
        case .coding:   return "chevron.left.forwardslash.chevron.right"
        case .writing:  return "pencil"
        case .learning: return "brain"
        case .work:     return "briefcase"
        case .other:    return "circle"
        }
    }
}
