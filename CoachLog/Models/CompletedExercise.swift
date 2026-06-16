import Foundation
import SwiftData

@Model
final class CompletedExercise {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var muscleGroupRaw: String

    @Relationship(deleteRule: .cascade)
    var sets: [WorkoutSet]

    init(
        id: UUID = UUID(),
        exerciseName: String,
        muscleGroup: MuscleGroup,
        sets: [WorkoutSet] = []
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.muscleGroupRaw = muscleGroup.rawValue
        self.sets = sets
    }

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .core }
        set { muscleGroupRaw = newValue.rawValue }
    }
}

