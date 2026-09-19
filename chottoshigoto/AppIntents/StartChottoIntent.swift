import AppIntents

struct StartChottoIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Chotto"
    static var description = IntentDescription("Start a focus session with the default timer duration")
    static var openAppWhenRun: Bool = true

    static var parameterSummary: some ParameterSummary {
        Summary("Start Chotto")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SharedDefaults.signalStartSession()
        return .result(dialog: "Starting your focus session.")
    }
}
