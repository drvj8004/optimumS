
import HealthKit

enum HealthKitManager {
    private static let store = HKHealthStore()

    static func requestAuthorization(completion: @escaping(Bool)->Void) {
        guard let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(false); return
        }
        store.requestAuthorization(toShare: [sleep],
                                   read: [sleep,steps]) { ok,_ in
            DispatchQueue.main.async { completion(ok) }
        }
    }

    static func fetchSteps(for date: Date, completion: @escaping(Int)->Void) {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(0); return
        }
        let start = Calendar.current.startOfDay(for: date)
        let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let pred  = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let q = HKStatisticsQuery(quantityType: stepsType,
                                  quantitySamplePredicate: pred,
                                  options: .cumulativeSum) { _, s, _ in
            let val = s?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            completion(Int(val))
        }
        store.execute(q)
    }
}
