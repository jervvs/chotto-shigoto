import SwiftUI

struct FocusAutomationGuide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Automation")
                        .font(.system(size: 28, weight: .light, design: .serif))

                    Text("Automatically turn on an iOS Focus mode when you start a Chotto session, and turn it off when the session ends.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                // How it works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it works")
                        .font(.system(size: 17, weight: .semibold))

                    Text("Chotto exposes \"Start Chotto\" and \"End Chotto\" actions to the Shortcuts app. You can create a personal automation that turns on a Focus mode when Chotto opens, and turns it off when Chotto closes.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                // Steps
                VStack(alignment: .leading, spacing: 16) {
                    Text("Setup steps")
                        .font(.system(size: 17, weight: .semibold))

                    GuideStep(
                        number: "1",
                        title: "Open the Shortcuts app",
                        detail: "Find it in your App Library or search for \"Shortcuts\"."
                    )

                    GuideStep(
                        number: "2",
                        title: "Create a new personal automation",
                        detail: "Tap the Automation tab, then tap \"+\" to create a new personal automation."
                    )

                    GuideStep(
                        number: "3",
                        title: "Choose the trigger",
                        detail: "Select \"App\" as the trigger, then choose \"Chotto\" and select \"Is Opened\"."
                    )

                    GuideStep(
                        number: "4",
                        title: "Add the Focus On action",
                        detail: "Tap \"Add Action\", search for \"Set Focus\", then choose which Focus mode to turn on (e.g., Work)."
                    )

                    GuideStep(
                        number: "5",
                        title: "Set \"Run Immediately\"",
                        detail: "Make sure \"Run Immediately\" is selected so it runs without asking."
                    )

                    GuideStep(
                        number: "6",
                        title: "Create the Off automation",
                        detail: "Create another automation: Trigger = \"App\" → \"Chotto\" → \"Is Closed\". Action = \"Set Focus\" → turn off the same Focus mode."
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
                            description: "Starts a focus session with your default timer duration"
                        )

                        ActionRow(
                            icon: "timer.circle.fill",
                            name: "End Chotto",
                            description: "Ends the current focus session"
                        )
                    }
                    .padding(12)
                    .background(Color.chottoSage.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Alternative: Shortcut chaining
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("You can also create a Shortcut that chains \"Start Chotto\" with \"Set Focus On\", then run that Shortcut manually to start your session.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.chottoSage)
                    }
                    .padding(12)
                    .background(Color.chottoSage.opacity(0.1))
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
