import Foundation

protocol ProtectionService {
    func requestAuthorization() async throws
    func activate() async throws
    func deactivate() async throws
}
