import SwiftUI
import Charts

struct Last7DaysView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var store: SleepStore

    var body: some View {
        List {

            // ───── BEDTIME: one point per 3 h+ block ─────
            Section("Bedtime") {
                Chart {
                    ForEach(store.week) { entry in
                        ForEach(entry.bedtimes, id: \.self) { bt in
                            PointMark(
                                x: .value("Day", weekday(entry.date)),
                                y: .value("Clock", hourFrac(bt))
                            )
                            .foregroundStyle(theme.color)
                        }
                    }
                }
                .chartYScale(domain: 0 ... 12)     // 0 = midnight, 12 = noon
                .frame(height: 180)
            }

            // ───── HOURS SLEPT: sum of all blocks ─────
            Section("Hours slept") {
                Chart {
                    ForEach(store.week) { entry in
                        BarMark(
                            x: .value("Day", weekday(entry.date)),
                            y: .value("Hours", entry.hours)
                        )
                        .foregroundStyle(theme.color)
                    }
                }
                .frame(height: 180)
            }

            // ───── AVG QUALITY (stars) ─────
            Section("Avg quality") {
                Chart {
                    ForEach(store.week) { entry in
                        LineMark(
                            x: .value("Day", weekday(entry.date)),
                            y: .value("★", entry.quality)
                        )
                        .foregroundStyle(theme.color)
                    }
                }
                .frame(height: 120)
            }
        }
        .navigationTitle("Last 7 Days")
    }

    // short weekday (“Mon”, “Tue”…)
    private func weekday(_ d: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f.string(from: d)
    }

    // fractional hour in 0–12 range
    private func hourFrac(_ d: Date) -> Double {
        let c = Calendar.current
        let h = c.component(.hour,   from: d) % 12
        let m = c.component(.minute, from: d)
        return Double(h) + Double(m) / 60.0
    }
}
