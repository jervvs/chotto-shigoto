import SwiftUI

struct SettingsView: View {
    @Environment(SessionService.self) private var sessionService
    @AppStorage("defaultTimerMinutes") private var defaultMinutes: Int = 25
    @State private var showTimerPicker = false

    var body: some View {
        NavigationStack {
            List {
                // Default Timer
                Section {
                    Button {
                        showTimerPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundStyle(Color.chottoSage)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Default Timer")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)
                                Text("\(defaultMinutes) minutes")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Focus")
                } footer: {
                    Text("This sets the initial timer when you open the app. You can always adjust it before starting.")
                }

                // Focus Automation
                Section {
                    NavigationLink {
                        FocusAutomationGuide()
                    } label: {
                        HStack {
                            Image(systemName: "moon.zzz")
                                .foregroundStyle(Color.chottoSage)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("System Focus")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Set up via Shortcuts")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Focus Automation")
                } footer: {
                    Text("Chotto can integrate with iOS Focus modes through the Shortcuts app.")
                }

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
            #if !DEBUG
            .sheet(isPresented: $showAppPicker) {
                AppPickerView { selection in
                    protection?.shieldApps(selection.applicationTokens)
                }
            }
            #endif
            .sheet(isPresented: $showTimerPicker) {
                DefaultTimerPickerSheet(defaultMinutes: $defaultMinutes)
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

// MARK: - Default Timer Picker Sheet

private struct DefaultTimerPickerSheet: View {
    @Binding var defaultMinutes: Int
    @State private var textValue: String
    @State private var tempMinutes: Int
    @Environment(\.dismiss) private var dismiss

    init(defaultMinutes: Binding<Int>) {
        _defaultMinutes = defaultMinutes
        _tempMinutes = State(initialValue: defaultMinutes.wrappedValue)
        _textValue = State(initialValue: "\(defaultMinutes.wrappedValue)")
    }

    private var validatedMinutes: Int {
        let val = Int(textValue) ?? 25
        return max(1, min(180, val))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Default Timer")
                    .font(.system(size: 22, weight: .light, design: .serif))

                // Typable input
                HStack(spacing: 4) {
                    TextField("25", text: $textValue)
                        .keyboardType(.numberPad)
                        .font(.system(size: 48, weight: .thin, design: .monospaced))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                        .onChange(of: textValue) { _, _ in
                            tempMinutes = validatedMinutes
                        }

                    Text("min")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)
                }

                // Synced drum wheel
                ChottoTimerPicker(selectedMinutes: $tempMinutes)
                    .padding(.horizontal, 8)
                    .onChange(of: tempMinutes) { _, newValue in
                        textValue = "\(newValue)"
                    }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.chottoCream.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        defaultMinutes = validatedMinutes
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(SessionService(protection: MockProtectionService(), repository: SessionRepository.preview))
}
