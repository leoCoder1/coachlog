import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthKitManager {
    var authorizationStatusText = "Not requested"
    var lastImportMessage = "HealthKit can provide sleep, resting HR, HRV, body weight, and workouts."

    @ObservationIgnored private let healthStore = HKHealthStore()

    init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatusText = "Unavailable"
            lastImportMessage = "HealthKit is not available on this device. Recovery imports will use safe defaults."
            return
        }
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatusText = "Unavailable"
            lastImportMessage = "HealthKit is unavailable here. Mock recovery data can still be used."
            return false
        }

        let readTypes = healthReadTypes()

        do {
            let success = try await requestAuthorization(readTypes: readTypes)
            authorizationStatusText = success ? "Requested" : "Not completed"
            lastImportMessage = success
                ? "HealthKit request completed. Apple keeps read permissions private, so imports will use any values the user allowed."
                : "HealthKit request did not complete. Recovery imports can still use safe defaults."
            return success
        } catch {
            authorizationStatusText = "Failed"
            lastImportMessage = error.localizedDescription
            return false
        }
    }

    func importRecoverySnapshot() async -> RecoverySnapshot {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastImportMessage = "Using mock recovery because HealthKit is unavailable."
            return .mock
        }

        async let sleepHours = latestSleepHours()
        async let restingHeartRate = latestQuantity(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute())
        )
        async let hrv = latestQuantity(
            identifier: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli)
        )

        let importedSleep = await sleepHours
        let importedRestingHeartRate = await restingHeartRate
        let importedHRV = await hrv
        let sleep = importedSleep ?? RecoverySnapshot.mock.sleepHours
        let rhr = importedRestingHeartRate ?? RecoverySnapshot.mock.restingHeartRate
        let hrvValue = importedHRV ?? RecoverySnapshot.mock.hrv
        let readiness = readinessScore(sleepHours: sleep, restingHeartRate: rhr, hrv: hrvValue)

        lastImportMessage = importMessage(
            sleepHours: importedSleep,
            restingHeartRate: importedRestingHeartRate,
            hrv: importedHRV
        )
        return RecoverySnapshot(
            sleepHours: sleep,
            restingHeartRate: rhr,
            hrv: hrvValue,
            readinessScore: readiness
        )
    }

    func latestBodyWeight() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastImportMessage = "Body weight is unavailable because HealthKit is not available here."
            return nil
        }

        let weight = await latestQuantity(identifier: .bodyMass, unit: .pound())
        lastImportMessage = weight == nil
            ? "No HealthKit body weight was returned. Check Apple Health permissions and whether weight data exists."
            : "Imported latest body weight from HealthKit."
        return weight
    }

    private func healthReadTypes() -> Set<HKObjectType> {
        var types = Set<HKObjectType>()

        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }

        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHeartRate)
        }

        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }

        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }

        types.insert(HKObjectType.workoutType())
        return types
    }

    private func requestAuthorization(readTypes: Set<HKObjectType>) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    private func latestQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    private func latestSleepHours() async -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .hour, value: -36, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: .now)
        let asleepValues = Self.asleepValues

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let sleepSeconds = (samples as? [HKCategorySample])?
                    .filter { sample in
                        asleepValues.contains(sample.value)
                    }
                    .reduce(0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    } ?? 0

                continuation.resume(returning: sleepSeconds > 0 ? sleepSeconds / 3600 : nil)
            }

            healthStore.execute(query)
        }
    }

    private func readinessScore(sleepHours: Double, restingHeartRate: Double, hrv: Double) -> Int {
        var score = 70

        if sleepHours >= 7 {
            score += 12
        } else if sleepHours < 6 {
            score -= 18
        }

        if restingHeartRate <= 60 {
            score += 8
        } else if restingHeartRate >= 72 {
            score -= 10
        }

        if hrv >= 55 {
            score += 10
        } else if hrv < 35 {
            score -= 12
        }

        return min(100, max(1, score))
    }

    private func importMessage(
        sleepHours: Double?,
        restingHeartRate: Double?,
        hrv: Double?
    ) -> String {
        var missingValues: [String] = []

        if sleepHours == nil {
            missingValues.append("sleep")
        }
        if restingHeartRate == nil {
            missingValues.append("resting HR")
        }
        if hrv == nil {
            missingValues.append("HRV")
        }

        if missingValues.isEmpty {
            return "Imported recovery snapshot from HealthKit."
        }

        if missingValues.count == 3 {
            return "No HealthKit recovery values were returned. Check Apple Health permissions or sample availability; using safe defaults."
        }

        return "Imported partial HealthKit recovery. Missing \(missingValues.joined(separator: ", ")) uses safe defaults."
    }

    private static var asleepValues: Set<Int> {
        [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
    }
}
