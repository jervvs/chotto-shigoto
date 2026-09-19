import SwiftUI

struct HomeView: View {
    @Environment(SessionService.self) private var sessionService
    @Environment(SessionStore.self) private var sessionStore
    @State private var selectedMinutes: Int = 25
    @State private var isStarting = false

    private var durationText: String {
        let totalSeconds = selectedMinutes * 60
        let hrs = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // App Name
                VStack(spacing: 8) {
                    Text("chotto shigoto")
                        .font(.system(size: 28, weight: .light, design: .serif))

                    Text("ちょっと仕事")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 32)

                // Timer Picker
                ChottoTimerPicker(selectedMinutes: $selectedMinutes)
                    .padding(.horizontal, 8)

                // Duration Display
                Text(durationText)
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(Color.chottoCharcoal)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                // Start Button
                Button {
                    isStarting = true
                    let duration = TimeInterval(selectedMinutes * 60)
                    sessionService.startSession(plannedDuration: duration)
                } label: {
                    Text("Start Timer")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.black)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 40)
                .disabled(isStarting || selectedMinutes < 1)
                .opacity(selectedMinutes < 1 ? 0.5 : 1.0)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.chottoCream.ignoresSafeArea())
            .onAppear {
                isStarting = false
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(SessionService(protection: MockProtectionService()))
        .environment(SessionStore())
}
