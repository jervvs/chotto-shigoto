import SwiftUI

struct RootView: View {
    @Environment(SessionService.self) private var sessionService
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, progress, settings
    }

    var body: some View {
        Group {
            switch sessionService.state {
            case .idle:
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(Tab.home)
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                    ProgressView()
                        .tag(Tab.progress)
                        .tabItem {
                            Label("Progress", systemImage: "chart.bar")
                        }

                    SettingsView()
                        .tag(Tab.settings)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }

            case .logging:
                LoggingView()
                    .transition(.opacity)

            case .active:
                FocusView()
                    .transition(.opacity)

            case .completed:
                CompletionView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: sessionService.state)
        .tint(.chottoCharcoal)
    }
}

#Preview {
    RootView()
        .environment(SessionService())
        .environment(SessionStore())
}
