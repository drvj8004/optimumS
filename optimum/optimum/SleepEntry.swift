import Foundation

struct SleepEntry: Identifiable, Codable {
    var id = UUID()
    var date:     Date
    var bedtimes: [Date]
    var hours:    Double
    var quality:  Int
}
