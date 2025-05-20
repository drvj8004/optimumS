
import Foundation
import CoreMotion
import Combine

/// Publishes the previous night’s consolidated sleep summary.
final class SleepManager: ObservableObject {
    // MARK: – Published
    @Published var lastHours: Double = 0
    @Published var lastBedtimes: [Date] = []
    @Published var lastDateLabel: String = "--"

    // MARK: – Private
    private let motion = CMMotionActivityManager()
    private var refreshTimer: Timer?
    private let queue = OperationQueue()

    init() {
        refresh()
        scheduleMidnightRefresh()
    }

    func forceRefresh() { refresh() }

    // MARK: – Motion query + processing
    private func refresh() {
        let today00 = Calendar.current.startOfDay(for: Date())
        let windowStart = today00.addingTimeInterval(-48*3600)   // lookback 48 h
        guard CMMotionActivityManager.isActivityAvailable() else { return }

        motion.queryActivityStarting(from: windowStart, to: today00, to: .main) { [weak self] acts, err in
            guard let self, let acts else { return }

            let yesterday00 = today00.addingTimeInterval(-86400)
            let segments = MotionSleepDetector.detectSleepSegments(from: acts)
                .map { (max($0.0,yesterday00), min($0.1,today00)) }
                .filter { $0.1 > $0.0 }

            let hours = segments.reduce(0) { $0 + $1.1.timeIntervalSince($1.0) } / 3600
            DispatchQueue.main.async {
                self.lastHours = (hours*10).rounded()/10
                self.lastBedtimes = segments.map { $0.0 }.sorted()
                self.lastDateLabel = DateUtils.weekdayShort(yesterday00)
            }
        }
    }

    // MARK: – Schedule next midnight auto‑refresh
    private func scheduleMidnightRefresh() {
        if let next = Calendar.current.nextDate(after: Date(),
                                                matching: DateComponents(hour:0, minute:0),
                                                matchingPolicy: .nextTime) {
            refreshTimer = Timer(fireAt: next, interval: 0, target: self,
                                 selector: #selector(triggerTimer),
                                 userInfo: nil, repeats: false)
            RunLoop.main.add(refreshTimer!, forMode: .common)
        }
    }

    @objc private func triggerTimer() {
        refresh()
        scheduleMidnightRefresh()
    }
}
