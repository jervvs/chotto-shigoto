import AppIntents

struct ChottoShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartChottoIntent(),
            phrases: [
                "Start a chotto in \(.applicationName)",
                "Start focus session in \(.applicationName)",
                "Begin chotto in \(.applicationName)"
            ],
            shortTitle: "Start Chotto",
            systemImageName: "timer"
        )

        AppShortcut(
            intent: GetEndTimeIntent(),
            phrases: [
                "Get chotto end time in \(.applicationName)",
                "When does chotto end in \(.applicationName)",
                "Check chotto timer in \(.applicationName)"
            ],
            shortTitle: "Get End Time",
            systemImageName: "clock"
        )
    }
}
