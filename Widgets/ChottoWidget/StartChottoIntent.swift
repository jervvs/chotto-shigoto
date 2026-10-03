import AppIntents

struct WidgetStartChottoIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a Chotto"
    static var description = IntentDescription("Start a focus session with the default timer")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        SharedDefaults.signalStartSession()
        return .result()
    }
}
