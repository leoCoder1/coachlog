import Foundation

struct ExerciseDefinition: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var primaryMuscleGroup: MuscleGroup
    var secondaryMuscleGroups: [MuscleGroup]
    var equipment: Equipment
    var station: GymStation
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
            station: .bodyweight,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Dumbbell Bench Press",
            primaryMuscleGroup: .chest,
            secondaryMuscleGroups: [.triceps, .shoulders],
            equipment: .dumbbell,
            station: .adjustableBench,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Incline Dumbbell Press",
            primaryMuscleGroup: .chest,
            secondaryMuscleGroups: [.triceps, .shoulders],
            equipment: .dumbbell,
            station: .adjustableBench,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Machine Chest Press",
            primaryMuscleGroup: .chest,
            secondaryMuscleGroups: [.triceps, .shoulders],
            equipment: .machine,
            station: .chestPress,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Cable Chest Fly",
            primaryMuscleGroup: .chest,
            secondaryMuscleGroups: [.shoulders],
            equipment: .cable,
            station: .cableStack,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Smith Machine Bench Press",
            primaryMuscleGroup: .chest,
            secondaryMuscleGroups: [.triceps, .shoulders],
            equipment: .machine,
            station: .smithMachine,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Triceps Pressdown",
            primaryMuscleGroup: .triceps,
            secondaryMuscleGroups: [],
            equipment: .cable,
            station: .cableStack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Overhead Cable Triceps Extension",
            primaryMuscleGroup: .triceps,
            secondaryMuscleGroups: [],
            equipment: .cable,
            station: .cableStack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Close-Grip Push-ups",
            primaryMuscleGroup: .triceps,
            secondaryMuscleGroups: [.chest, .shoulders],
            equipment: .bodyweight,
            station: .bodyweight,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Lat Pulldown",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.biceps],
            equipment: .machine,
            station: .latPulldown,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Seated Row",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.biceps],
            equipment: .machine,
            station: .seatedRow,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Assisted Pull-up",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.biceps],
            equipment: .machine,
            station: .assistedPullUp,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Cable Row",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.biceps],
            equipment: .cable,
            station: .cableStack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Dumbbell Row",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.biceps],
            equipment: .dumbbell,
            station: .dumbbellRack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Biceps Curl",
            primaryMuscleGroup: .biceps,
            secondaryMuscleGroups: [],
            equipment: .dumbbell,
            station: .dumbbellRack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Cable Curl",
            primaryMuscleGroup: .biceps,
            secondaryMuscleGroups: [],
            equipment: .cable,
            station: .cableStack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Incline Dumbbell Curl",
            primaryMuscleGroup: .biceps,
            secondaryMuscleGroups: [],
            equipment: .dumbbell,
            station: .adjustableBench,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Goblet Squat",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.core],
            equipment: .dumbbell,
            station: .dumbbellRack,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Romanian Deadlift",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.back],
            equipment: .dumbbell,
            station: .dumbbellRack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Leg Press",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [],
            equipment: .machine,
            station: .legPress,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Seated Leg Curl",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [],
            equipment: .machine,
            station: .legCurl,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Dumbbell Reverse Lunge",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.core],
            equipment: .dumbbell,
            station: .dumbbellRack,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Glute Bridge",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.core],
            equipment: .bodyweight,
            station: .mat,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Calf Raise",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [],
            equipment: .bodyweight,
            station: .bodyweight,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Step-up",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.core],
            equipment: .bodyweight,
            station: .bodyweight,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Dumbbell Shoulder Press",
            primaryMuscleGroup: .shoulders,
            secondaryMuscleGroups: [.triceps],
            equipment: .dumbbell,
            station: .adjustableBench,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Dumbbell Lateral Raise",
            primaryMuscleGroup: .shoulders,
            secondaryMuscleGroups: [],
            equipment: .dumbbell,
            station: .dumbbellRack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Cable Lateral Raise",
            primaryMuscleGroup: .shoulders,
            secondaryMuscleGroups: [],
            equipment: .cable,
            station: .cableStack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Machine Shoulder Press",
            primaryMuscleGroup: .shoulders,
            secondaryMuscleGroups: [.triceps],
            equipment: .machine,
            station: .chestPress,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Plank",
            primaryMuscleGroup: .core,
            secondaryMuscleGroups: [.shoulders],
            equipment: .bodyweight,
            station: .mat,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Dead Bug",
            primaryMuscleGroup: .core,
            secondaryMuscleGroups: [],
            equipment: .bodyweight,
            station: .mat,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Side Plank",
            primaryMuscleGroup: .core,
            secondaryMuscleGroups: [.shoulders],
            equipment: .bodyweight,
            station: .mat,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Pallof Press",
            primaryMuscleGroup: .core,
            secondaryMuscleGroups: [.shoulders],
            equipment: .cable,
            station: .cableStack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        )
    ]
}
