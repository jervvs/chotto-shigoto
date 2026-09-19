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
            intent: EndChottoIntent(),
            phrases: [
                "End chotto in \(.applicationName)",
                "End focus session in \(.applicationName)",
                "Stop chotto in \(.applicationName)"
            ],
            shortTitle: "End Chotto",
            systemImageName: "timer.circle.fill"
        )
    }
}
