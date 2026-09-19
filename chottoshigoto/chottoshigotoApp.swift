import SwiftUI
import SwiftData

@main
struct chottoshigotoApp: App {
    @State private var sessionService: SessionService
    @State private var sessionStore = SessionStore()
    @State private var recoveryResult: SessionService.RecoveryResult = .noActiveSession

    let modelContainer: ModelContainer

    init() {
        let protection: ProtectionService
        #if DEBUG
        protection = MockProtectionService()
        #else
        protection = ScreenTimeProtectionService()
        #endif

        let container: ModelContainer
        do {
            let schema = Schema([PersistedSession.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        modelContainer = container

        let repository = SessionRepository(modelContext: container.mainContext)
        _sessionService = State(initialValue: SessionService(protection: protection, repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            RootView(recoveryResult: recoveryResult)
                .environment(sessionService)
                .environment(sessionStore)
                .modelContainer(modelContainer)
                .onAppear {
                    handleRecovery()
                }
        }
    }

    private func handleRecovery() {
        let result = sessionService.recoverSession()
        recoveryResult = result

        switch result {
        case .resume(let session):
            sessionService.resumePersistedSession(session)
        case .expired(let session):
            sessionService.showExpiredCompletion(session)
        case .noActiveSession:
            // Check if intent signaled to start a session
            if SharedDefaults.consumeStartSessionSignal() {
                let defaults = UserDefaults.standard
                let minutes = defaults.integer(forKey: "defaultTimerMinutes")
                let duration = TimeInterval((minutes > 0 ? minutes : 25) * 60)
                sessionService.startSession(plannedDuration: duration)
            }
        }

        // Always clear any stale signal to prevent ghost sessions
        SharedDefaults.clearStartSessionSignal()
    }
}
