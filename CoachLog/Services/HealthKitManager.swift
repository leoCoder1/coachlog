import Foundation
import HealthKit
import Observation

struct RecoveryImportResult {
    var snapshot: RecoverySnapshot?
    var message: String
    var importedMetricCount: Int
}

struct HealthKitWorkoutSaveResult {
    enum Status {
        case saved
        case skippedDuplicate
        case unavailable
        case authorizationDenied
        case failed
    }

    var status: Status
    var healthKitUUID: UUID?
    var message: String

    var didSave: Bool {
        status == .saved && healthKitUUID != nil
    }
}

enum HealthKitWorkoutSync {
    static let workoutWritingEnabledKey = "healthKitWorkoutWritingEnabled"
}

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

    func importRecoverySnapshot() async -> RecoveryImportResult {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastImportMessage = "Using mock recovery because HealthKit is unavailable."
            return RecoveryImportResult(snapshot: nil, message: lastImportMessage, importedMetricCount: 0)
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
        let importedMetricKeys = importedMetricKeys(
            sleepHours: importedSleep,
            restingHeartRate: importedRestingHeartRate,
            hrv: importedHRV
        )

        guard !importedMetricKeys.isEmpty else {
            lastImportMessage = "No HealthKit recovery samples were returned. Check Apple Health > Sharing > Apps > AI Coach and confirm Sleep, Resting Heart Rate, and HRV are enabled."
            return RecoveryImportResult(snapshot: nil, message: lastImportMessage, importedMetricCount: 0)
        }

        let sleep = importedSleep ?? RecoverySnapshot.mock.sleepHours
        let rhr = importedRestingHeartRate ?? RecoverySnapshot.mock.restingHeartRate
        let hrvValue = importedHRV ?? RecoverySnapshot.mock.hrv
        let readiness = readinessScore(sleepHours: sleep, restingHeartRate: rhr, hrv: hrvValue)

        lastImportMessage = importMessage(
            sleepHours: importedSleep,
            restingHeartRate: importedRestingHeartRate,
            hrv: importedHRV
        )
        let snapshot = RecoverySnapshot(
            sleepHours: sleep,
            restingHeartRate: rhr,
            hrv: hrvValue,
            readinessScore: readiness,
            source: importedMetricKeys.count == RecoveryMetricKey.allCases.count
                ? RecoverySnapshotSource.healthKit
                : RecoverySnapshotSource.partialHealthKit,
            importedMetricKeys: importedMetricKeys.map(\.rawValue).joined(separator: ","),
            importNote: lastImportMessage
        )

        return RecoveryImportResult(
            snapshot: snapshot,
            message: lastImportMessage,
            importedMetricCount: importedMetricKeys.count
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

    func requestWorkoutWriteAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatusText = "Unavailable"
            lastImportMessage = "HealthKit is unavailable on this device."
            return false
        }

        do {
            let success = try await requestAuthorization(shareTypes: healthWorkoutShareTypes())
            authorizationStatusText = success ? "Workout write requested" : "Not completed"
            lastImportMessage = success
                ? "HealthKit workout write request completed. Apple Health may still let you manage write access in Settings."
                : "HealthKit workout write request did not complete."
            return success
        } catch {
            authorizationStatusText = "Failed"
            lastImportMessage = error.localizedDescription
            return false
        }
    }

    func saveWorkoutToHealthIfNeeded(_ session: WorkoutSession) async -> HealthKitWorkoutSaveResult {
        guard HKHealthStore.isHealthDataAvailable() else {
            let message = "HealthKit is unavailable, so this workout stayed in AI Coach only."
            lastImportMessage = message
            return HealthKitWorkoutSaveResult(status: .unavailable, healthKitUUID: nil, message: message)
        }

        guard session.healthKitWorkoutUUID == nil else {
            let message = "This AI Coach workout was already saved to Apple Health."
            lastImportMessage = message
            return HealthKitWorkoutSaveResult(status: .skippedDuplicate, healthKitUUID: nil, message: message)
        }

        let workoutType = HKObjectType.workoutType()
        if healthStore.authorizationStatus(for: workoutType) != .sharingAuthorized {
            let authorized = await requestWorkoutWriteAuthorization()
            guard authorized,
                  healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized else {
                let message = "Apple Health workout write access is not enabled. The workout stayed in AI Coach only."
                authorizationStatusText = "Workout write denied"
                lastImportMessage = message
                return HealthKitWorkoutSaveResult(status: .authorizationDenied, healthKitUUID: nil, message: message)
            }
        }

        if let existingWorkout = await existingHealthWorkout(for: session) {
            let message = "Apple Health already has this AI Coach workout."
            authorizationStatusText = "Workout already saved"
            lastImportMessage = message
            return HealthKitWorkoutSaveResult(
                status: .skippedDuplicate,
                healthKitUUID: existingWorkout.uuid,
                message: message
            )
        }

        do {
            let workout = try await saveHealthWorkout(from: session)
            let message = "Saved completed workout to Apple Health."
            authorizationStatusText = "Workout write enabled"
            lastImportMessage = message
            return HealthKitWorkoutSaveResult(status: .saved, healthKitUUID: workout.uuid, message: message)
        } catch {
            authorizationStatusText = "Workout save failed"
            lastImportMessage = error.localizedDescription
            return HealthKitWorkoutSaveResult(status: .failed, healthKitUUID: nil, message: error.localizedDescription)
        }
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

    private func healthWorkoutShareTypes() -> Set<HKSampleType> {
        [HKObjectType.workoutType()]
    }

    private func requestAuthorization(readTypes: Set<HKObjectType>) async throws -> Bool {
        try await requestAuthorization(shareTypes: [], readTypes: readTypes)
    }

    private func requestAuthorization(
        shareTypes: Set<HKSampleType>,
        readTypes: Set<HKObjectType> = []
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    private func saveHealthWorkout(from session: WorkoutSession) async throws -> HKWorkout {
        let endDate = session.date
        let startDate = endDate.addingTimeInterval(-max(60, session.duration))
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: configuration,
            device: .local()
        )

        try await beginCollection(builder, at: startDate)
        try await addMetadata(healthWorkoutMetadata(for: session), to: builder)
        try await endCollection(builder, at: endDate)
        return try await finishWorkout(builder)
    }

    private func beginCollection(_ builder: HKWorkoutBuilder, at startDate: Date) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.beginCollection(withStart: startDate) { success, error in
                Self.resumeVoidContinuation(continuation, success: success, error: error)
            }
        }
    }

    private func addMetadata(_ metadata: [String: Any], to builder: HKWorkoutBuilder) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.addMetadata(metadata) { success, error in
                Self.resumeVoidContinuation(continuation, success: success, error: error)
            }
        }
    }

    private func endCollection(_ builder: HKWorkoutBuilder, at endDate: Date) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.endCollection(withEnd: endDate) { success, error in
                Self.resumeVoidContinuation(continuation, success: success, error: error)
            }
        }
    }

    private func finishWorkout(_ builder: HKWorkoutBuilder) async throws -> HKWorkout {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKWorkout, Error>) in
            builder.finishWorkout { workout, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let workout {
                    continuation.resume(returning: workout)
                } else {
                    continuation.resume(throwing: HealthKitWorkoutSaveError.saveDidNotComplete)
                }
            }
        }
    }

    private nonisolated static func resumeVoidContinuation(
        _ continuation: CheckedContinuation<Void, Error>,
        success: Bool,
        error: Error?
    ) {
        if let error {
            continuation.resume(throwing: error)
        } else if success {
            continuation.resume(returning: ())
        } else {
            continuation.resume(throwing: HealthKitWorkoutSaveError.saveDidNotComplete)
        }
    }

    private func existingHealthWorkout(for session: WorkoutSession) async -> HKWorkout? {
        let externalUUID = session.id.uuidString
        let endDate = session.date
        let startDate = endDate.addingTimeInterval(-max(60, session.duration) - 60)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate.addingTimeInterval(60),
            options: []
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let workout = (samples as? [HKWorkout])?.first { sample in
                    sample.metadata?[HKMetadataKeyExternalUUID] as? String == externalUUID
                }
                continuation.resume(returning: workout)
            }

            healthStore.execute(query)
        }
    }

    private func healthWorkoutMetadata(for session: WorkoutSession) -> [String: Any] {
        [
            HKMetadataKeyExternalUUID: session.id.uuidString,
            HKMetadataKeySyncIdentifier: "com.machvect.CoachLog.workout.\(session.id.uuidString)",
            HKMetadataKeySyncVersion: 1,
            HKMetadataKeyIndoorWorkout: true,
            HKMetadataKeyTimeZone: TimeZone.current.identifier,
            "com.machvect.CoachLog.sessionID": session.id.uuidString,
            "com.machvect.CoachLog.summary": healthWorkoutSummary(for: session),
            "com.machvect.CoachLog.exerciseCount": session.completedExercises.count,
            "com.machvect.CoachLog.setCount": totalSetCount(in: session)
        ]
    }

    private func healthWorkoutSummary(for session: WorkoutSession) -> String {
        let exerciseCount = session.completedExercises.count
        let setCount = totalSetCount(in: session)
        let minutes = Int((session.duration / 60).rounded())
        return "\(session.goal.displayName): \(exerciseCount) exercises, \(setCount) sets, \(minutes) min"
    }

    private func totalSetCount(in session: WorkoutSession) -> Int {
        session.completedExercises.reduce(0) { count, exercise in
            count + exercise.sets.count
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
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -14, to: .now) ?? .now
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: .now, options: .strictEndDate)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
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
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        let asleepValues = Self.asleepValues

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let intervals = (samples as? [HKCategorySample])?
                    .filter { sample in
                        asleepValues.contains(sample.value) && sample.endDate > sample.startDate
                    }
                    .map { SleepInterval(startDate: $0.startDate, endDate: $0.endDate) } ?? []

                let sleepSeconds = Self.latestMainSleepDuration(from: intervals, now: now)

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

    private func importedMetricKeys(
        sleepHours: Double?,
        restingHeartRate: Double?,
        hrv: Double?
    ) -> [RecoveryMetricKey] {
        var keys: [RecoveryMetricKey] = []

        if sleepHours != nil {
            keys.append(.sleep)
        }
        if restingHeartRate != nil {
            keys.append(.restingHeartRate)
        }
        if hrv != nil {
            keys.append(.hrv)
        }

        return keys
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
            return "No HealthKit recovery values were returned. Check Apple Health permissions or sample availability."
        }

        return "Imported partial HealthKit recovery. Missing \(missingValues.joined(separator: ", ")) will show as unavailable."
    }

    private nonisolated struct SleepInterval {
        var startDate: Date
        var endDate: Date

        var duration: TimeInterval {
            max(0, endDate.timeIntervalSince(startDate))
        }
    }

    private nonisolated static func latestMainSleepDuration(
        from intervals: [SleepInterval],
        now: Date
    ) -> TimeInterval {
        let mergedIntervals = mergedSleepIntervals(from: intervals)
        let sessions = sleepSessions(from: mergedIntervals)
        let recentStart = now.addingTimeInterval(-36 * 60 * 60)
        let recentSessions = sessions.filter { $0.endDate >= recentStart }
        let candidateSessions = recentSessions.isEmpty ? sessions : recentSessions

        if let substantial = candidateSessions
            .filter({ $0.duration >= 2 * 60 * 60 })
            .max(by: { $0.duration < $1.duration }) {
            return substantial.duration
        }

        return candidateSessions.max(by: { $0.endDate < $1.endDate })?.duration ?? 0
    }

    private nonisolated static func mergedSleepIntervals(from intervals: [SleepInterval]) -> [SleepInterval] {
        let sortedIntervals = intervals.sorted { $0.startDate < $1.startDate }
        var mergedIntervals: [SleepInterval] = []

        for interval in sortedIntervals {
            guard var last = mergedIntervals.popLast() else {
                mergedIntervals.append(interval)
                continue
            }

            if interval.startDate <= last.endDate {
                last.endDate = max(last.endDate, interval.endDate)
                mergedIntervals.append(last)
            } else {
                mergedIntervals.append(last)
                mergedIntervals.append(interval)
            }
        }

        return mergedIntervals
    }

    private nonisolated static func sleepSessions(from intervals: [SleepInterval]) -> [SleepInterval] {
        let sessionGap: TimeInterval = 3 * 60 * 60
        var sessions: [SleepInterval] = []

        for interval in intervals {
            guard var currentSession = sessions.popLast() else {
                sessions.append(interval)
                continue
            }

            if interval.startDate.timeIntervalSince(currentSession.endDate) <= sessionGap {
                currentSession.endDate = max(currentSession.endDate, interval.endDate)
                sessions.append(currentSession)
            } else {
                sessions.append(currentSession)
                sessions.append(interval)
            }
        }

        return sessions
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

private enum HealthKitWorkoutSaveError: LocalizedError {
    case saveDidNotComplete

    var errorDescription: String? {
        "Apple Health did not confirm the workout save."
    }
}
