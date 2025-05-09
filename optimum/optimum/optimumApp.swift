import SwiftUI

@main
struct OptimumApp: App {

    // one global copy of each manager / store
    @StateObject private var theme        = ThemeManager()
    @StateObject private var sleepManager : SleepManager
    @StateObject private var store       : SleepStore

    // splash toggle
    @State private var showSplash = true

    init() {
        // must create plain instances *first*, then wrap them
        let sm = SleepManager()
        _sleepManager = StateObject(wrappedValue: sm)
        _store        = StateObject(wrappedValue: SleepStore(manager: sm))

        // ask for notification permission once
        NotificationManager.request { _ in }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView(showSplash: $showSplash)
                        .transition(.opacity)
                } else {
                    ContentView()
                        .environmentObject(theme)
                        .environmentObject(sleepManager)
                        .environmentObject(store)
                        .transition(.opacity)
                }
            }
        }
    }
}
