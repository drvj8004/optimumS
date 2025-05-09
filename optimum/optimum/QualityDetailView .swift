import SwiftUI

struct QualityDetailView: View {

    // incoming bindings
    @Binding var quality: Int
    var caffeine:  Date
    var melatonin: Date

    // ───── persistent alarm time ─────
    @AppStorage("alarmHour")   private var alarmHour   : Int = 7
    @AppStorage("alarmMinute") private var alarmMinute : Int = 0

    // UI helpers
    @State private var showSaved = false
    @EnvironmentObject private var theme: ThemeManager

    // MARK: - view -------------------------------------------------------
    var body: some View {
        Form {

            // 1 ── Rate
            Section("Rate") {
                Picker("", selection: $quality) {
                    ForEach(1...5, id:\.self) { v in
                        Text(String(repeating: "★", count: v)).tag(v)
                    }
                }
                .pickerStyle(.segmented)
            }

            // 2 ── Advice
            Section("Advice") {
                HStack { Text("No caffeine after"); Spacer(); Text(ts(caffeine)) }
                HStack { Text("Take melatonin at"); Spacer(); Text(ts(melatonin)) }
            }

            // 3 ── Alarm
            Section("Alarm") {
                // Bind the DatePicker through a computed Binding<Date>
                DatePicker("Wake‑up time",
                           selection: Binding(
                               get: { Self.date(h: alarmHour, m: alarmMinute) },
                               set: { newDate in
                                   let comps = Calendar.current.dateComponents([.hour,.minute], from: newDate)
                                   alarmHour   = comps.hour   ?? 7
                                   alarmMinute = comps.minute ?? 0
                               }),
                           displayedComponents: [.hourAndMinute])

                Button("Save Alarm") {
                    let d = Self.date(h: alarmHour, m: alarmMinute)
                    NotificationManager.scheduleDailyAlarm(at: d)    // add soundFile: if desired
                    flashSavedLabel()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .tint(theme.color)

                if showSaved {
                    Text("Alarm saved!")
                        .font(.caption.bold())
                        .foregroundColor(theme.color)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                }
            }
        }
        .navigationTitle("Sleep Quality")
    }

    // MARK: - helpers ----------------------------------------------------
    private func flashSavedLabel() {
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }

    private func ts(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }

    private static func date(h: Int, m: Int) -> Date {
        Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date())!
    }
}
