import Foundation

/// Non-ML, rule-based sleep-quality score (1 = poor … 5 = excellent).
enum SleepAnalyzer {

    /// Predict a star rating for a single night.
    static func predictQuality(
        hours: Double,
        goalHours: Double,
        segments: Int,
        steps: Int?,
        bedtime: Date?,
        targetBedtime: Date?,
        recentBedtimes: [Date]
    ) -> Int {

        var score = 5

        // ───── 1. duration vs goal ─────────────────────────────────────────────
        let severeDeficit = goalHours * 0.80     // > 20 % below goal
        if hours < severeDeficit {
            score -= 2
        } else if hours < goalHours {
            score -= 1
        }

        // ───── 2. fragmentation ───────────────────────────────────────────────
        if segments > 1 { score -= 1 }
        if segments > 2 { score -= 1 }    // multiple awakenings

        // ───── 3. bedtime regularity ──────────────────────────────────────────
        if recentBedtimes.count >= 2 {
            let minutes = recentBedtimes.map(Self.minutesFrom6pm)
            let mean    = minutes.reduce(0, +) / Double(minutes.count)
            let avgDev  = minutes.reduce(0) { $0 + abs($1 - mean) } / Double(minutes.count)
            if avgDev > 60 { score -= 1 }   // > 1 h average deviation
        }

        // deviation from user-set target
        if let tgt = targetBedtime,
           let actual = bedtime,
           abs(actual.timeIntervalSince(tgt)) > 3_600 {
            score -= 1
        }

        // ───── 4. daytime activity ────────────────────────────────────────────
        if let stepCount = steps, stepCount < 3_000 {
            score -= 1            // very low activity
        }

        return max(1, min(score, 5))
    }

    /// Minutes from 6 PM; times after midnight roll past 24 h for continuity.
    private static func minutesFrom6pm(_ date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let h = comps.hour, let m = comps.minute else { return 0 }
        var total = Double(h * 60 + m)
        if h < 18 { total += 24 * 60 }    // 0:00->5:59 treated as next day
        return total
    }
}
