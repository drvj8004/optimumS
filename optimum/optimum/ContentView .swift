import SwiftUI

struct ContentView: View {

    // ───── shared objects from App ─────
    @EnvironmentObject private var theme : ThemeManager
    @EnvironmentObject private var mgr   : SleepManager
    @EnvironmentObject private var store : SleepStore

    // ───── persistent bedtime target ─────
    @AppStorage("targetHour")   private var targetHour   : Int = 23
    @AppStorage("targetMinute") private var targetMinute : Int = 0

    // ───── local UI state ─────
    @State private var showSaved = false
    @State private var quality   = 3                    // updated onAppear

    private let grid = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)

    // MARK: - body -------------------------------------------------------
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Text("optimum")
                    .font(.custom("Georgia", size: 46))
                    .frame(maxWidth: .infinity, alignment: .center)

                LazyVGrid(columns: grid, spacing: 20) {

                    // 1 —— last‑7‑day graph
                    NavigationLink { Last7DaysView(theme: theme, store: store) }
                    label: { Tile("Last‑7‑day\nSleep") }

                    // 2 —— bedtime target (PERSISTENT)
                    Tile("Your Target") {
                        VStack(spacing: 12) {
                            DatePicker("",
                                       selection: Binding(
                                           get: { Self.date(h: targetHour, m: targetMinute) },
                                           set: { new in
                                               let c = Calendar.current.dateComponents([.hour,.minute], from: new)
                                               targetHour   = c.hour   ?? 23
                                               targetMinute = c.minute ?? 0
                                           }),
                                       displayedComponents: .hourAndMinute)
                            .labelsHidden()

                            Button {
                                let d = Self.date(h: targetHour, m: targetMinute)
                                NotificationManager.scheduleBedtimeCues(for: d)
                                flashSaved()
                            } label: { Text("Save").frame(maxWidth: .infinity) }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(.systemGray5))
                            .foregroundColor(.primary)
                        }

                        if showSaved {
                            Text("Time saved!")
                                .font(.caption2.bold())
                                .transition(.opacity)
                        }
                    }

                    // 3 —— hours slept yesterday
                    Tile("Hours Slept\nyesterday (\(mgr.lastDateLabel))") {
                        Text(mgr.lastHours > 0
                             ? "\(mgr.lastHours, specifier: "%.1f") h"
                             : "--")
                            .font(.title2.bold())
                    }

                    // 4 —— yesterday bedtimes
                    NavigationLink { BedtimeDetailView(times: mgr.lastBedtimes) }
                    label: {
                        Tile("Bedtime\nyesterday (\(mgr.lastDateLabel))") {
                            Text(mgr.lastBedtimes.first.map(timeString) ?? "--")
                                .font(.title3)
                        }
                    }

                    // 5 —— quality rating
                    NavigationLink {
                        QualityDetailView(
                            quality:  $quality,
                            caffeine:  Self.date(h: targetHour, m: targetMinute)
                                      .addingTimeInterval(-6*3600),
                            melatonin: Self.date(h: targetHour, m: targetMinute)
                                      .addingTimeInterval(-3600)
                        )
                    } label: {
                        Tile("Quality") { Stars(rating: quality, tint: theme.color) }
                    }
                    .onChange(of: quality) { store.updateQuality($0) }

                    // 6 —— theme colour
                    Tile("Theme") {
                        ColorPicker("", selection: Binding(
                            get: { theme.color },
                            set: { new in
                                let c = UIColor(new).cgColor.components ?? [0,0,0,0]
                                theme.r = Double(c[0])
                                theme.g = Double(c[1])
                                theme.b = Double(c[2])
                                theme.commit()
                            }))
                        .labelsHidden()
                    }
                }
                .padding(20)
            }
            .accentColor(theme.color)
        }
        .onAppear { quality = store.yesterdayQuality() }
    }

    // MARK: - helpers ----------------------------------------------------
    private func flashSaved() {
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }

    private static func date(h: Int, m: Int) -> Date {
        Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date())!
    }

    private func timeString(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }
}

// ────────────────────────────────────────────────────────────────────────
// MARK: - Reusable dashboard tiles and star control
// ────────────────────────────────────────────────────────────────────────

private struct Tile<Content: View>: View {
    var title: String
    @ViewBuilder var inner: () -> Content
    @EnvironmentObject private var theme: ThemeManager

    init(_ t: String, @ViewBuilder _ inner: @escaping () -> Content = { EmptyView() }) {
        title = t; self.inner = inner
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption).bold()
                .multilineTextAlignment(.center)
            inner()
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .center)
        }
        .foregroundColor(theme.color)
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.12))
        )
    }
}

private struct Stars: View {
    var rating: Int
    var tint:   Color
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id:\.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundStyle(tint)
            }
        }
        .font(.title3)
    }
}
