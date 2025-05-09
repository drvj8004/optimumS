import CoreMotion
import Combine
import Foundation

final class SleepManager: ObservableObject {
    @Published var lastHours:    Double = 0
    @Published var lastBedtimes: [Date] = []
    @Published var lastDateLabel = "--"

    private let motion = CMMotionActivityManager()
    private var timer : Timer?

    init() { refresh(); scheduleMidnight() }

    // MARK: - public
    func forceRefresh() { refresh() }

    // MARK: - refresh
    private func refresh() {
        let today    = Calendar.current.startOfDay(for: Date())
        let dayStart = today.addingTimeInterval(-86_400)          // yesterday 00:00
        let fetchFrom = dayStart.addingTimeInterval(-86_400)      // 48 h window

        guard CMMotionActivityManager.isActivityAvailable() else { return }

        motion.queryActivityStarting(from: fetchFrom, to: today, to: .main) { [weak self] acts, _ in
            guard let self, let acts else { return }
            var blocks:[(Date,Date)] = []; var current:Date?

            for act in acts {
                if act.stationary && act.confidence != .low {
                    current = current ?? act.startDate
                } else if let s = current {
                    blocks.append((s, act.startDate)); current = nil
                }
            }
            if let s = current { blocks.append((s, today)) }

            self.process(raw: blocks, windowStart: dayStart, windowEnd: today)
        }
    }

    // MARK: - process raw motion blocks
    private func process(raw:[(Date,Date)], windowStart: Date, windowEnd: Date) {
        let minDur = 3.0 * 3600
        var totalInside: TimeInterval = 0
        var starts:[Date] = []

        for (rawS, rawE) in raw {
            let rawDur = rawE.timeIntervalSince(rawS)
            guard rawDur >= minDur else { continue }

            let clipS = max(rawS, windowStart)
            let clipE = min(rawE, windowEnd)
            let inside = max(0, clipE.timeIntervalSince(clipS))
            guard inside > 0 else { continue }

            totalInside += inside
            starts.append(rawS)
        }
        starts.sort()

        DispatchQueue.main.async {
            self.lastHours     = round(totalInside/360) / 10
            self.lastBedtimes  = starts
            self.lastDateLabel = Self.label(for: windowStart)
        }
    }

    private static func label(for d:Date)->String {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f.string(from:d)
    }

    // MARK: - midnight refresh
    private func scheduleMidnight() {
        let next = Calendar.current.nextDate(after: Date(),
                                             matching: .init(hour:0,minute:0),
                                             matchingPolicy: .nextTime)!
        timer = Timer(fireAt: next, interval: 0, target: self,
                      selector: #selector(tick), userInfo: nil, repeats: false)
        RunLoop.main.add(timer!, forMode: .common)
    }
    @objc private func tick() { refresh(); scheduleMidnight() }
}
