import AppIntents

struct StartChottoIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Chotto"
    static var description = IntentDescription("Start a focus session with the default timer duration")

    static var parameterSummary: some ParameterSummary {
        Summary("Start Chotto")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Opening Chotto to start your focus session.")
    }
}
