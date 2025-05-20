
import UserNotifications
import Foundation

enum NotificationManager {
    static func request(_ cb:@escaping(Bool)->Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert,.sound]) { ok,_ in
                DispatchQueue.main.async { cb(ok) }
            }
    }

    // MARK: – Bedtime cues
    static func scheduleBedtimeCues(for bedtime: Date) {
        let caffeine = bedtime.addingTimeInterval(-6*3600)
        let windDown = bedtime.addingTimeInterval(-3600)
        oneOff(id: "caffeine", title: "Caffeine cut‑off",
               body: "Last caffeine now for better sleep.",
               fire: caffeine)
        oneOff(id: "windDown", title: "Wind‑down",
               body: "Start winding down – bedtime soon.",
               fire: windDown)
    }

    // MARK: – Repeating alarm
    static func scheduleDailyAlarm(at wake: Date) {
        let comps = Calendar.current.dateComponents([.hour,.minute], from: wake)
        let c = UNMutableNotificationContent()
        c.title = "Wake Up"
        c.body  = "Good morning!"
        c.sound = .defaultCritical
        let trig = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: "dailyAlarm", content: c, trigger: trig)
        let ctr = UNUserNotificationCenter.current()
        ctr.removePendingNotificationRequests(withIdentifiers: ["dailyAlarm"])
        ctr.add(req)
    }

    // MARK: – helpers
    private static func oneOff(id:String,title:String,body:String,fire:Date) {
        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: fire)
        let c = UNMutableNotificationContent()
        c.title = title; c.body = body; c.sound = .default
        let trig = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: id, content: c, trigger: trig))
    }
}
