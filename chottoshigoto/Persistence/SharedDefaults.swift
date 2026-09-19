import Foundation

enum SharedDefaults {
    static let suiteName = "group.com.jervdev.chottoshigoto"

    static var shared: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private static let startSessionKey = "pendingStartSession"

    static func signalStartSession() {
        shared?.set(true, forKey: startSessionKey)
        shared?.synchronize()
    }

    static func consumeStartSessionSignal() -> Bool {
        guard shared?.bool(forKey: startSessionKey) == true else { return false }
        shared?.removeObject(forKey: startSessionKey)
        shared?.synchronize()
        return true
    }
}
