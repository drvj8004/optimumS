
import SwiftUI

@main
struct OptimumApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var sleepMgr: SleepManager
    @StateObject private var store: SleepStore

    @State private var splash = true

    init() {
        let mgr = SleepManager()
        _sleepMgr = StateObject(wrappedValue: mgr)
        _store    = StateObject(wrappedValue: SleepStore(manager:mgr))
        NotificationManager.request { _ in }
        HealthKitManager.requestAuthorization { _ in }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if splash {
                    SplashView(show: $splash)
                        .transition(.opacity)
                } else {
                    TabView {
                        NavigationStack { HomeView() }
                            .tabItem { Label("Home", systemImage: "house.fill") }

                        NavigationStack { TrendsView() }
                            .tabItem { Label("Trends", systemImage: "chart.bar.fill") }
                    }
                    .environmentObject(theme)
                    .environmentObject(sleepMgr)
                    .environmentObject(store)
                    .accentColor(theme.color)
                    .transition(.opacity)
                }
            }
        }
    }
}
