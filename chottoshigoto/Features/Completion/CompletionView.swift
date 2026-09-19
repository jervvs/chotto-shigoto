import SwiftUI

struct CompletionView: View {
    @Environment(SessionService.self) private var sessionService
    @Environment(SessionStore.self) private var sessionStore

    private var completedSession: FocusSession? {
        if case .completed(let session) = sessionService.state {
            return session
        }
        return nil
    }

    private var durationText: String {
        guard let session = completedSession else { return "0s" }
        let totalSeconds = Int(session.actualDuration)
        if totalSeconds < 60 {
            return "\(totalSeconds) sec"
        }
        let hours = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins) min"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("お疲れ様でした。")
                    .font(.system(size: 36, weight: .light, design: .serif))

                VStack(spacing: 4) {
                    Text("Thank you for your hard work.")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary)

                    Text("You completed \(durationText) of focused work.")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    sessionService.moreChotto()
                } label: {
                    Text("mou chotto")
                        .font(.system(size: 18, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    sessionService.proceedToLogging()
                } label: {
                    Text("finish")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.chottoCream.ignoresSafeArea())
    }
}

#Preview {
    CompletionView()
        .environment(SessionService(protection: MockProtectionService(), repository: SessionRepository.preview))
        .environment(SessionStore())
}
