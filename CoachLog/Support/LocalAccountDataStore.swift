import Foundation
import SwiftData

enum LocalAccountDataStore {
    @MainActor
    static func deleteAllUserData(in modelContext: ModelContext) throws {
        try delete(WorkoutSet.self, in: modelContext)
        try delete(CompletedExercise.self, in: modelContext)
        try delete(WorkoutSession.self, in: modelContext)
        try delete(WorkoutTemplateExercise.self, in: modelContext)
        try delete(WorkoutTemplate.self, in: modelContext)
        try delete(BodyMeasurement.self, in: modelContext)
        try delete(RecoverySnapshot.self, in: modelContext)
        try delete(StrengthBaselineTest.self, in: modelContext)
        try delete(Exercise.self, in: modelContext)

        try modelContext.save()
    }

    @MainActor
    static func clearAccountScopedPreferences(defaults: UserDefaults = .standard) {
        CoachAuthSession.signOut(defaults: defaults)
        defaults.removeObject(forKey: HealthKitRecoverySync.autoImportEnabledKey)
        defaults.removeObject(forKey: HealthKitRecoverySync.lastAutoImportDateKey)
        defaults.removeObject(forKey: HealthKitWorkoutSync.workoutWritingEnabledKey)
        defaults.removeObject(forKey: UnitPreferenceKeys.weightUnit)
        defaults.removeObject(forKey: UnitPreferenceKeys.lengthUnit)
    }

    @MainActor
    private static func delete<T: PersistentModel>(_ modelType: T.Type, in modelContext: ModelContext) throws {
        let models = try modelContext.fetch(FetchDescriptor<T>())
        for model in models {
            modelContext.delete(model)
        }
    }
}
