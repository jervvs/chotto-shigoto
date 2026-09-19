import SwiftUI

struct SettingsView: View {
    @Environment(SessionService.self) private var sessionService

    var body: some View {
        NavigationStack {
            List {
                // Protection Section
                Section {
                    #if DEBUG
                    mockProtectionRow
                    #else
                    realProtectionSection
                    #endif
                } header: {
                    Text("Protection")
                } footer: {
                    Text("Select apps to block during focus sessions.")
                }

                // Version
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Mock Protection (DEBUG)

    private var mockProtectionRow: some View {
        HStack {
            Image(systemName: "shield.checkered")
                .foregroundStyle(Color.chottoSage)

            VStack(alignment: .leading, spacing: 2) {
                Text("App Protection")
                    .font(.system(size: 16, weight: .medium))
                Text("Mock active - no real blocking")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.chottoSage)
        }
    }

    // MARK: - Real Protection (Release)

    #if !DEBUG
    @State private var showAppPicker = false
    @State private var needsAuthorization = false
    @State private var newWhitelistBundleId = ""

    private var protection: ScreenTimeProtectionService? {
        sessionService.protection as? ScreenTimeProtectionService
    }

    private var realProtectionSection: some View {
        Group {
            HStack {
                Image(systemName: protection?.isAuthorized == true ? "shield.checkered" : "shield")
                    .foregroundStyle(protection?.isAuthorized == true ? Color.chottoSage : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("App Protection")
                        .font(.system(size: 16, weight: .medium))
                    Text(protection?.selectedApps.isEmpty == true ? "No apps selected" : "\(protection?.selectedApps.count ?? 0) apps blocked")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        await authorizeAndPick()
                    }
                } label: {
                    Text(protection?.isAuthorized == true ? "Change" : "Set up")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Whitelist
            ForEach(protection?.whitelistedApps ?? [], id: \.self) { bundleId in
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(Color.chottoSage)
                    Text(bundleIdForDisplay(bundleId))
                        .font(.system(size: 14))
                    Spacer()
                    Button {
                        protection?.removeFromWhitelist(bundleId: bundleId)
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.red)
                    }
                }
            }

            HStack {
                TextField("Bundle ID (e.g. com.pagerduty.PagerDuty)", text: $newWhitelistBundleId)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    guard !newWhitelistBundleId.isEmpty else { return }
                    protection?.addToWhitelist(bundleId: newWhitelistBundleId)
                    newWhitelistBundleId = ""
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color.chottoSage)
                }
                .disabled(newWhitelistBundleId.isEmpty)
            }
        }
    }

    private func authorizeAndPick() async {
        guard let protection else { return }
        do {
            try await protection.requestAuthorization()
            showAppPicker = true
        } catch {
            needsAuthorization = true
        }
    }

    private func bundleIdForDisplay(_ bundleId: String) -> String {
        let known: [String: String] = [
            "com.pagerduty.PagerDuty": "PagerDuty",
            "com.slack.Slack": "Slack",
            "com.apple.mobilephone": "Phone",
            "com.apple.MobileSMS": "Messages",
            "com.apple.mobilemail": "Mail",
        ]
        return known[bundleId] ?? bundleId
    }
    #endif
}

#Preview {
    SettingsView()
        .environment(SessionService(protection: MockProtectionService()))
}
