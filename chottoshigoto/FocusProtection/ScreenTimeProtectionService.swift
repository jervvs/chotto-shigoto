#if !DEBUG
import Foundation
import FamilyControls
import ManagedSettings
import os

@Observable
final class ScreenTimeProtectionService: ProtectionService {
    private(set) var isAuthorized = false
    private(set) var isProtecting = false
    private(set) var selectedApps: [ApplicationToken] = []
    private(set) var whitelistedApps: [String] = []

    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private let logger = Logger(subsystem: "com.jervdev.chottoshigoto", category: "ScreenTimeProtection")

    init() {
        whitelistedApps = Self.defaultWhitelistedApps
        loadWhitelist()
    }

    // MARK: - Default Whitelist (high-priority alert apps)

    static let defaultWhitelistedApps: [String] = [
        "com.pagerduty.PagerDuty",
        "com.slack.Slack",
        "com.apple.mobilephone",
        "com.apple.MobileSMS",
        "com.apple.mobilemail",
    ]

    // MARK: - ProtectionService

    func requestAuthorization() async throws {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = true
            logger.info("Authorization granted")
        } catch {
            logger.error("Authorization failed: \(error.localizedDescription)")
            isAuthorized = false
            throw error
        }
    }

    func activate() async throws {
        guard !selectedApps.isEmpty else {
            logger.info("No apps selected for protection")
            return
        }
        store.shield.applications = Set(selectedApps)
        isProtecting = true
        logger.info("Shielded \(self.selectedApps.count) apps")
    }

    func deactivate() async throws {
        store.clearAllSettings()
        isProtecting = false
        logger.info("All shields removed")
    }

    // MARK: - App Selection (ScreenTime-specific)

    func shieldApps(_ tokens: [ApplicationToken]) {
        guard !tokens.isEmpty else {
            logger.warning("No apps to shield")
            return
        }
        selectedApps = tokens
        store.shield.applications = Set(tokens)
        isProtecting = true
        logger.info("Shielded \(tokens.count) apps")
    }

    // MARK: - Whitelist

    func addToWhitelist(bundleId: String) {
        guard !whitelistedApps.contains(bundleId) else { return }
        whitelistedApps.append(bundleId)
        saveWhitelist()
        logger.info("Added \(bundleId) to whitelist")
    }

    func removeFromWhitelist(bundleId: String) {
        whitelistedApps.removeAll { $0 == bundleId }
        saveWhitelist()
        logger.info("Removed \(bundleId) from whitelist")
    }

    func isWhitelisted(bundleId: String) -> Bool {
        whitelistedApps.contains(bundleId)
    }

    // MARK: - Persist Whitelist

    private func saveWhitelist() {
        UserDefaults.standard.set(whitelistedApps, forKey: "whitelistedApps")
    }

    private func loadWhitelist() {
        if let saved = UserDefaults.standard.stringArray(forKey: "whitelistedApps") {
            whitelistedApps = saved
        }
    }
}
#endif