import AppIntents

struct StartChottoIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a Chotto"
    static var description = IntentDescription("Start a 25-minute focus session")

    func perform() async throws -> some IntentResult {
        // The widget communicates with the main app through:
        // 1. A shared App Group container
        // 2. UserDefaults(suiteName: "group.com.jervdev.chottoshigoto")
        // 3. The main app observes changes and starts the session
        //
        // For the initial implementation, this opens the app.
        // Full inter-process communication will be added when the
        // App Group is configured.
        return .result()
    }
}
