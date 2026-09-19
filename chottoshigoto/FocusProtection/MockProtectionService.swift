import Foundation
import os

final class MockProtectionService: ProtectionService {
    private let logger = Logger(subsystem: "com.jervdev.chottoshigoto", category: "MockProtection")

    func requestAuthorization() async throws {
        logger.info("Mock: authorization requested - granted automatically")
    }

    func activate() async throws {
        logger.info("Mock: protection activated (no real blocking)")
    }

    func deactivate() async throws {
        logger.info("Mock: protection deactivated")
    }
}
