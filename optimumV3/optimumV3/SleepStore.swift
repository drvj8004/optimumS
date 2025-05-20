import Foundation
import Combine

/// Stores the last 7 nights, handles quality logic & JSON persistence.
final class SleepStore: ObservableObject {
    @Published private(set) var week: [SleepEntry] = []
    
    private let manager: SleepManager
    private let fileURL: URL
    private var subs = Set<AnyCancellable>()
    
    // MARK: – init / load ------------------------------------------------------
    init(manager: SleepManager) {
        self.manager = manager
        
        let docs = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("sleep.json")
        load()
        bind()
    }
    
    // yesterday 00:00 (convenience)
    private var yesterday: Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(-86_400)
    }
    
    // MARK: – Combine link to SleepManager ------------------------------------
    private func bind() {
        manager.$lastBedtimes
            .combineLatest(manager.$lastHours)
            .sink { [weak self] (starts, hrs) in
                self?.updateYesterday(bedtimes: starts, hours: hrs)
            }
            .store(in: &subs)
    }
    
    // MARK: – public helpers ---------------------------------------------------
    func yesterdayQuality() -> Int {
        week.first(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) })?
            .quality ?? 3
    }
    
    func updateQuality(_ newQuality: Int) {
        if let i = week.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) }) {
            week[i].quality = newQuality
        } else {
            week.append(SleepEntry(date: yesterday, quality: newQuality))
        }
        saveTrimmed()
    }
    
    // MARK: – core update when new motion data arrives ------------------------
    private func updateYesterday(bedtimes: [Date], hours: Double) {
        guard hours > 0 else { return }
        let d      = yesterday
        let idx    = week.firstIndex { Calendar.current.isDate($0.date, inSameDayAs: d) }
        let target = Self.targetBedtimeDate(for: d)
        let goal   = Self.userSleepGoalHours()
        let recent = week.compactMap { $0.bedtimes.first }
        
        var entry = idx != nil ? week[idx!] : SleepEntry(date: d)
        entry.bedtimes = bedtimes
        entry.hours    = hours
        
        // predicted quality
        let predicted = SleepAnalyzer.predictQuality(
            hours: hours,
            goalHours: goal,
            segments: bedtimes.count,
            steps: entry.steps,
            bedtime: bedtimes.first,
            targetBedtime: target,
            recentBedtimes: recent
        )
        
        let userOverrode = idx != nil && week[idx!].quality != predicted
        if !userOverrode { entry.quality = predicted }
        
        if let i = idx { week[i] = entry } else { week.append(entry) }
        saveTrimmed()
        
        // fetch step count, then maybe update quality again
        HealthKitManager.fetchSteps(for: d) { [weak self] steps in
            DispatchQueue.main.async {
                guard let self else { return }
                if let i = self.week.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: d) }) {
                    var e = self.week[i]
                    e.steps = steps
                    
                    let predicted2 = SleepAnalyzer.predictQuality(
                        hours: e.hours,
                        goalHours: goal,
                        segments: e.bedtimes.count,
                        steps: steps,
                        bedtime: e.bedtimes.first,
                        targetBedtime: target,
                        recentBedtimes: recent
                    )
                    let userOverrode2 = e.quality != predicted2
                    if !userOverrode2 { e.quality = predicted2 }
                    
                    self.week[i] = e
                    self.saveTrimmed()
                }
            }
        }
    }
    
    // MARK: – persistence ------------------------------------------------------
    private func saveTrimmed() {
        week = Array(week.sorted { $0.date < $1.date }.suffix(7))
        if let data = try? JSONEncoder().encode(week) {
            try? data.write(to: fileURL)
        }
        objectWillChange.send()
    }
    
    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let arr  = try? JSONDecoder().decode([SleepEntry].self, from: data) {
            week = arr.sorted { $0.date < $1.date }
        }
    }
    
    // MARK: – Goal / target helpers (unchanged logic) -------------------------
    /// Compute nightly goal from user’s chosen bedtime & alarm.
    static func userSleepGoalHours() -> Double {
        let btH = UserDefaults.standard.integer(forKey: "targetHour")
        let btM = UserDefaults.standard.integer(forKey: "targetMinute")
        let alH = UserDefaults.standard.object(forKey: "alarmHour") as? Int ?? 7
        let alM = UserDefaults.standard.object(forKey: "alarmMinute") as? Int ?? 0
        
        guard btH != 0 || btM != 0 else { return 8.0 }        // fallback
        
        let bt = btH * 60 + btM
        let al = alH * 60 + alM
        let diff = btH >= 18 ? (24*60 - bt) + al : (al - bt)
        return Double(max(diff, 0)) / 60.0
    }
    
    /// Build a Date representing the user’s target bedtime for a given night.
    static func targetBedtimeDate(for day: Date) -> Date? {
        let h = UserDefaults.standard.integer(forKey: "targetHour")
        let m = UserDefaults.standard.integer(forKey: "targetMinute")
        guard h != 0 || m != 0 else { return nil }
        
        var comps = Calendar.current.dateComponents([.year,.month,.day], from: day)
        comps.hour = h; comps.minute = m
        if h < 18 { comps.day! += 1 }          // after-midnight target
        return Calendar.current.date(from: comps)
    }
}
