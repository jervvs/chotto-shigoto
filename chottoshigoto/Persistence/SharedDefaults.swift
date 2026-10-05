import Foundation

enum SharedDefaults {
    static let suiteName = "group.com.jervdev.chottoshigoto"

    private static let sharedDefaults = UserDefaults(suiteName: suiteName)

    private static let startSessionKey = "pendingStartSession"
    private static let pendingDurationKey = "pendingDuration"

    nonisolated static func signalStartSession() {
        sharedDefaults?.set(true, forKey: startSessionKey)
    }

    nonisolated static func consumeStartSessionSignal() -> Bool {
        guard sharedDefaults?.bool(forKey: startSessionKey) == true else { return false }
        sharedDefaults?.removeObject(forKey: startSessionKey)
        return true
    }

    nonisolated static func clearStartSessionSignal() {
        sharedDefaults?.removeObject(forKey: startSessionKey)
    }

    nonisolated static func setPendingDuration(_ duration: TimeInterval) {
        sharedDefaults?.set(duration, forKey: pendingDurationKey)
    }

    nonisolated static func consumePendingDuration() -> TimeInterval? {
        guard let duration = sharedDefaults?.object(forKey: pendingDurationKey) as? TimeInterval else { return nil }
        sharedDefaults?.removeObject(forKey: pendingDurationKey)
        return duration
    }
}
