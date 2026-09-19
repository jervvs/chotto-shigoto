import SwiftUI
import Combine

struct FocusView: View {
    @Environment(SessionService.self) private var sessionService
    @State private var now = Date()
    @State private var timer: AnyCancellable?

    private var remainingSeconds: TimeInterval {
        guard let session = sessionService.currentSession else { return 0 }
        return session.remainingSeconds(at: now)
    }

    private var hours: Int {
        Int(remainingSeconds) / 3600
    }

    private var minutes: Int {
        (Int(remainingSeconds) % 3600) / 60
    }

    private var seconds: Int {
        Int(remainingSeconds) % 60
    }

    private var timerText: String {
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(timerText)
                .font(.system(size: 96, weight: .thin, design: .monospaced))
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.9), value: minutes)
                .minimumScaleFactor(0.5)

            Spacer()

            Text("chotto shigoto")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.chottoCream.ignoresSafeArea())
        .onAppear {
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    now = Date()
                }
        }
        .onDisappear {
            timer?.cancel()
        }
    }
}

#Preview {
    FocusView()
        .environment(SessionService(protection: MockProtectionService(), repository: SessionRepository.preview))
}
