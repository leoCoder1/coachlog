import Foundation
import Observation

struct SetInput: Hashable {
    var weight: Double
    var reps: Int
    var rir: Int
}

struct LoggedSetDraft: Identifiable, Hashable {
    var id = UUID()
    var weight: Double
    var reps: Int
    var rir: Int
    var timestamp: Date = .now
}

struct ExerciseSubstitution: Identifiable, Hashable {
    var exercise: PlannedExercise
    var reason: String

    var id: UUID { exercise.id }
}

@MainActor
@Observable
final class WorkoutSessionViewModel {
    let activeWorkoutID: UUID
    var plan: WorkoutPlan
    let startedAt: Date
    var inputs: [UUID: SetInput]
    var loggedSets: [UUID: [LoggedSetDraft]]
    var loadSuggestions: [UUID: LoadSuggestion]

    @ObservationIgnored private let progressionEngine: ProgressionEngine
    @ObservationIgnored private let guidance: TodayCoachGuidance?
    @ObservationIgnored private var didPrepareFromHistory = false

    init(
        plan: WorkoutPlan,
        guidance: TodayCoachGuidance? = nil,
        startedAt: Date = .now,
        progressionEngine: ProgressionEngine = ProgressionEngine()
    ) {
        self.activeWorkoutID = UUID()
        self.plan = plan
        self.startedAt = startedAt
        self.inputs = Dictionary(uniqueKeysWithValues: plan.exercises.map { exercise in
            (exercise.id, Self.defaultInput(for: exercise))
        })
        self.loggedSets = Dictionary(uniqueKeysWithValues: plan.exercises.map { ($0.id, []) })
        self.loadSuggestions = [:]
        self.progressionEngine = progressionEngine
        self.guidance = guidance
    }

    var hasLoggedSets: Bool {
        loggedSets.values.contains { !$0.isEmpty }
    }

    var elapsedTimeText: String {
        let elapsed = max(0, Date().timeIntervalSince(startedAt))
        let minutes = Int(elapsed / 60)
        return "\(minutes) min"
    }

    var weightOptions: [Double] {
        stride(from: 0.0, through: 400.0, by: 2.5).map { $0 }
    }

    var repOptions: [Int] {
        Array(1...40)
    }

    func prepareFromHistory(
        sessions: [WorkoutSession],
        context: WorkoutContext
    ) {
        guard !didPrepareFromHistory else { return }
        didPrepareFromHistory = true

        for exercise in plan.exercises {
            prepareExerciseFromHistory(exercise, sessions: sessions, context: context)
        }
    }

    func input(for exerciseID: UUID) -> SetInput {
        inputs[exerciseID] ?? SetInput(weight: 0, reps: 10, rir: 2)
    }

    func sets(for exerciseID: UUID) -> [LoggedSetDraft] {
        loggedSets[exerciseID] ?? []
    }

    func loadSuggestion(for exerciseID: UUID) -> LoadSuggestion? {
        loadSuggestions[exerciseID]
    }

    func useSuggestedWeight(for exerciseID: UUID) {
        guard let suggestion = loadSuggestions[exerciseID] else { return }
        updateWeight(nearestWeightOption(to: suggestion.suggestedWeight), for: exerciseID)
    }

    func updateWeight(_ weight: Double, for exerciseID: UUID) {
        var input = input(for: exerciseID)
        input.weight = nearestWeightOption(to: max(0, weight))
        inputs[exerciseID] = input
    }

    func updateReps(_ reps: Int, for exerciseID: UUID) {
        var input = input(for: exerciseID)
        input.reps = max(1, reps)
        inputs[exerciseID] = input
    }

    func updateRIR(_ rir: Int, for exerciseID: UUID) {
        var input = input(for: exerciseID)
        input.rir = max(0, min(3, rir))
        inputs[exerciseID] = input
    }

    func addSet(for exerciseID: UUID) {
        let input = input(for: exerciseID)
        let draft = LoggedSetDraft(
            weight: input.weight,
            reps: input.reps,
            rir: input.rir
        )
        loggedSets[exerciseID, default: []].append(draft)
    }

    func apply(_ command: WatchLogSetCommand) -> Bool {
        guard command.sessionID == activeWorkoutID,
              plan.exercises.contains(where: { $0.id == command.exerciseID }) else {
            return false
        }

        inputs[command.exerciseID] = SetInput(
            weight: nearestWeightOption(to: command.weight),
            reps: max(1, command.reps),
            rir: max(0, min(3, command.rir))
        )
        loggedSets[command.exerciseID, default: []].append(
            LoggedSetDraft(
                id: command.commandID,
                weight: nearestWeightOption(to: command.weight),
                reps: max(1, command.reps),
                rir: max(0, min(3, command.rir)),
                timestamp: command.timestamp
            )
        )
        return true
    }

    func apply(_ command: WatchUndoSetCommand) -> Bool {
        guard command.sessionID == activeWorkoutID,
              var exerciseSets = loggedSets[command.exerciseID],
              !exerciseSets.isEmpty else {
            return false
        }

        exerciseSets.removeLast()
        loggedSets[command.exerciseID] = exerciseSets

        if let previousSet = exerciseSets.last {
            inputs[command.exerciseID] = SetInput(
                weight: previousSet.weight,
                reps: previousSet.reps,
                rir: previousSet.rir
            )
        }

        return true
    }

    func substitutionOptions(
        for exercise: PlannedExercise,
        pain: PainFlag
    ) -> [ExerciseSubstitution] {
        let plannedNames = Set(plan.exercises.map(\.name))

        return ExerciseLibrary.definitions
            .filter { definition in
                definition.primaryMuscleGroup == exercise.muscleGroup
                && definition.kind == exercise.kind
                && definition.name != exercise.name
                && !plannedNames.contains(definition.name)
                && isAllowed(definition, for: pain)
            }
            .sorted { lhs, rhs in
                substitutionScore(lhs, replacing: exercise) < substitutionScore(rhs, replacing: exercise)
            }
            .prefix(6)
            .map { definition in
                let replacement = plannedExercise(from: definition, replacing: exercise)
                return ExerciseSubstitution(
                    exercise: replacement,
                    reason: substitutionReason(for: definition, replacing: exercise)
                )
            }
    }

    func replaceExercise(
        _ exercise: PlannedExercise,
        with replacement: PlannedExercise,
        sessions: [WorkoutSession],
        context: WorkoutContext
    ) {
        guard let index = plan.exercises.firstIndex(where: { $0.id == exercise.id }) else {
            return
        }

        let previousInput = input(for: exercise.id)
        plan.exercises[index] = replacement
        inputs.removeValue(forKey: exercise.id)
        loggedSets.removeValue(forKey: exercise.id)
        loadSuggestions.removeValue(forKey: exercise.id)

        inputs[replacement.id] = SetInput(
            weight: 0,
            reps: replacement.targetRepsLower,
            rir: previousInput.rir
        )
        loggedSets[replacement.id] = []
        prepareExerciseFromHistory(replacement, sessions: sessions, context: context)
    }

    func addExercise(
        _ exercise: Exercise,
        sessions: [WorkoutSession],
        context: WorkoutContext
    ) {
        let targetSets = exercise.kind == .stretch ? 2 : 3
        let targetLower = exercise.kind == .stretch ? 20 : 8
        let targetUpper = exercise.kind == .stretch ? 30 : 12
        let planned = PlannedExercise(
            name: exercise.name,
            muscleGroup: exercise.primaryMuscleGroup,
            secondaryMuscleGroups: exercise.secondaryMuscleGroups,
            primaryDetailedMuscle: exercise.primaryDetailedMuscle,
            secondaryDetailedMuscle: exercise.secondaryDetailedMuscle,
            detailedMuscles: exercise.detailedMuscles,
            equipment: exercise.equipment,
            station: exercise.station,
            kind: exercise.kind,
            targetSets: targetSets,
            targetRepsLower: targetLower,
            targetRepsUpper: targetUpper,
            coachingNote: "Added from your exercise library."
        )

        plan.exercises.append(planned)
        inputs[planned.id] = Self.defaultInput(for: planned)
        loggedSets[planned.id] = []
        prepareExerciseFromHistory(planned, sessions: sessions, context: context)
    }

    private static func defaultInput(for exercise: PlannedExercise) -> SetInput {
        SetInput(
            weight: 0,
            reps: exercise.targetRepsLower,
            rir: exercise.kind == .stretch ? 3 : 2
        )
    }

    private func nearestWeightOption(to weight: Double) -> Double {
        let clamped = min(400, max(0, weight))
        return (clamped / 2.5).rounded() * 2.5
    }

    private func prepareExerciseFromHistory(
        _ exercise: PlannedExercise,
        sessions: [WorkoutSession],
        context: WorkoutContext
    ) {
        let lastWeight = progressionEngine.lastWeight(for: exercise.name, in: sessions)

        if let lastWeight {
            var input = input(for: exercise.id)
            input.weight = nearestWeightOption(to: lastWeight)
            inputs[exercise.id] = input
        }

        var localSuggestion: LoadSuggestion?
        if let suggestion = progressionEngine.loadSuggestion(
            for: exercise,
            recentSessions: sessions,
            pain: context.painFlag
        ) {
            loadSuggestions[exercise.id] = suggestion
            localSuggestion = suggestion
        }

        applyAIGuidance(
            to: exercise,
            lastWeight: lastWeight,
            localSuggestion: localSuggestion
        )
    }

    private func applyAIGuidance(
        to exercise: PlannedExercise,
        lastWeight: Double?,
        localSuggestion: LoadSuggestion?
    ) {
        guard let advice = guidance?.advice(for: exercise.name) else { return }

        switch advice.action {
        case .increase:
            guard let localSuggestion,
                  localSuggestion.suggestedWeight > localSuggestion.lastWeight else {
                return
            }

            let suggestedWeight = min(
                advice.suggestedWeightPounds ?? localSuggestion.suggestedWeight,
                localSuggestion.suggestedWeight
            )
            setSuggestedWeight(
                suggestedWeight,
                lastWeight: localSuggestion.lastWeight,
                exercise: exercise,
                message: advice.reason
            )
        case .hold:
            guard let lastWeight else { return }
            setSuggestedWeight(
                lastWeight,
                lastWeight: lastWeight,
                exercise: exercise,
                message: advice.reason
            )
        case .reduce:
            guard let lastWeight else { return }
            let suggestedWeight = min(advice.suggestedWeightPounds ?? lastWeight * 0.9, lastWeight)
            setSuggestedWeight(
                suggestedWeight,
                lastWeight: lastWeight,
                exercise: exercise,
                message: advice.reason
            )
        case .substitute:
            return
        }
    }

    private func setSuggestedWeight(
        _ suggestedWeight: Double,
        lastWeight: Double,
        exercise: PlannedExercise,
        message: String
    ) {
        let roundedSuggestion = nearestWeightOption(to: suggestedWeight)
        var input = input(for: exercise.id)
        input.weight = roundedSuggestion
        inputs[exercise.id] = input
        loadSuggestions[exercise.id] = LoadSuggestion(
            exerciseName: exercise.name,
            lastWeight: lastWeight,
            suggestedWeight: roundedSuggestion,
            message: message
        )
    }

    private func plannedExercise(
        from definition: ExerciseDefinition,
        replacing exercise: PlannedExercise
    ) -> PlannedExercise {
        PlannedExercise(
            name: definition.name,
            muscleGroup: definition.primaryMuscleGroup,
            secondaryMuscleGroups: definition.secondaryMuscleGroups,
            primaryDetailedMuscle: definition.primaryDetailedMuscle,
            secondaryDetailedMuscle: definition.secondaryDetailedMuscle,
            detailedMuscles: definition.detailedMuscles,
            equipment: definition.equipment,
            station: definition.station,
            kind: definition.kind,
            targetSets: exercise.targetSets,
            targetRepsLower: exercise.targetRepsLower,
            targetRepsUpper: exercise.targetRepsUpper,
            coachingNote: "Swap for \(exercise.name). Same \(definition.primaryMuscleGroup.rawValue.lowercased()) focus using \(definition.station.rawValue.lowercased())."
        )
    }

    private func substitutionScore(
        _ definition: ExerciseDefinition,
        replacing exercise: PlannedExercise
    ) -> Int {
        let stationPenalty = definition.station == exercise.station ? 40 : 0
        let equipmentScore: Int

        switch definition.equipment {
        case .bodyweight:
            equipmentScore = 0
        case .dumbbell:
            equipmentScore = 6
        case .cable:
            equipmentScore = 12
        case .machine:
            equipmentScore = 18
        }

        let overlapBonus = definition.secondaryMuscleGroups
            .filter { exercise.secondaryMuscleGroups.contains($0) }
            .count * 3

        return stationPenalty + equipmentScore - overlapBonus
    }

    private func substitutionReason(
        for definition: ExerciseDefinition,
        replacing exercise: PlannedExercise
    ) -> String {
        if definition.station != exercise.station {
            return "\(definition.station.rawValue), same \(definition.primaryMuscleGroup.rawValue.lowercased()) focus"
        }

        return "Same station, different movement pattern"
    }

    private func isAllowed(_ definition: ExerciseDefinition, for pain: PainFlag) -> Bool {
        switch pain {
        case .none:
            true
        case .knee:
            definition.isKneeFriendly
        case .shoulder:
            definition.isShoulderFriendly
        case .back:
            !definition.name.localizedCaseInsensitiveContains("deadlift")
            && !definition.name.localizedCaseInsensitiveContains("row")
        case .other:
            true
        }
    }

    func makeWorkoutSession(context: WorkoutContext) -> WorkoutSession {
        let completed = plan.exercises.compactMap { exercise -> CompletedExercise? in
            let drafts = sets(for: exercise.id)
            guard !drafts.isEmpty else { return nil }

            let workoutSets = drafts.map {
                WorkoutSet(
                    weight: $0.weight,
                    reps: $0.reps,
                    rir: $0.rir,
                    timestamp: $0.timestamp
                )
            }

            return CompletedExercise(
                exerciseName: exercise.name,
                muscleGroup: exercise.muscleGroup,
                sets: workoutSets
            )
        }

        return WorkoutSession(
            duration: max(60, Date().timeIntervalSince(startedAt)),
            energyLevel: context.energyLevel,
            painFlag: context.painFlag,
            availableMinutes: context.availableMinutes,
            goal: context.goal,
            completedExercises: completed
        )
    }

    func activeWorkoutSnapshot(context: WorkoutContext) -> ActiveWorkoutSnapshot {
        ActiveWorkoutSnapshot(
            sessionID: activeWorkoutID,
            workoutTitle: "\(context.goal.displayName) · \(context.availableMinutes.displayName)",
            startedAt: startedAt,
            updatedAt: .now,
            exercises: plan.exercises.map { exercise in
                let input = input(for: exercise.id)
                return ActiveWorkoutExerciseSnapshot(
                    id: exercise.id,
                    name: exercise.name,
                    targetSets: exercise.targetSets,
                    targetRepRange: exercise.targetRepRange,
                    loggedSetCount: sets(for: exercise.id).count,
                    latestWeight: input.weight,
                    latestReps: input.reps,
                    latestRIR: input.rir,
                    showsWeight: showsWeight(for: exercise)
                )
            }
        )
    }

    private func showsWeight(for exercise: PlannedExercise) -> Bool {
        exercise.kind == .strength
        && exercise.equipment != .bodyweight
        && exercise.station != .bodyweight
        && exercise.station != .mat
    }
}
