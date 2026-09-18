import SwiftUI

@main
struct chottoshigotoApp: App {
    @State private var sessionService = SessionService()
    @State private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionService)
                .environment(sessionStore)
        }
    }
}
