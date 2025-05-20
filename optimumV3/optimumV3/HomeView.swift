import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var mgr  : SleepManager
    @EnvironmentObject private var store: SleepStore
    
    @AppStorage("targetHour")   private var targetHour   = 23
    @AppStorage("targetMinute") private var targetMinute = 0
    @AppStorage("alarmHour")    private var alarmHour    = 7
    @AppStorage("alarmMinute")  private var alarmMinute  = 0
    
    @State private var showSaved = false
    @State private var quality   = 3
    
    /// Two columns on phones, adaptive on iPad.
    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 150), spacing: 14)] }
    
    var body: some View {
        ZStack {
            Image("NightSky")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    
                    Text("optimum")
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    
                    LazyVGrid(columns: columns, spacing: 14) {
                        
                        // ───── Hours slept ─────
                        tile("Hours Slept\n(\(mgr.lastDateLabel))") {
                            Text(mgr.lastHours > 0 ? String(format: "%.1f h", mgr.lastHours) : "--")
                                .font(.title3.bold())
                        }
                        
                        // ───── Quality rating ─────
                        NavigationLink {
                            QualityDetailView(
                                quality: $quality,
                                caffeine: DateUtils.targetDate(hour: targetHour, minute: targetMinute)
                                          .addingTimeInterval(-6*3600),
                                windDown: DateUtils.targetDate(hour: targetHour, minute: targetMinute)
                                          .addingTimeInterval(-3600)
                            )
                        } label: {
                            tile("Quality") { Stars(rating: quality, tint: theme.color) }
                        }
                        .onChange(of: quality) { store.updateQuality($0) }
                        
                        // ───── Bedtime ─────
                        NavigationLink {
                            BedtimeDetailView(times: mgr.lastBedtimes)
                        } label: {
                            tile("Bedtime\n(\(mgr.lastDateLabel))") {
                                Text(mgr.lastBedtimes.first.map(DateUtils.timeString) ?? "--")
                                    .font(.title3)
                            }
                        }
                        
                        // ───── Sleep debt ─────
                        tile("Sleep Debt\n(7 days)") {
                            Text(debtText())
                                .font(.title3.bold())
                        }
                        
                        // ───── Target bedtime picker ─────
                        tile("Your Target") {
                            VStack(spacing: 8) {
                                DatePicker("",
                                           selection: Binding(
                                             get:{ DateUtils.targetDate(hour: targetHour, minute: targetMinute) },
                                             set:{ v in
                                                 let c = Calendar.current.dateComponents([.hour,.minute], from: v)
                                                 targetHour   = c.hour ?? 23
                                                 targetMinute = c.minute ?? 0
                                             }),
                                           displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                
                                Button("Save") {
                                    NotificationManager.scheduleBedtimeCues(for:
                                        DateUtils.targetDate(hour: targetHour, minute: targetMinute))
                                    flashSaved()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(theme.color)
                                
                                if showSaved {
                                    Text("Time saved!")
                                        .font(.caption.bold())
                                        .foregroundColor(theme.color)
                                        .transition(.opacity)
                                }
                            }
                        }
                        
                        // ───── Theme picker ─────
                        tile("Theme") {
                            ColorPicker("",
                                        selection: Binding(
                                            get:{ theme.color },
                                            set:{ new in
                                                if let c = UIColor(new).cgColor.components, c.count >= 3 {
                                                    theme.r = c[0]; theme.g = c[1]; theme.b = c[2]
                                                    theme.commit()
                                                }
                                            }))
                                .labelsHidden()
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(theme.color.opacity(0.25)))
                        }
                    }
                    .padding(.horizontal, 22)      // ← wider safe-area inset prevents cropping
                    .padding(.bottom, 34)
                }
            }
        }
        .onAppear { quality = store.yesterdayQuality() }
    }
    
    // ──────────────────────────────────────────────────────────────────────────
    private func debtText() -> String {
        let goal   = SleepStore.userSleepGoalHours()
        let deficit = store.week.reduce(0.0) {
            let d = goal - $1.hours
            return d > 0 ? $0 + d : $0
        }
        return deficit < 0.1 ? "0 h" : String(format: "%.1f h", deficit)
    }
    
    private func flashSaved() {
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }
    
    // ───── Reusable card view ────────────────────────────────────────────────
    @ViewBuilder
    private func tile<Content: View>(_ title: String,
                                     @ViewBuilder _ inner: () -> Content) -> some View {
        
        @Environment(\.colorScheme) var scheme
        let tintOpacity = scheme == .dark ? 0.35 : 0.15   // darker overlay in dark mode
        
        VStack(spacing: 6) {
            Text(title)
                .font(.custom("ChalkboardSE-Regular", size: 13))
                .bold()
                .multilineTextAlignment(.center)
                .foregroundColor(theme.color)
            
            inner()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(minHeight: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)           // ← smaller radius avoids edge cut-off
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(tintOpacity))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12))
                )
                .shadow(color: .black.opacity(0.30), radius: 3, x: 1.5, y: 1.5)
        )
    }
}

// simple star rating view
private struct Stars: View {
    let rating: Int
    let tint: Color
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) {
                Image(systemName: $0 <= rating ? "star.fill" : "star")
            }
        }
        .foregroundColor(tint)
        .font(.title3)
    }
}
