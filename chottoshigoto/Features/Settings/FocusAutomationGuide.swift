import SwiftUI

struct FocusAutomationGuide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Automation")
                        .font(.system(size: 28, weight: .light, design: .serif))

                    Text("Automatically turn on an iOS Focus mode when you start a Chotto session.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                // How it works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it works")
                        .font(.system(size: 17, weight: .semibold))

                    Text("Chotto provides actions to the Shortcuts app. You can create a personal automation that turns on a Focus mode when you start a session.")
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
                        title: "Create a new automation",
                        detail: "Tap the Automation tab, then tap \"+\" to create a new personal automation."
                    )

                    GuideStep(
                        number: "3",
                        title: "Choose a trigger",
                        detail: "Select \"App\" as the trigger, then choose \"Chotto\" and select \"Is Opened\"."
                    )

                    GuideStep(
                        number: "4",
                        title: "Add the Focus action",
                        detail: "Tap \"Add Action\", search for \"Set Focus\", then choose which Focus mode to turn on (e.g., Work)."
                    )

                    GuideStep(
                        number: "5",
                        title: "Save the automation",
                        detail: "Tap \"Done\". Now when you open Chotto and start a timer, the Focus mode will activate automatically."
                    )
                }

                // Note
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("You can create a similar automation to turn off the Focus when Chotto is closed or after a timer ends.")
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
