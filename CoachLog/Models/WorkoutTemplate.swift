import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var goalRaw: String

    @Relationship(deleteRule: .cascade)
    var templateExercises: [WorkoutTemplateExercise]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        goal: FitnessGoal = .generalFitness,
        templateExercises: [WorkoutTemplateExercise] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.goalRaw = goal.rawValue
        self.templateExercises = templateExercises
    }

    var goal: FitnessGoal {
        get { FitnessGoal(rawValue: goalRaw) ?? .generalFitness }
        set { goalRaw = newValue.rawValue }
    }

    var orderedExercises: [WorkoutTemplateExercise] {
        templateExercises.sorted { lhs, rhs in
            if lhs.orderIndex == rhs.orderIndex {
                return lhs.exerciseName < rhs.exerciseName
            }

            return lhs.orderIndex < rhs.orderIndex
        }
    }

    var exerciseCountText: String {
        "\(templateExercises.count) \(templateExercises.count == 1 ? "movement" : "movements")"
    }

    var estimatedMinutes: Int {
        let minutes = orderedExercises.reduce(0) { total, exercise in
            let minutesPerSet = exercise.kind == .stretch ? 1 : 3
            return total + max(1, exercise.targetSets) * minutesPerSet
        }

        return max(10, minutes)
    }

    var availableMinutes: AvailableMinutes {
        if estimatedMinutes <= AvailableMinutes.twenty.rawValue {
            return .twenty
        }

        if estimatedMinutes <= AvailableMinutes.forty.rawValue {
            return .forty
        }

        return .sixty
    }

    func makeWorkoutPlan() -> WorkoutPlan {
        let plannedExercises = orderedExercises.map { $0.makePlannedExercise() }
        let focusGroups = plannedExercises.reduce(into: [MuscleGroup]()) { groups, exercise in
            for group in exercise.affectedMuscleGroups where !groups.contains(group) {
                groups.append(group)
            }
        }

        return WorkoutPlan(
            exercises: plannedExercises,
            focusMuscleGroups: focusGroups,
            volumeAdjustmentNote: "Saved workout",
            weeklyRotationNote: "You chose this workout from your saved sets."
        )
    }
}

@Model
final class WorkoutTemplateExercise {
    @Attribute(.unique) var id: UUID
    var sourceExerciseID: UUID?
    var orderIndex: Int
    var exerciseName: String
    var primaryMuscleGroupRaw: String
    var secondaryMuscleGroupsStorage: String
    var equipmentRaw: String
    var stationRaw: String
    var primaryDetailedMuscleRaw: String
    var secondaryDetailedMuscleRaw: String?
    var kindRaw: String
    var targetSets: Int
    var targetRepsLower: Int
    var targetRepsUpper: Int
    var coachingNote: String

    init(
        id: UUID = UUID(),
        sourceExerciseID: UUID? = nil,
        orderIndex: Int,
        exerciseName: String,
        primaryMuscleGroup: MuscleGroup,
        secondaryMuscleGroups: [MuscleGroup],
        equipment: Equipment,
        station: GymStation,
        primaryDetailedMuscle: DetailedMuscleGroup,
        secondaryDetailedMuscle: DetailedMuscleGroup?,
        kind: ExerciseKind,
        targetSets: Int,
        targetRepsLower: Int,
        targetRepsUpper: Int,
        coachingNote: String = ""
    ) {
        self.id = id
        self.sourceExerciseID = sourceExerciseID
        self.orderIndex = orderIndex
        self.exerciseName = exerciseName
        self.primaryMuscleGroupRaw = primaryMuscleGroup.rawValue
        self.secondaryMuscleGroupsStorage = secondaryMuscleGroups.map(\.rawValue).joined(separator: ",")
        self.equipmentRaw = equipment.rawValue
        self.stationRaw = station.rawValue
        self.primaryDetailedMuscleRaw = primaryDetailedMuscle.rawValue
        self.secondaryDetailedMuscleRaw = secondaryDetailedMuscle?.rawValue
        self.kindRaw = kind.rawValue
        self.targetSets = targetSets
        self.targetRepsLower = targetRepsLower
        self.targetRepsUpper = targetRepsUpper
        self.coachingNote = coachingNote
    }

    convenience init(exercise: Exercise, orderIndex: Int) {
        let targetSets = exercise.kind == .stretch ? 2 : 3
        let targetRepsLower = exercise.kind == .stretch ? 20 : 8
        let targetRepsUpper = exercise.kind == .stretch ? 30 : 12

        self.init(
            sourceExerciseID: exercise.id,
            orderIndex: orderIndex,
            exerciseName: exercise.name,
            primaryMuscleGroup: exercise.primaryMuscleGroup,
            secondaryMuscleGroups: exercise.secondaryMuscleGroups,
            equipment: exercise.equipment,
            station: exercise.station,
            primaryDetailedMuscle: exercise.primaryDetailedMuscle,
            secondaryDetailedMuscle: exercise.secondaryDetailedMuscle,
            kind: exercise.kind,
            targetSets: targetSets,
            targetRepsLower: targetRepsLower,
            targetRepsUpper: targetRepsUpper,
            coachingNote: "From your saved workout."
        )
    }

    var primaryMuscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: primaryMuscleGroupRaw) ?? .core }
        set { primaryMuscleGroupRaw = newValue.rawValue }
    }

    var secondaryMuscleGroups: [MuscleGroup] {
        get {
            secondaryMuscleGroupsStorage
                .split(separator: ",")
                .compactMap { MuscleGroup(rawValue: String($0)) }
        }
        set {
            secondaryMuscleGroupsStorage = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .bodyweight }
        set { equipmentRaw = newValue.rawValue }
    }

    var station: GymStation {
        get { GymStation(rawValue: stationRaw) ?? .bodyweight }
        set { stationRaw = newValue.rawValue }
    }

    var primaryDetailedMuscle: DetailedMuscleGroup {
        get { DetailedMuscleGroup(rawValue: primaryDetailedMuscleRaw) ?? DetailedMuscleGroup.defaults(for: primaryMuscleGroup)[0] }
        set { primaryDetailedMuscleRaw = newValue.rawValue }
    }

    var secondaryDetailedMuscle: DetailedMuscleGroup? {
        get {
            guard let secondaryDetailedMuscleRaw else { return nil }
            return DetailedMuscleGroup(rawValue: secondaryDetailedMuscleRaw)
        }
        set { secondaryDetailedMuscleRaw = newValue?.rawValue }
    }

    var kind: ExerciseKind {
        get { ExerciseKind(rawValue: kindRaw) ?? .strength }
        set { kindRaw = newValue.rawValue }
    }

    var detailedMuscles: [DetailedMuscleGroup] {
        var muscles = [primaryDetailedMuscle]

        if let secondaryDetailedMuscle, secondaryDetailedMuscle != primaryDetailedMuscle {
            muscles.append(secondaryDetailedMuscle)
        }

        return muscles
    }

    func makePlannedExercise() -> PlannedExercise {
        PlannedExercise(
            name: exerciseName,
            muscleGroup: primaryMuscleGroup,
            secondaryMuscleGroups: secondaryMuscleGroups,
            primaryDetailedMuscle: primaryDetailedMuscle,
            secondaryDetailedMuscle: secondaryDetailedMuscle,
            detailedMuscles: detailedMuscles,
            equipment: equipment,
            station: station,
            kind: kind,
            targetSets: targetSets,
            targetRepsLower: targetRepsLower,
            targetRepsUpper: targetRepsUpper,
            coachingNote: coachingNote
        )
    }
}
