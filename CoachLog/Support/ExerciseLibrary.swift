import Foundation

struct ExerciseDefinition: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var primaryMuscleGroup: MuscleGroup
    var secondaryMuscleGroups: [MuscleGroup]
    var equipment: Equipment
    var isKneeFriendly: Bool
    var isShoulderFriendly: Bool
}

enum ExerciseLibrary {
    static let definitions: [ExerciseDefinition] = [
        ExerciseDefinition(
            name: "Push-ups",
            primaryMuscleGroup: .chest,
            secondaryMuscleGroups: [.triceps, .shoulders],
            equipment: .bodyweight,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Dumbbell Bench Press",
            primaryMuscleGroup: .chest,
            secondaryMuscleGroups: [.triceps, .shoulders],
            equipment: .dumbbell,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Incline Dumbbell Press",
            primaryMuscleGroup: .chest,
            secondaryMuscleGroups: [.triceps, .shoulders],
            equipment: .dumbbell,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Triceps Pressdown",
            primaryMuscleGroup: .triceps,
            secondaryMuscleGroups: [],
            equipment: .cable,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Lat Pulldown",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.biceps],
            equipment: .machine,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Seated Row",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.biceps],
            equipment: .machine,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Dumbbell Row",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.biceps],
            equipment: .dumbbell,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Biceps Curl",
            primaryMuscleGroup: .biceps,
            secondaryMuscleGroups: [],
            equipment: .dumbbell,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Goblet Squat",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.core],
            equipment: .dumbbell,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Romanian Deadlift",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.back],
            equipment: .dumbbell,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Glute Bridge",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.core],
            equipment: .bodyweight,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Calf Raise",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [],
            equipment: .bodyweight,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Step-up",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.core],
            equipment: .bodyweight,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Plank",
            primaryMuscleGroup: .core,
            secondaryMuscleGroups: [.shoulders],
            equipment: .bodyweight,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Dead Bug",
            primaryMuscleGroup: .core,
            secondaryMuscleGroups: [],
            equipment: .bodyweight,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Side Plank",
            primaryMuscleGroup: .core,
            secondaryMuscleGroups: [.shoulders],
            equipment: .bodyweight,
            isKneeFriendly: true,
            isShoulderFriendly: true
        )
    ]
}

