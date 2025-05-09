import Foundation
import Combine

final class SleepStore: ObservableObject {
    @Published private(set) var week:[SleepEntry] = []

    private let url: URL
    private var bag = Set<AnyCancellable>()

    init(manager: SleepManager) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        url = dir.appendingPathComponent("sleep.json")
        load()

        manager.$lastBedtimes.combineLatest(manager.$lastHours)
            .sink { [weak self] (starts, hrs) in
                self?.upsertYesterday(bedtimes: starts, hours: hrs)
            }
            .store(in: &bag)
    }

    // MARK: quality helpers
    private var yesterday: Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(-86_400)
    }
    func yesterdayQuality() -> Int {
        week.first { Calendar.current.isDate($0.date, inSameDayAs: yesterday) }?.quality ?? 3
    }
    func updateQuality(_ q: Int) {
        if let idx = week.firstIndex(where:{ Calendar.current.isDate($0.date, inSameDayAs: yesterday) }) {
            week[idx].quality = q
        } else {
            week.append(SleepEntry(date: yesterday, bedtimes: [], hours: 0, quality: q))
        }
        trimSave()
    }

    // MARK: upsert yesterday’s hours/bedtimes
    private func upsertYesterday(bedtimes:[Date], hours:Double) {
        if let i = week.firstIndex(where:{ Calendar.current.isDate($0.date, inSameDayAs: yesterday) }) {
            week[i].bedtimes = bedtimes; week[i].hours = hours
        } else {
            week.append(SleepEntry(date: yesterday, bedtimes: bedtimes, hours: hours, quality: 3))
        }
        trimSave()
    }

    // MARK: persistence helpers
    private func trimSave() {
        week = Array(week.sorted{ $0.date > $1.date }.prefix(7)).sorted{ $0.date < $1.date }
        if let d = try? JSONEncoder().encode(week) { try? d.write(to: url) }
    }
    private func load() {
        if let d = try? Data(contentsOf: url),
           let arr = try? JSONDecoder().decode([SleepEntry].self, from: d) { week = arr }
    }
}
