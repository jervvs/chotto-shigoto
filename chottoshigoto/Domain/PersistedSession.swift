import Foundation
import SwiftData

@Model
final class PersistedSession {
    var id: UUID
    var startedAt: Date
    var plannedDuration: TimeInterval
    var completedAt: Date?
    var categoryRaw: String?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        plannedDuration: TimeInterval,
        completedAt: Date? = nil,
        category: SessionCategory? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.plannedDuration = plannedDuration
        self.completedAt = completedAt
        self.categoryRaw = category?.rawValue
    }

    var endDate: Date {
        startedAt.addingTimeInterval(plannedDuration)
    }

    var isActive: Bool {
        completedAt == nil
    }

    var actualDuration: TimeInterval {
        guard let completedAt else { return 0 }
        return completedAt.timeIntervalSince(startedAt)
    }

    var category: SessionCategory? {
        get { categoryRaw.flatMap { SessionCategory(rawValue: $0) } }
        set { categoryRaw = newValue?.rawValue }
    }

    func complete(at: Date = Date()) {
        completedAt = at
    }
}
