import SwiftUI

struct LoggingView: View {
    @Environment(SessionService.self) private var sessionService
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("What was your chotto?")
                .font(.system(size: 22, weight: .light, design: .serif))

            VStack(spacing: 12) {
                ForEach(SessionCategory.allCases) { category in
                    Button {
                        sessionService.logCategory(category, store: sessionStore)
                    } label: {
                        Text(category.label)
                            .font(.system(size: 17, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)

            Button("Skip") {
                sessionService.skipLogging(store: sessionStore)
            }
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.chottoCream.ignoresSafeArea())
    }
}

#Preview {
    LoggingView()
        .environment(SessionService(protection: MockProtectionService(), repository: SessionRepository.preview))
        .environment(SessionStore())
}
