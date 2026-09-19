import AppIntents

struct EndChottoIntent: AppIntent {
    static var title: LocalizedStringResource = "End Chotto"
    static var description = IntentDescription("End the current focus session")

    static var parameterSummary: some ParameterSummary {
        Summary("End Chotto")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Opening Chotto to end your focus session.")
    }
}
