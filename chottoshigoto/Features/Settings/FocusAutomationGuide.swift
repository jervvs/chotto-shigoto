import SwiftUI

struct FocusAutomationGuide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Automation")
                        .font(.system(size: 28, weight: .light, design: .serif))

                    Text("Create a Shortcut that starts your Chotto session and automatically turns on a Focus mode until the session ends.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                // How it works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it works")
                        .font(.system(size: 17, weight: .semibold))

                    Text("Chotto exposes \"Start Chotto\" and \"Get Chotto End Time\" actions to Shortcuts. Chain them with a Focus action to automatically reduce interruptions during your session.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                // Flow diagram
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shortcut flow")
                        .font(.system(size: 17, weight: .semibold))

                    VStack(spacing: 0) {
                        FlowStep(icon: "timer", title: "Start Chotto", subtitle: "Starts your focus session")
                        FlowConnector()
                        FlowStep(icon: "arrow.up.forward.app", title: "Open Chotto", subtitle: "Brings app to foreground")
                        FlowConnector()
                        FlowStep(icon: "clock", title: "Get Chotto End Time", subtitle: "Returns session end date")
                        FlowConnector()
                        FlowStep(icon: "moon.zzz", title: "Set Focus", subtitle: "On until end time")
                    }
                    .padding(16)
                    .background(Color.chottoSage.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Steps
                VStack(alignment: .leading, spacing: 16) {
                    Text("Setup steps")
                        .font(.system(size: 17, weight: .semibold))

                    GuideStep(
                        number: "1",
                        title: "Open Shortcuts and create a new Shortcut",
                        detail: "Tap \"+\" in the Shortcuts app to create a new Shortcut."
                    )

                    GuideStep(
                        number: "2",
                        title: "Add \"Start Chotto\"",
                        detail: "Search for \"Start Chotto\" and add it. This starts your focus session."
                    )

                    GuideStep(
                        number: "3",
                        title: "Add \"Open chottoshigoto\"",
                        detail: "Search for \"Open App\" and select Chotto. This ensures the app is in the foreground."
                    )

                    GuideStep(
                        number: "4",
                        title: "Add \"Get Chotto End Time\"",
                        detail: "Search for \"Get Chotto End Time\" and add it. This returns the session's end date."
                    )

                    GuideStep(
                        number: "5",
                        title: "Add \"Set Focus\"",
                        detail: "Search for \"Set Focus\" and choose your Focus mode (e.g., Reduce Interruptions). Set it to turn On."
                    )

                    GuideStep(
                        number: "6",
                        title: "Set the Focus duration",
                        detail: "Tap the time parameter in the Focus action, then select the \"Get Chotto End Time\" variable. Your Focus will automatically turn off when the session ends."
                    )
                }

                // What Chotto exposes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chotto actions in Shortcuts")
                        .font(.system(size: 17, weight: .semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        ActionRow(
                            icon: "timer",
                            name: "Start Chotto",
                            description: "Opens Chotto and starts a focus session with your default timer"
                        )

                        Divider()

                        ActionRow(
                            icon: "clock",
                            name: "Get Chotto End Time",
                            description: "Returns the end time of the current active session"
                        )
}
                .padding(12)
                .background(Color.chottoSage.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Shortcut Trigger Button
            VStack(alignment: .leading, spacing: 12) {
                Text("Shortcut Trigger Button")
                    .font(.system(size: 17, weight: .semibold))

                Text("You can also configure a shortcut to run directly from Chotto's Home screen. In Settings \u{2192} Shortcut Trigger, enter the exact name of your shortcut. The main button will change to \"Start Shortcut\" and launch it via the Shortcuts URL scheme.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Text("This is useful if you want a single shortcut that starts Chotto, enables Focus mode, and optionally does other actions (like playing a focus playlist).")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Example shortcut for the button:")
                        .font(.system(size: 15, weight: .medium))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Start Chotto (opens app, starts session, returns end time)")
                        Text("2. Open App \u{2192} Chotto (ensures app is foreground)")
                        Text("3. Set Focus \u{2192} On (choose your Focus mode)")
                        Text("4. Get Chotto End Time \u{2192} use as Focus duration")
                        Text("5. (Optional) Play Music / Run Script / etc.")
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
                }
                .padding(12)
                .background(Color.chottoSage.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()
        }
        .padding(20)
    }
        .background(Color.chottoCream.ignoresSafeArea())
        .navigationTitle("Focus Automation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Views

private struct FlowStep: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.chottoSage)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct FlowConnector: View {
    var body: some View {
        HStack {
            Spacer()
                .frame(width: 36)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.chottoSage.opacity(0.3))
                    .frame(width: 1, height: 12)
            }
            Spacer()
        }
    }
}

private struct ActionRow: View {
    let icon: String
    let name: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.chottoSage)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct GuideStep: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.chottoSage)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FocusAutomationGuide()
    }
}
