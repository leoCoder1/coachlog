import Foundation
import BackgroundTasks
import SwiftData

enum HealthKitRecoverySync {
    static let autoImportEnabledKey = "healthKitRecoveryAutoImportEnabled"
    static let lastAutoImportDateKey = "healthKitRecoveryLastAutoImportDate"
    static let backgroundRefreshTaskIdentifier = "com.machvect.CoachLog.healthkit-refresh"

    static func shouldAutoImport(lastImportDate: Date?, now: Date = .now) -> Bool {
        guard let lastImportDate else { return true }
        return !Calendar.current.isDate(lastImportDate, inSameDayAs: now)
    }

    @MainActor
    @discardableResult
    static func performAutoImportIfNeeded(
        in modelContainer: ModelContainer,
        force: Bool = false,
        now: Date = .now,
        defaults: UserDefaults = .standard
    ) async -> RecoveryImportResult? {
        guard defaults.bool(forKey: autoImportEnabledKey) else {
            return nil
        }

        let lastImportTime = defaults.double(forKey: lastAutoImportDateKey)
        let lastImportDate = lastImportTime > 0 ? Date(timeIntervalSince1970: lastImportTime) : nil
        guard force || shouldAutoImport(lastImportDate: lastImportDate, now: now) else {
            return nil
        }

        let healthKitManager = HealthKitManager()
        guard healthKitManager.isHealthDataAvailable else {
            return nil
        }

        let result = await healthKitManager.importRecoverySnapshot()
        guard let snapshot = result.snapshot else {
            return result
        }

        let modelContext = ModelContext(modelContainer)
        save(snapshot, in: modelContext)
        defaults.set(now.timeIntervalSince1970, forKey: lastAutoImportDateKey)

        return result
    }

    static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshTaskIdentifier)
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 20, to: .now)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // iOS may deny background refresh based on device state or user settings.
        }
    }

    @MainActor
    static func save(_ snapshot: RecoverySnapshot, in modelContext: ModelContext) {
        if let existingSnapshot = existingHealthKitSnapshot(for: snapshot.date, in: modelContext) {
            update(existingSnapshot, from: snapshot)
        } else {
            modelContext.insert(snapshot)
        }

        try? modelContext.save()
    }

    @MainActor
    private static func existingHealthKitSnapshot(
        for date: Date,
        in modelContext: ModelContext
    ) -> RecoverySnapshot? {
        let snapshots = (try? modelContext.fetch(FetchDescriptor<RecoverySnapshot>())) ?? []
        return snapshots.first { snapshot in
            Calendar.current.isDate(snapshot.date, inSameDayAs: date) && snapshot.isHealthKitBacked
        }
    }

    private static func update(_ existingSnapshot: RecoverySnapshot, from snapshot: RecoverySnapshot) {
        existingSnapshot.date = snapshot.date
        existingSnapshot.sleepHours = snapshot.sleepHours
        existingSnapshot.restingHeartRate = snapshot.restingHeartRate
        existingSnapshot.hrv = snapshot.hrv
        existingSnapshot.readinessScore = snapshot.readinessScore
        existingSnapshot.source = snapshot.source
        existingSnapshot.importedMetricKeys = snapshot.importedMetricKeys
        existingSnapshot.importNote = snapshot.importNote
    }
}
