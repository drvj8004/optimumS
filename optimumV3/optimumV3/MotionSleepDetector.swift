import CoreMotion
import Foundation

/// Heuristic consolidation of CMMotionActivity into nightly sleep segments.
enum MotionSleepDetector {
    
    /// - Parameters:
    ///   - activities:  Raw `CMMotionActivity` samples from Core Motion.
    ///   - minDuration: **Now 5 h by default** — segments shorter than this are discarded.
    ///   - mergeGap:    Gap (seconds) within which adjacent stationary blocks are merged.
    /// - Returns:       Array of consolidated `(start, end)` pairs representing sleep.
    static func detectSleepSegments(
        from activities: [CMMotionActivity],
        minDuration: TimeInterval = 5 * 3600,          //  ← raised from 3 h to 5 h
        mergeGap:    TimeInterval = 15 * 60
    ) -> [(Date, Date)] {
        
        guard !activities.isEmpty else { return [] }
        
        // ───── 1. raw stationary periods ─────────────────────────────────────
        var blocks: [(Date, Date)] = []
        var currentStart: Date?
        
        for act in activities {
            if act.stationary && act.confidence != .low {
                if currentStart == nil { currentStart = act.startDate }
            } else {
                if let s = currentStart {
                    blocks.append((s, act.startDate))
                    currentStart = nil
                }
            }
        }
        if let s = currentStart {
            blocks.append((s, activities.last!.startDate))
        }
        
        guard !blocks.isEmpty else { return [] }
        
        // ───── 2. merge gaps ≤ mergeGap ──────────────────────────────────────
        let sorted = blocks.sorted { $0.0 < $1.0 }
        var merged: [(Date, Date)] = []
        var start = sorted[0].0
        var end   = sorted[0].1
        
        for seg in sorted.dropFirst() {
            if seg.0.timeIntervalSince(end) <= mergeGap {
                end = seg.1                               // extend current block
            } else {
                merged.append((start, end))
                start = seg.0
                end   = seg.1
            }
        }
        merged.append((start, end))                        // push final block
        
        // ───── 3. filter out blocks < minDuration ────────────────────────────
        return merged.filter { $0.1.timeIntervalSince($0.0) >= minDuration }
    }
}
