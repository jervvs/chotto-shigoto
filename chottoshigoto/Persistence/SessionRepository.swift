import Foundation
import SwiftData
import os

final class SessionRepository {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.jervdev.chottoshigoto", category: "SessionRepository")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func activeSession() -> PersistedSession? {
        let descriptor = FetchDescriptor<PersistedSession>(
            predicate: #Predicate { $0.completedAt == nil }
        )
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            logger.error("Failed to fetch active session: \(error.localizedDescription)")
            return nil
        }
    }

    func save(_ session: PersistedSession) {
        modelContext.insert(session)
        try? modelContext.save()
    }

    func complete(_ session: PersistedSession, at: Date = Date()) {
        session.complete(at: at)
        try? modelContext.save()
    }

    func delete(_ session: PersistedSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }
}
