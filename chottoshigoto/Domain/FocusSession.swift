import Foundation

struct FocusSession: Identifiable, Codable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    let plannedDuration: TimeInterval
    var category: SessionCategory?
    var completed: Bool

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        plannedDuration: TimeInterval = 25 * 60,
        category: SessionCategory? = nil,
        completed: Bool = false
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedDuration = plannedDuration
        self.category = category
        self.completed = completed
    }

    var endAt: Date {
        startedAt.addingTimeInterval(plannedDuration)
    }

    func remainingSeconds(at now: Date = Date()) -> TimeInterval {
        max(0, endAt.timeIntervalSince(now))
    }

    var actualDuration: TimeInterval {
        guard let endedAt else { return 0 }
        return endedAt.timeIntervalSince(startedAt)
    }

    var isActive: Bool {
        endedAt == nil && !completed
    }
}
