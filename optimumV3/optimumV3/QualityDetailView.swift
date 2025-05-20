
import SwiftUI

struct QualityDetailView: View {
    @Binding var quality:Int
    var caffeine:Date
    var windDown:Date

    @AppStorage("alarmHour") private var alarmHour:Int = 7
    @AppStorage("alarmMinute") private var alarmMinute:Int = 0
    @EnvironmentObject private var theme:ThemeManager
    @State private var saved=false

    var body: some View {
        Form {
            Section("Rate Last Night") {
                Picker("Quality", selection:$quality){
                    ForEach(1...5,id:\ .self){ Text(String(repeating:"★",count:$0)).tag($0) }
                }.pickerStyle(.segmented)
            }
            Section("Advice"){
                row("No caffeine after", DateUtils.timeString(caffeine))
                row("Wind down by",      DateUtils.timeString(windDown))
            }
            Section("Alarm"){
                DatePicker("Wake‑up", selection: Binding(
                    get:{ DateUtils.targetDate(hour: alarmHour, minute: alarmMinute) },
                    set:{ v in
                        let c = Calendar.current.dateComponents([.hour,.minute], from:v)
                        alarmHour=c.hour ?? 7; alarmMinute=c.minute ?? 0
                    }), displayedComponents:[.hourAndMinute])
                Button("Save Alarm"){
                    NotificationManager.scheduleDailyAlarm(at:
                        DateUtils.targetDate(hour: alarmHour, minute: alarmMinute))
                    withAnimation{ saved=true }
                    DispatchQueue.main.asyncAfter(deadline:.now()+2){ withAnimation{ saved=false } }
                }
                if saved{
                    Text("Alarm saved!").font(.caption.bold()).foregroundColor(theme.color)
                }
            }
        }.navigationTitle("Sleep Quality")
    }

    @ViewBuilder private func row(_ left:String,_ right:String)->some View{
        HStack{ Text(left); Spacer(); Text(right) }
    }
}
