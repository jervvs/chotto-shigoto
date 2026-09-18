import SwiftUI
import FamilyControls
import ManagedSettings

struct SettingsView: View {
    @Environment(SessionService.self) private var sessionService
    @State private var showAppPicker = false
    @State private var showWhitelistPicker = false
    @State private var needsAuthorization = false
    @State private var newWhitelistBundleId = ""

    private var protection: FocusProtectionService {
        sessionService.protection
    }

    var body: some View {
        NavigationStack {
            List {
                // Protection Section
                Section {
                    HStack {
                        Image(systemName: protection.isAuthorized ? "shield.checkered" : "shield")
                            .foregroundStyle(protection.isAuthorized ? Color.chottoSage : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Protection")
                                .font(.system(size: 16, weight: .medium))
                            Text(protection.selectedApps.isEmpty ? "No apps selected" : "\(protection.selectedApps.count) apps blocked")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            Task {
                                await authorizeAndPick()
                            }
                        } label: {
                            Text(protection.isAuthorized ? "Change" : "Set up")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                } header: {
                    Text("Protection")
                } footer: {
                    Text("Select apps to block during focus sessions.")
                }

                // Whitelist Section
                Section {
                    ForEach(protection.whitelistedApps, id: \.self) { bundleId in
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(Color.chottoSage)
                            Text(bundleIdForDisplay(bundleId))
                                .font(.system(size: 14))
                            Spacer()
                            Button {
                                protection.removeFromWhitelist(bundleId: bundleId)
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
                            protection.addToWhitelist(bundleId: newWhitelistBundleId)
                            newWhitelistBundleId = ""
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Color.chottoSage)
                        }
                        .disabled(newWhitelistBundleId.isEmpty)
                    }
                } header: {
                    Text("Whitelist")
                } footer: {
                    Text("These apps will never be blocked, even during focus sessions. Useful for PagerDuty, Slack alerts, phone calls, etc.")
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
        .sheet(isPresented: $showAppPicker) {
            AppPickerView { selection in
                let tokens = Array(selection.applicationTokens)
                let categories = Array(selection.categoryTokens)
                print("Selected \(tokens.count) apps, \(categories.count) categories")
                protection.shieldApps(tokens)
            }
        }
        .alert("Permission Required", isPresented: $needsAuthorization) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Chotto needs Screen Time access to block distracting apps.")
        }
    }

    private func authorizeAndPick() async {
        let authorized = await protection.requestAuthorization()
        if authorized {
            showAppPicker = true
        } else {
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
}

#Preview {
    SettingsView()
        .environment(SessionService())
}
