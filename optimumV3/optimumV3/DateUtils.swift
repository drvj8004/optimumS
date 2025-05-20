
import Foundation

enum DateUtils {
    /// hh:mm a
    static func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    /// “Mon”, “Tue”, …
    static func weekdayShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f.string(from: date)
    }

    /// Make a Date for today / tomorrow at hour:minute
    static func targetDate(hour: Int, minute: Int) -> Date {
        let now = Date()
        var comps = Calendar.current.dateComponents([.year,.month,.day], from: now)
        comps.hour = hour
        comps.minute = minute
        var candidate = Calendar.current.date(from: comps)!
        if candidate < now {  // already passed, use tomorrow
            candidate = Calendar.current.date(byAdding: .day, value: 1, to: candidate)!
        }
        return candidate
    }
}
