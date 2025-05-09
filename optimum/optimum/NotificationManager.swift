import UserNotifications
import Foundation

enum NotificationManager {

    // ───────────────── permission ─────────────────
    static func request(_ cb: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { ok, _ in
                DispatchQueue.main.async { cb(ok) }
            }
    }

    // ─────────────── bedtime cues ────────────────
    static func scheduleBedtimeCues(for bedtime: Date) {
        guard let next = nextOccurrence(of: bedtime) else { return }

        oneOff(id: "caffeineCut",
               title: "Caffeine cut‑off",
               body: "Skip coffee from now until bed.",
               fire: next.addingTimeInterval(-6*3600))

        oneOff(id: "melatoninCue",
               title: "Melatonin reminder",
               body: "Take melatonin to be asleep by \(short(next)).",
               fire: next.addingTimeInterval(-3600))
    }

    // ─────────────── daily alarm ────────────────
    /// If `soundFile` is `nil`, uses `.defaultCritical`.
    /// Otherwise supply the **exact** file name you added to the Xcode bundle
    /// (must be ≤ 30 s, `caf/wav/aiff`).
    static func scheduleDailyAlarm(at time: Date, soundFile: String? = nil) {
        let comps = Calendar.current.dateComponents([.hour,.minute], from: time)

        let content = UNMutableNotificationContent()
        content.title = "Wake‑up"
        content.body  = "It's time to get up."
        content.sound = soundFile == nil
            ? .defaultCritical
            : UNNotificationSound(named: UNNotificationSoundName(soundFile!))

        let trig = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req  = UNNotificationRequest(identifier: "dailyAlarm", content: content, trigger: trig)

        let ctr = UNUserNotificationCenter.current()
        ctr.removePendingNotificationRequests(withIdentifiers: ["dailyAlarm"])
        ctr.add(req)
    }

    // ───────────────── helpers ───────────────────
    private static func oneOff(id: String, title: String, body: String, fire: Date) {
        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: fire)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let trig = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req  = UNNotificationRequest(identifier: id, content: content, trigger: trig)

        UNUserNotificationCenter.current()
            .add(req)
    }

    private static func nextOccurrence(of d: Date) -> Date? {
        var comps = Calendar.current.dateComponents([.hour,.minute], from: d)
        comps.second = 0
        var candidate = Calendar.current.nextDate(after: Date(),
                                                  matching: comps,
                                                  matchingPolicy: .nextTimePreservingSmallerComponents)!
        if candidate < Date() { candidate.addTimeInterval(86_400) }
        return candidate
    }

    private static func short(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }
}
