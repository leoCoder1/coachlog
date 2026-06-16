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
    var primaryDetailedMuscle: DetailedMuscleGroup
    var secondaryDetailedMuscle: DetailedMuscleGroup?
    var detailedMuscles: [DetailedMuscleGroup]
    var equipment: Equipment
    var station: GymStation
    var targetSets: Int
    var targetRepsLower: Int
    var targetRepsUpper: Int
    var coachingNote: String

    var targetRepRange: String {
        "\(targetRepsLower)-\(targetRepsUpper)"
    }

    var affectedMuscleGroups: [MuscleGroup] {
        var groups = [muscleGroup]

        for group in secondaryMuscleGroups where !groups.contains(group) {
            groups.append(group)
        }

        return groups
    }

    var muscleImpactText: String {
        affectedMuscleGroups.map(\.rawValue).joined(separator: ", ")
    }

    var detailedMuscleImpactText: String {
        detailedMuscles.map(\.rawValue).joined(separator: ", ")
    }

    var specificMuscleSummary: String {
        if let secondaryDetailedMuscle {
            return "\(primaryDetailedMuscle.rawValue) + \(secondaryDetailedMuscle.rawValue)"
        }

        return primaryDetailedMuscle.rawValue
    }

    var illustrationAssetName: String {
        "exercise-\(name.slugifiedAssetName)"
    }
}

struct WorkoutPlan: Identifiable, Hashable {
    var id = UUID()
    var generatedAt = Date()
    var exercises: [PlannedExercise]
    var focusMuscleGroups: [MuscleGroup]
    var volumeAdjustmentNote: String
    var weeklyRotationNote: String?
}

struct MuscleFreshnessResult: Identifiable, Hashable {
    var id: MuscleGroup { group }
    var group: MuscleGroup
    var status: FreshnessStatus
    var daysSinceTraining: Int?
    var note: String
}

private extension String {
    var slugifiedAssetName: String {
        lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
