import SwiftUI

@main
struct chottoshigotoApp: App {
    @State private var sessionService: SessionService
    @State private var sessionStore = SessionStore()

    init() {
        let protection: ProtectionService
        #if DEBUG
        protection = MockProtectionService()
        #else
        protection = ScreenTimeProtectionService()
        #endif
        _sessionService = State(initialValue: SessionService(protection: protection))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionService)
                .environment(sessionStore)
        }
    }
}
