import Foundation

struct RecoverySnapshotSummary: Hashable {
    var sleepHours: Double
    var restingHeartRate: Double
    var hrv: Double
    var readinessScore: Int

    init(snapshot: RecoverySnapshot) {
        self.sleepHours = snapshot.sleepHours
        self.restingHeartRate = snapshot.restingHeartRate
        self.hrv = snapshot.hrv
        self.readinessScore = snapshot.readinessScore
    }
}

struct WorkoutContext: Hashable {
    var availableMinutes: AvailableMinutes
    var energyLevel: EnergyLevel
    var painFlag: PainFlag
    var goal: FitnessGoal
    var recovery: RecoverySnapshotSummary?

    var shouldReduceVolume: Bool {
        guard let recovery else { return energyLevel == .low }
        return energyLevel == .low || recovery.sleepHours < 6.5 || recovery.readinessScore < 60
    }

    var canUseFullVolume: Bool {
        guard let recovery else { return energyLevel != .low }
        return energyLevel == .high && recovery.sleepHours >= 7 && recovery.readinessScore >= 75
    }
}

struct PlannedExercise: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var muscleGroup: MuscleGroup
    var secondaryMuscleGroups: [MuscleGroup]
    var equipment: Equipment
    var targetSets: Int
    var targetRepsLower: Int
    var targetRepsUpper: Int
    var coachingNote: String

    var targetRepRange: String {
        "\(targetRepsLower)-\(targetRepsUpper)"
    }
}

struct WorkoutPlan: Identifiable, Hashable {
    var id = UUID()
    var generatedAt = Date()
    var exercises: [PlannedExercise]
    var focusMuscleGroups: [MuscleGroup]
    var volumeAdjustmentNote: String
}

struct MuscleFreshnessResult: Identifiable, Hashable {
    var id: MuscleGroup { group }
    var group: MuscleGroup
    var status: FreshnessStatus
    var daysSinceTraining: Int?
    var note: String
}

