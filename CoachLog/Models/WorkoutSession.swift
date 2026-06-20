import Foundation
import SwiftData

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var duration: TimeInterval
    var energyLevelRaw: String
    var painFlagRaw: String
    var availableMinutesRaw: Int
    var goalRaw: String
    var healthKitWorkoutUUID: String?
    var healthKitWorkoutSavedAt: Date?

    @Relationship(deleteRule: .cascade)
    var completedExercises: [CompletedExercise]

    init(
        id: UUID = UUID(),
        date: Date = .now,
        duration: TimeInterval,
        energyLevel: EnergyLevel,
        painFlag: PainFlag,
        availableMinutes: AvailableMinutes,
        goal: FitnessGoal,
        completedExercises: [CompletedExercise] = [],
        healthKitWorkoutUUID: String? = nil,
        healthKitWorkoutSavedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.energyLevelRaw = energyLevel.rawValue
        self.painFlagRaw = painFlag.rawValue
        self.availableMinutesRaw = availableMinutes.rawValue
        self.goalRaw = goal.rawValue
        self.healthKitWorkoutUUID = healthKitWorkoutUUID
        self.healthKitWorkoutSavedAt = healthKitWorkoutSavedAt
        self.completedExercises = completedExercises
    }

    var energyLevel: EnergyLevel {
        get { EnergyLevel(rawValue: energyLevelRaw) ?? .normal }
        set { energyLevelRaw = newValue.rawValue }
    }

    var painFlag: PainFlag {
        get { PainFlag(rawValue: painFlagRaw) ?? .none }
        set { painFlagRaw = newValue.rawValue }
    }

    var availableMinutes: AvailableMinutes {
        get { AvailableMinutes(rawValue: availableMinutesRaw) ?? .forty }
        set { availableMinutesRaw = newValue.rawValue }
    }

    var goal: FitnessGoal {
        get { FitnessGoal(rawValue: goalRaw) ?? .generalFitness }
        set { goalRaw = newValue.rawValue }
    }
}
