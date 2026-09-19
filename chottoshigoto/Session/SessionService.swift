import Foundation
import Combine
import os

@Observable
final class SessionService {
    private(set) var state: SessionState = .idle
    private var timer: AnyCancellable?

    let protection: ProtectionService
    private let logger = Logger(subsystem: "com.jervdev.chottoshigoto", category: "SessionService")

    init(protection: ProtectionService) {
        self.protection = protection
    }

    convenience init() {
        self.init(protection: MockProtectionService())
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

    // MARK: - Actions

    func startSession(plannedDuration: TimeInterval = 25 * 60) {
        let session = FocusSession(plannedDuration: plannedDuration)
        state = .active(session)
        startTimer()
        Task { await applyProtection() }
        logger.info("Session started: \(session.id)")
    }

    func completeSession() {
        guard case .active(let session) = state else { return }
        stopTimer()
        Task { await removeProtection() }

        var finished = session
        finished.endedAt = Date()
        finished.completed = true

        state = .completed(finished)
        logger.info("Session completed: \(finished.id)")
    }

    func moreChotto() {
        guard case .completed(let session) = state else { return }

        let newSession = FocusSession(plannedDuration: session.plannedDuration)
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
        state = .idle
        logger.info("Session finished: \(session.id)")
    }

    func logCategory(_ category: SessionCategory, store: SessionStore) {
        guard case .logging(let session) = state else { return }
        var logged = session
        logged.category = category
        store.saveSession(logged)
        state = .idle
        logger.info("Session logged: \(logged.id) as \(category.rawValue)")
    }

    func skipLogging(store: SessionStore) {
        guard case .logging(let session) = state else { return }
        store.saveSession(session)
        state = .idle
    }

    func discardSession() {
        stopTimer()
        Task { await removeProtection() }
        state = .idle
    }

    func restoreActiveSession() {
        state = .idle
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
