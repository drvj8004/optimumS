import SwiftUI
import Charts

/// Trends tab – 7-day graphs + personalised tips.
struct TrendsView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var store: SleepStore
    
    var body: some View {
        List {
            // ───── Bedtime scatter ───────────────────────────────────────────
            Section(header: Text("Bedtimes").font(.headline)) {
                Chart(store.week) { entry in
                    ForEach(entry.bedtimes, id: \.self) { bt in
                        PointMark(
                            x: .value("Day", DateUtils.weekdayShort(entry.date)),
                            y: .value("Bedtime", hourFraction(bt))
                        )
                        .foregroundStyle(theme.color)
                    }
                }
                .chartYScale(domain: 0 ... 12)
                .frame(height: 180)
            }
            
            // ───── Hours slept bar ───────────────────────────────────────────
            Section(header: Text("Hours Slept").font(.headline)) {
                Chart(store.week) { e in
                    BarMark(
                        x: .value("Day", DateUtils.weekdayShort(e.date)),
                        y: .value("Hours", e.hours)
                    )
                    .foregroundStyle(theme.color)
                }
                .frame(height: 180)
            }
            
            // ───── Sleep quality line ────────────────────────────────────────
            Section(header: Text("Sleep Quality").font(.headline)) {
                Chart(store.week) { e in
                    LineMark(
                        x: .value("Day", DateUtils.weekdayShort(e.date)),
                        y: .value("Quality", e.quality)
                    )
                    .foregroundStyle(theme.color)
                    
                    PointMark(
                        x: .value("Day", DateUtils.weekdayShort(e.date)),
                        y: .value("Quality", e.quality)
                    )
                    .foregroundStyle(theme.color)
                }
                .frame(height: 160)
            }
            
            // ───── Daily steps (theme-coloured) ──────────────────────────────
            if store.week.contains(where: { $0.steps != nil }) {
                Section(header: Text("Daily Steps").font(.headline)) {
                    Chart(store.week) { e in
                        BarMark(
                            x: .value("Day", DateUtils.weekdayShort(e.date)),
                            y: .value("Steps", e.steps ?? 0)
                        )
                        .foregroundStyle(theme.color.opacity(0.70))   // ← uses accent tint
                    }
                    .frame(height: 160)
                }
            }
            
            // ───── Suggestions list ─────────────────────────────────────────
            Section(header: Text("Suggestions").font(.headline)) {
                ForEach(suggestions(), id: \.self) { tip in
                    Text("• \(tip)")
                        .font(.custom("ChalkboardSE-Regular", size: 14))
                        .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Last 7 Days")
        .foregroundColor(.white)
        .scrollContentBackground(.hidden)
        .background(
            Image("NightSky")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
    }
    
    // MARK: – helpers ----------------------------------------------------------
    
    private func hourFraction(_ date: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(c.hour! % 12) + Double(c.minute!) / 60.0
    }
    
    private func suggestions() -> [String] {
        var tips: [String] = []
        
        let goal = SleepStore.userSleepGoalHours()
        let debt = store.week.reduce(0.0) { total, e in
            let d = goal - e.hours
            return d > 0 ? total + d : total
        }
        if debt > 0.5 {
            tips.append(String(format:
                "You accumulated %.1f h of sleep debt – aim for an earlier bed.", debt))
        } else { tips.append("Great job keeping debt low!") }
        
        let firsts = store.week.compactMap { $0.bedtimes.first }
        if firsts.count >= 2 {
            let mins = firsts.map {
                60 * Calendar.current.component(.hour,   from: $0) +
                     Calendar.current.component(.minute, from: $0)
            }
            if let lo = mins.min(), let hi = mins.max(), hi - lo > 120 {
                tips.append("Your bedtime shifts more than 2 h – try to stay consistent.")
            }
        }
        
        let valid = store.week.compactMap(\.steps)
        if !valid.isEmpty {
            let avg = valid.reduce(0, +) / valid.count
            if avg < 5_000 {
                tips.append("Average steps ≈ \(avg). More daytime activity can improve sleep.")
            }
        }
        
        let avgH = store.week.map(\.hours).reduce(0, +) / Double(max(store.week.count, 1))
        if avgH + 0.5 < goal {
            tips.append(String(format:
                "You're averaging %.1f h vs %.0f h goal – go to bed earlier.", avgH, goal))
        }
        
        return tips
    }
}
