import Foundation
import os

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let duration: TimeInterval
    let category: SessionCategory

    init(from session: FocusSession) {
        self.id = session.id
        self.startedAt = session.startedAt
        self.endedAt = session.endedAt ?? Date()
        self.duration = session.actualDuration
        self.category = session.category ?? .other
    }

    var dateKey: String {
        let cal = Calendar.current
        return "\(cal.component(.year, from: endedAt))-\(cal.component(.month, from: endedAt))-\(cal.component(.day, from: endedAt))"
    }
}

@Observable
final class SessionStore {
    private(set) var history: [SessionRecord] = []

    private let fileName = "chotto_history.json"
    private let logger = Logger(subsystem: "com.jervdev.chottoshigoto", category: "SessionStore")

    var totalChottos: Int { history.count }

    var totalHours: Double {
        history.reduce(0) { $0 + $1.duration } / 3600
    }

    init() {
        load()
    }

    func saveSession(_ session: FocusSession) {
        let record = SessionRecord(from: session)
        history.append(record)
        persist()
    }

    func sessions(for date: Date) -> [SessionRecord] {
        let cal = Calendar.current
        return history.filter {
            cal.isDate($0.endedAt, inSameDayAs: date)
        }
    }

    func chottoCount(for date: Date) -> Int {
        sessions(for: date).count
    }

    // MARK: - Persistence

    private func fileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    private func load() {
        let url = fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            history = try JSONDecoder().decode([SessionRecord].self, from: data)
        } catch {
            logger.error("Failed to load history: \(error.localizedDescription)")
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: fileURL(), options: [.atomic, .completeFileProtection])
        } catch {
            logger.error("Failed to save history: \(error.localizedDescription)")
        }
    }
}
