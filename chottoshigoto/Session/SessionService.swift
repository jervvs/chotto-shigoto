import Foundation
import Combine
import SwiftData
import os

@Observable
final class SessionService {
    private(set) var state: SessionState = .idle
    private var timer: AnyCancellable?

    let protection: ProtectionService
    let repository: SessionRepository
    private let logger = Logger(subsystem: "com.jervdev.chottoshigoto", category: "SessionService")

    init(protection: ProtectionService, repository: SessionRepository) {
        self.protection = protection
        self.repository = repository
    }

    convenience init() {
        self.init(protection: MockProtectionService(), repository: SessionRepository.preview)
    }

    var currentSession: FocusSession? {
        switch state {
        case .active(let session), .completed(let session), .logging(let session):
            return session
        case .idle:
            return nil
        }
    }

    var isRunning: Bool {
        if case .active = state { return true }
        return false
    }

    // MARK: - Recovery

    enum RecoveryResult {
        case noActiveSession
        case resume(PersistedSession)
        case expired(PersistedSession)
    }

    func recoverSession() -> RecoveryResult {
        guard let session = repository.activeSession() else {
            return .noActiveSession
        }

        if Date() < session.endDate {
            return .resume(session)
        }

        repository.complete(session, at: session.endDate)
        return .expired(session)
    }

    func resumePersistedSession(_ persisted: PersistedSession) {
        let session = FocusSession(
            id: persisted.id,
            startedAt: persisted.startedAt,
            plannedDuration: persisted.plannedDuration
        )
        state = .active(session)
        startTimer()
        Task { await applyProtection() }
        logger.info("Resumed persisted session: \(session.id)")
    }

    func showExpiredCompletion(_ persisted: PersistedSession) {
        let session = FocusSession(
            id: persisted.id,
            startedAt: persisted.startedAt,
            endedAt: persisted.endDate,
            plannedDuration: persisted.plannedDuration,
            completed: true
        )
        state = .completed(session)
        logger.info("Showing expired session completion: \(session.id)")
    }

    // MARK: - Actions

    func startSession(plannedDuration: TimeInterval = 25 * 60) {
        let session = FocusSession(plannedDuration: plannedDuration)

        let persisted = PersistedSession(
            id: session.id,
            startedAt: session.startedAt,
            plannedDuration: session.plannedDuration
        )
        repository.save(persisted)

        state = .active(session)
        startTimer()
        Task { await applyProtection() }
        logger.info("Session started: \(session.id)")
    }

    func completeSession() {
        guard case .active(let session) = state else { return }
        stopTimer()
        Task { await removeProtection() }

        if let persisted = repository.activeSession() {
            repository.complete(persisted)
        }

        var finished = session
        finished.endedAt = Date()
        finished.completed = true

        state = .completed(finished)
        logger.info("Session completed: \(finished.id)")
    }

    func moreChotto() {
        guard case .completed(let session) = state else { return }

        let newSession = FocusSession(plannedDuration: session.plannedDuration)

        let persisted = PersistedSession(
            id: newSession.id,
            startedAt: newSession.startedAt,
            plannedDuration: newSession.plannedDuration
        )
        repository.save(persisted)

        state = .active(newSession)
        startTimer()
        Task { await applyProtection() }
        logger.info("mou chotto started: \(newSession.id)")
    }

    func proceedToLogging() {
        guard case .completed(let session) = state else { return }
        state = .logging(session)
    }

    func finishSession(store: SessionStore) {
        guard case .completed(let session) = state else { return }
        store.saveSession(session)
        deleteActivePersistedSession()
        state = .idle
        logger.info("Session finished: \(session.id)")
    }

    func logCategory(_ category: SessionCategory, store: SessionStore) {
        guard case .logging(let session) = state else { return }
        var logged = session
        logged.category = category
        store.saveSession(logged)
        deleteActivePersistedSession()
        state = .idle
        logger.info("Session logged: \(logged.id) as \(category.rawValue)")
    }

    func skipLogging(store: SessionStore) {
        guard case .logging(let session) = state else { return }
        store.saveSession(session)
        deleteActivePersistedSession()
        state = .idle
    }

    func discardSession() {
        stopTimer()
        Task { await removeProtection() }
        deleteActivePersistedSession()
        state = .idle
    }

    private func deleteActivePersistedSession() {
        if let persisted = repository.activeSession() {
            repository.delete(persisted)
        }
    }

    // MARK: - Protection

    private func applyProtection() async {
        do {
            try await protection.activate()
        } catch {
            logger.error("Protection activation failed: \(error.localizedDescription)")
        }
    }

    private func removeProtection() async {
        do {
            try await protection.deactivate()
        } catch {
            logger.error("Protection deactivation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if case .active(let session) = self.state {
                    if session.remainingSeconds(at: Date()) <= 0 {
                        self.completeSession()
                    }
                }
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        stopTimer()
    }
}

// MARK: - Preview

extension SessionRepository {
    static var preview: SessionRepository {
        let container = try! ModelContainer(
            for: PersistedSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SessionRepository(modelContext: container.mainContext)
    }
}
