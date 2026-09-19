import SwiftUI
import SwiftData

@main
struct chottoshigotoApp: App {
    @Environment(\.scenePhase) private var scenePhase
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
        let service = SessionService(protection: protection, repository: repository)

        // Recover session before view appears — no transition needed
        let result = service.recoverSession()
        _recoveryResult = State(initialValue: result)

        switch result {
        case .resume(let session):
            service.resumePersistedSession(session)
        case .expired(let session):
            service.showExpiredCompletion(session)
        case .noActiveSession:
            break
        }

        // Consume signal on cold launch (not yet running)
        if SharedDefaults.consumeStartSessionSignal() {
            let defaults = UserDefaults.standard
            let minutes = defaults.integer(forKey: "defaultTimerMinutes")
            let duration = TimeInterval((minutes > 0 ? minutes : 25) * 60)
            service.startSession(plannedDuration: duration)
        }

        _sessionService = State(initialValue: service)
    }

    var body: some Scene {
        WindowGroup {
            RootView(recoveryResult: recoveryResult)
                .environment(sessionService)
                .environment(sessionStore)
                .modelContainer(modelContainer)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        handleSignalWhileRunning()
                    }
                }
        }
    }

    private func handleSignalWhileRunning() {
        guard case .idle = sessionService.state else { return }
        if SharedDefaults.consumeStartSessionSignal() {
            let defaults = UserDefaults.standard
            let minutes = defaults.integer(forKey: "defaultTimerMinutes")
            let duration = TimeInterval((minutes > 0 ? minutes : 25) * 60)
            sessionService.startSession(plannedDuration: duration)
        }
    }
}
