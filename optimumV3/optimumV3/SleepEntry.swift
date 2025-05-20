
import Foundation

/// Data model for one calendar‑day of sleep statistics.
struct SleepEntry: Identifiable, Codable {
    let id: UUID
    let date: Date                 // the “yesterday” this record describes
    var bedtimes: [Date]           // start of each consolidated sleep segment
    var hours: Double              // total hours slept inside the night window
    var quality: Int               // 1‑5 star rating
    var steps: Int?                // Health‑Kit daily steps (optional)

    init(id: UUID = UUID(),
         date: Date,
         bedtimes: [Date] = [],
         hours: Double = 0,
         quality: Int = 3,
         steps: Int? = nil) {
        self.id = id
        self.date = date
        self.bedtimes = bedtimes
        self.hours = hours
        self.quality = quality
        self.steps = steps
    }
}
