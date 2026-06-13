import Foundation
import HealthKit

/// Reads resting HR, HRV, SpO2, and sleep from HealthKit and aggregates them
/// into one VitalsSnapshot per day. Requires the HealthKit entitlement and a
/// real device for meaningful data.
struct LiveHealthSource: HealthDataSource {
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let t = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) { types.insert(t) }
        types.insert(HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!)
        return types
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func recentVitals(days: Int) async throws -> [VitalsSnapshot] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        try await requestAuthorization()

        let calendar = Calendar.current
        let end = calendar.startOfDay(for: Date()).addingTimeInterval(86_400)
        let start = calendar.date(byAdding: .day, value: -days, to: end) ?? end

        async let rhr = dailyAverage(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let hrv = dailyAverage(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: start, end: end)
        async let spo2 = dailyAverage(.oxygenSaturation, unit: .percent(), start: start, end: end)
        async let sleep = dailySleep(start: start, end: end)

        let (rhrByDay, hrvByDay, spo2ByDay, sleepByDay) = try await (rhr, hrv, spo2, sleep)

        var allDays = Set<Date>()
        allDays.formUnion(rhrByDay.keys)
        allDays.formUnion(hrvByDay.keys)
        allDays.formUnion(spo2ByDay.keys)
        allDays.formUnion(sleepByDay.keys)

        return allDays.sorted().map { day in
            VitalsSnapshot(
                date: day,
                restingHeartRate: rhrByDay[day],
                hrv: hrvByDay[day],
                spo2: spo2ByDay[day],
                sleepHours: sleepByDay[day]?.hours,
                sleepFragmentation: sleepByDay[day]?.fragmentation
            )
        }
    }

    // MARK: Quantity aggregation

    private func dailyAverage(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> [Date: Double] {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return [:] }
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: start)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: anchor,
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, results, error in
                if let error { continuation.resume(throwing: error); return }
                var out: [Date: Double] = [:]
                results?.enumerateStatistics(from: start, to: end) { stat, _ in
                    if let avg = stat.averageQuantity() {
                        out[calendar.startOfDay(for: stat.startDate)] = avg.doubleValue(for: unit)
                    }
                }
                continuation.resume(returning: out)
            }
            store.execute(query)
        }
    }

    // MARK: Sleep

    private struct SleepDay { var hours: Double; var fragmentation: Double }

    private func dailySleep(start: Date, end: Date) async throws -> [Date: SleepDay] {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return [:] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let calendar = Calendar.current

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
        ]
        let awakeValue = HKCategoryValueSleepAnalysis.awake.rawValue

        var asleepSecondsByDay: [Date: Double] = [:]
        var awakeSecondsByDay: [Date: Double] = [:]

        for sample in samples {
            // Attribute the night to the wake-up day.
            let day = calendar.startOfDay(for: sample.endDate)
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            if asleepValues.contains(sample.value) {
                asleepSecondsByDay[day, default: 0] += duration
            } else if sample.value == awakeValue {
                awakeSecondsByDay[day, default: 0] += duration
            }
        }

        var out: [Date: SleepDay] = [:]
        for (day, asleep) in asleepSecondsByDay {
            let awake = awakeSecondsByDay[day, default: 0]
            let inBed = asleep + awake
            let fragmentation = inBed > 0 ? awake / inBed : 0
            out[day] = SleepDay(hours: asleep / 3600, fragmentation: fragmentation)
        }
        return out
    }
}
