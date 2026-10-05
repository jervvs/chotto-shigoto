import AppIntents

struct StartChottoIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Chotto"
    static var description = IntentDescription("Start a focus session and return the end time")

    static var parameterSummary: some ParameterSummary {
        Summary("Start Chotto")
    }

    var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult & ReturnsValue<Date> & ProvidesDialog {
        SharedDefaults.signalStartSession()

        let duration: TimeInterval
        if let pendingDuration = SharedDefaults.consumePendingDuration() {
            duration = pendingDuration
        } else {
            let defaults = UserDefaults.standard
            let minutes = defaults.integer(forKey: "defaultTimerMinutes")
            duration = TimeInterval((minutes > 0 ? minutes : 25) * 60)
        }
        let endTime = Date().addingTimeInterval(duration)

        return .result(
            value: endTime,
            dialog: "Focus session ends at \(endTime.formatted(date: .omitted, time: .shortened))."
        )
    }
}
