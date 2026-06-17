import Foundation

struct ExerciseDefinition: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var primaryMuscleGroup: MuscleGroup
    var secondaryMuscleGroups: [MuscleGroup]
    var primaryDetailedMuscle: DetailedMuscleGroup
    var secondaryDetailedMuscle: DetailedMuscleGroup?
    var detailedMuscles: [DetailedMuscleGroup]
    var equipment: Equipment
    var station: GymStation
    var kind: ExerciseKind
    var isKneeFriendly: Bool
    var isShoulderFriendly: Bool

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscleGroup: MuscleGroup,
        secondaryMuscleGroups: [MuscleGroup],
        primaryDetailedMuscle: DetailedMuscleGroup? = nil,
        secondaryDetailedMuscle: DetailedMuscleGroup? = nil,
        detailedMuscles: [DetailedMuscleGroup]? = nil,
        equipment: Equipment,
        station: GymStation,
        kind: ExerciseKind = .strength,
        isKneeFriendly: Bool,
        isShoulderFriendly: Bool
    ) {
        self.id = id
        self.name = name
        self.primaryMuscleGroup = primaryMuscleGroup
        self.secondaryMuscleGroups = secondaryMuscleGroups
        let defaultDetailedMuscles = detailedMuscles ?? Self.defaultDetailedMuscles(
            for: name,
            primary: primaryMuscleGroup,
            secondary: secondaryMuscleGroups
        )
        let resolvedPrimary = primaryDetailedMuscle ?? defaultDetailedMuscles.first ?? DetailedMuscleGroup.defaults(for: primaryMuscleGroup)[0]
        let resolvedSecondary = secondaryDetailedMuscle ?? defaultDetailedMuscles.first { $0 != resolvedPrimary }

        self.primaryDetailedMuscle = resolvedPrimary
        self.secondaryDetailedMuscle = resolvedSecondary
        self.detailedMuscles = Self.orderedDetailedMuscles(
            primary: resolvedPrimary,
            secondary: resolvedSecondary,
            all: defaultDetailedMuscles
        )
        self.equipment = equipment
        self.station = station
        self.kind = kind
        self.isKneeFriendly = isKneeFriendly
        self.isShoulderFriendly = isShoulderFriendly
    }

    private static func orderedDetailedMuscles(
        primary: DetailedMuscleGroup,
        secondary: DetailedMuscleGroup?,
        all muscles: [DetailedMuscleGroup]
    ) -> [DetailedMuscleGroup] {
        var ordered = [primary]

        if let secondary, secondary != primary {
            ordered.append(secondary)
        }

        for muscle in muscles where !ordered.contains(muscle) {
            ordered.append(muscle)
        }

        return ordered
    }

    private static func defaultDetailedMuscles(
        for exerciseName: String,
        primary: MuscleGroup,
        secondary: [MuscleGroup]
    ) -> [DetailedMuscleGroup] {
        switch exerciseName {
        case "Push-ups":
            [.midChest, .lowerChest, .triceps, .frontDeltoids, .rectusAbdominis]
        case "Dumbbell Bench Press", "Machine Chest Press", "Smith Machine Bench Press":
            [.midChest, .lowerChest, .triceps, .frontDeltoids]
        case "Incline Dumbbell Press":
            [.upperChest, .frontDeltoids, .triceps]
        case "Cable Chest Fly":
            [.midChest, .lowerChest, .frontDeltoids]
        case "Triceps Pressdown":
            [.triceps, .forearmFlexors]
        case "Overhead Cable Triceps Extension":
            [.triceps, .forearmFlexors, .rectusAbdominis]
        case "Close-Grip Push-ups":
            [.triceps, .midChest, .frontDeltoids, .rectusAbdominis]
        case "Lat Pulldown", "Assisted Pull-up":
            [.latissimusDorsi, .upperBack, .biceps, .brachioradialis, .forearmFlexors]
        case "Seated Row", "Cable Row", "Dumbbell Row":
            [.upperBack, .latissimusDorsi, .rearDeltoids, .biceps, .brachioradialis]
        case "Biceps Curl", "Cable Curl", "Incline Dumbbell Curl":
            [.biceps, .brachioradialis, .forearmFlexors]
        case "Goblet Squat", "Leg Press":
            [.quadriceps, .gluteusMaximus, .adductors, .rectusAbdominis]
        case "Romanian Deadlift":
            [.hamstrings, .gluteusMaximus, .lowerBack, .forearmFlexors]
        case "Seated Leg Curl":
            [.hamstrings, .gastrocnemius]
        case "Dumbbell Reverse Lunge", "Step-up":
            [.quadriceps, .gluteusMaximus, .gluteusMedius, .hamstrings, .adductors, .obliques]
        case "Glute Bridge", "Dumbbell Hip Thrust":
            [.gluteusMaximus, .gluteusMedius, .hamstrings, .rectusAbdominis]
        case "Cable Glute Kickback":
            [.gluteusMaximus, .gluteusMedius, .hamstrings]
        case "Side-Lying Hip Abduction":
            [.gluteusMedius, .gluteusMinimus, .obliques]
        case "Calf Raise":
            [.gastrocnemius, .soleus]
        case "Dumbbell Shoulder Press", "Machine Shoulder Press":
            [.frontDeltoids, .sideDeltoids, .triceps]
        case "Dumbbell Lateral Raise", "Cable Lateral Raise":
            [.sideDeltoids, .frontDeltoids]
        case "Plank":
            [.rectusAbdominis, .obliques, .frontDeltoids]
        case "Dead Bug":
            [.rectusAbdominis, .obliques]
        case "Side Plank":
            [.obliques, .rectusAbdominis, .sideDeltoids]
        case "Pallof Press":
            [.obliques, .rectusAbdominis, .sideDeltoids]
        case "Child's Pose", "Lat Prayer Stretch":
            [.latissimusDorsi, .lowerBack, .rectusAbdominis]
        case "Thread the Needle":
            [.upperBack, .rearDeltoids, .latissimusDorsi, .obliques]
        case "Doorway Chest Stretch":
            [.midChest, .upperChest, .frontDeltoids]
        case "Cross-Body Shoulder Stretch":
            [.rearDeltoids, .sideDeltoids, .upperBack]
        case "Wrist Flexor Stretch":
            [.forearmFlexors, .brachioradialis]
        case "Hip Flexor Lunge Stretch":
            [.quadriceps, .gluteusMaximus, .rectusAbdominis]
        case "Seated Hamstring Stretch":
            [.hamstrings, .gastrocnemius, .lowerBack]
        case "Figure Four Glute Stretch":
            [.gluteusMaximus, .gluteusMedius, .hamstrings]
        case "Standing Quad Stretch":
            [.quadriceps, .rectusAbdominis]
        case "Calf Wall Stretch":
            [.gastrocnemius, .soleus, .hamstrings]
        case "Cobra Press-Up":
            [.rectusAbdominis, .upperChest, .frontDeltoids]
        case "Cat-Cow":
            [.lowerBack, .rectusAbdominis, .upperBack]
        case "World's Greatest Stretch":
            [.gluteusMaximus, .quadriceps, .obliques, .hamstrings, .upperBack]
        default:
            DetailedMuscleGroup.defaults(primary: primary, secondary: secondary)
        }
    }
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
            secondaryMuscleGroups: [.glutes, .core],
            equipment: .dumbbell,
            station: .dumbbellRack,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Romanian Deadlift",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.glutes, .back],
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
            secondaryMuscleGroups: [.glutes, .core],
            equipment: .dumbbell,
            station: .dumbbellRack,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Glute Bridge",
            primaryMuscleGroup: .glutes,
            secondaryMuscleGroups: [.legs, .core],
            equipment: .bodyweight,
            station: .mat,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Dumbbell Hip Thrust",
            primaryMuscleGroup: .glutes,
            secondaryMuscleGroups: [.legs, .core],
            equipment: .dumbbell,
            station: .adjustableBench,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Cable Glute Kickback",
            primaryMuscleGroup: .glutes,
            secondaryMuscleGroups: [.legs],
            equipment: .cable,
            station: .cableStack,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Side-Lying Hip Abduction",
            primaryMuscleGroup: .glutes,
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
            secondaryMuscleGroups: [.glutes, .core],
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
        ),
        ExerciseDefinition(
            name: "Child's Pose",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.core],
            equipment: .bodyweight,
            station: .mat,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Lat Prayer Stretch",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.shoulders],
            equipment: .bodyweight,
            station: .mat,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Thread the Needle",
            primaryMuscleGroup: .back,
            secondaryMuscleGroups: [.shoulders, .core],
            equipment: .bodyweight,
            station: .mat,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Doorway Chest Stretch",
            primaryMuscleGroup: .chest,
            secondaryMuscleGroups: [.shoulders],
            equipment: .bodyweight,
            station: .bodyweight,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Cross-Body Shoulder Stretch",
            primaryMuscleGroup: .shoulders,
            secondaryMuscleGroups: [.back],
            equipment: .bodyweight,
            station: .bodyweight,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Wrist Flexor Stretch",
            primaryMuscleGroup: .biceps,
            secondaryMuscleGroups: [],
            equipment: .bodyweight,
            station: .bodyweight,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Hip Flexor Lunge Stretch",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.core],
            equipment: .bodyweight,
            station: .mat,
            kind: .stretch,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Seated Hamstring Stretch",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.back],
            equipment: .bodyweight,
            station: .mat,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Figure Four Glute Stretch",
            primaryMuscleGroup: .glutes,
            secondaryMuscleGroups: [.legs],
            equipment: .bodyweight,
            station: .mat,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Standing Quad Stretch",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.core],
            equipment: .bodyweight,
            station: .bodyweight,
            kind: .stretch,
            isKneeFriendly: false,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Calf Wall Stretch",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [],
            equipment: .bodyweight,
            station: .bodyweight,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "Cobra Press-Up",
            primaryMuscleGroup: .core,
            secondaryMuscleGroups: [.chest, .shoulders],
            equipment: .bodyweight,
            station: .mat,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: false
        ),
        ExerciseDefinition(
            name: "Cat-Cow",
            primaryMuscleGroup: .core,
            secondaryMuscleGroups: [.back],
            equipment: .bodyweight,
            station: .mat,
            kind: .stretch,
            isKneeFriendly: true,
            isShoulderFriendly: true
        ),
        ExerciseDefinition(
            name: "World's Greatest Stretch",
            primaryMuscleGroup: .legs,
            secondaryMuscleGroups: [.glutes, .core, .back],
            equipment: .bodyweight,
            station: .mat,
            kind: .stretch,
            isKneeFriendly: false,
            isShoulderFriendly: true
        )
    ]
}
