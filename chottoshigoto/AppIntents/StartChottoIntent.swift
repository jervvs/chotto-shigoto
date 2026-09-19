import AppIntents

struct StartChottoIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Chotto"
    static var description = IntentDescription("Start a focus session and return the end time")
    static var openAppWhenRun: Bool = true

    static var parameterSummary: some ParameterSummary {
        Summary("Start Chotto")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Date> & ProvidesDialog {
        let defaults = UserDefaults.standard
        let minutes = defaults.integer(forKey: "defaultTimerMinutes")
        let duration = TimeInterval((minutes > 0 ? minutes : 25) * 60)
        let endTime = Date().addingTimeInterval(duration)

        SharedDefaults.signalStartSession()

        return .result(
            value: endTime,
            dialog: "Focus session started. Ends at \(endTime.formatted(date: .omitted, time: .shortened))."
        )
    }
}
