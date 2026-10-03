import AppIntents
import SwiftData

struct GetEndTimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Chotto End Time"
    static var description = IntentDescription("Returns the end time of the current focus session, or nil if no session is active")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Chotto End Time")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Date?> & ProvidesDialog {
        let container = try ModelContainer(for: PersistedSession.self)
        let repository = SessionRepository(modelContext: container.mainContext)

        guard let session = repository.activeSession() else {
            return .result(
                value: nil as Date?,
                dialog: "No active focus session."
            )
        }

        return .result(
            value: session.endDate,
            dialog: "Focus session ends at \(session.endDate.formatted(date: .omitted, time: .shortened))."
        )
    }
}
