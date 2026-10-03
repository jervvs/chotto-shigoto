import Foundation

enum SharedDefaults {
    static let suiteName = "group.com.jervdev.chottoshigoto"

    private static let sharedDefaults = UserDefaults(suiteName: suiteName)

    private static let startSessionKey = "pendingStartSession"

    static func signalStartSession() {
        sharedDefaults?.set(true, forKey: startSessionKey)
    }

    static func consumeStartSessionSignal() -> Bool {
        guard sharedDefaults?.bool(forKey: startSessionKey) == true else { return false }
        sharedDefaults?.removeObject(forKey: startSessionKey)
        return true
    }

    static func clearStartSessionSignal() {
        sharedDefaults?.removeObject(forKey: startSessionKey)
    }
}
