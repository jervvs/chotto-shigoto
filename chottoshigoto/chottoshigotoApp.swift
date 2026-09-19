import SwiftUI
import SwiftData

@main
struct chottoshigotoApp: App {
    @State private var sessionService: SessionService
    @State private var sessionStore = SessionStore()

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
            RootView()
                .environment(sessionService)
                .environment(sessionStore)
                .modelContainer(modelContainer)
        }
    }
}
