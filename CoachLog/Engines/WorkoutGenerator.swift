import Foundation

struct WorkoutGenerationResult {
    var plan: WorkoutPlan
    var freshness: [MuscleGroup: MuscleFreshnessResult]
}

final class WorkoutGenerator {
    private let freshnessEngine: MuscleFreshnessEngine

    init(freshnessEngine: MuscleFreshnessEngine = MuscleFreshnessEngine()) {
        self.freshnessEngine = freshnessEngine
    }

    func generate(
        context: WorkoutContext,
        sessions: [WorkoutSession],
        referenceDate: Date = .now
    ) -> WorkoutGenerationResult {
        let freshness = freshnessEngine.statuses(
            from: sessions,
            pain: context.painFlag,
            referenceDate: referenceDate
        )
        let plannedCount = context.availableMinutes.exerciseCount
        let targetSets = targetSets(for: context)
        let targetRepRange = targetRepRange(for: context.goal)

        let rankedGroups = MuscleGroup.dashboardGroups.sorted {
            priority(for: freshness[$0]?.status ?? .due) < priority(for: freshness[$1]?.status ?? .due)
        }

        var chosenDefinitions: [ExerciseDefinition] = []
        for group in rankedGroups {
            guard chosenDefinitions.count < plannedCount else { break }
            guard freshness[group]?.status != .caution else { continue }

            if let definition = firstAllowedDefinition(for: group, context: context, excluding: chosenDefinitions) {
                chosenDefinitions.append(definition)
            }
        }

        if chosenDefinitions.count < plannedCount {
            let fallback = ExerciseLibrary.definitions.filter { definition in
                !chosenDefinitions.contains(definition) && isAllowed(definition, for: context.painFlag)
            }

            for definition in fallback {
                guard chosenDefinitions.count < plannedCount else { break }
                guard freshness[definition.primaryMuscleGroup]?.status != .caution else { continue }
                chosenDefinitions.append(definition)
            }
        }

        if chosenDefinitions.isEmpty {
            chosenDefinitions = ExerciseLibrary.definitions
                .filter { $0.primaryMuscleGroup == .core }
                .prefix(plannedCount)
                .map { $0 }
        }

        let exercises = chosenDefinitions.prefix(plannedCount).map { definition in
            PlannedExercise(
                name: definition.name,
                muscleGroup: definition.primaryMuscleGroup,
                secondaryMuscleGroups: definition.secondaryMuscleGroups,
                equipment: definition.equipment,
                targetSets: targetSets,
                targetRepsLower: targetRepRange.lowerBound,
                targetRepsUpper: targetRepRange.upperBound,
                coachingNote: note(for: definition, context: context, freshness: freshness)
            )
        }

        let plan = WorkoutPlan(
            exercises: Array(exercises),
            focusMuscleGroups: Array(Set(exercises.map(\.muscleGroup))).sorted { $0.rawValue < $1.rawValue },
            volumeAdjustmentNote: volumeNote(for: context)
        )

        return WorkoutGenerationResult(plan: plan, freshness: freshness)
    }

    private func firstAllowedDefinition(
        for group: MuscleGroup,
        context: WorkoutContext,
        excluding chosen: [ExerciseDefinition]
    ) -> ExerciseDefinition? {
        ExerciseLibrary.definitions.first { definition in
            definition.primaryMuscleGroup == group
            && !chosen.contains(definition)
            && isAllowed(definition, for: context.painFlag)
        }
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

    private func priority(for status: FreshnessStatus) -> Int {
        switch status {
        case .due: 0
        case .ready: 1
        case .recovering: 2
        case .caution: 3
        }
    }

    private func targetSets(for context: WorkoutContext) -> Int {
        if context.shouldReduceVolume {
            return 2
        }

        if context.canUseFullVolume && context.availableMinutes != .twenty {
            return 4
        }

        return 3
    }

    private func targetRepRange(for goal: FitnessGoal) -> ClosedRange<Int> {
        switch goal {
        case .strength: 5...8
        case .buildMuscle: 8...12
        case .fatLoss: 10...15
        case .generalFitness: 8...12
        }
    }

    private func note(
        for definition: ExerciseDefinition,
        context: WorkoutContext,
        freshness: [MuscleGroup: MuscleFreshnessResult]
    ) -> String {
        if context.painFlag != .none {
            return "Kept pain-aware and inside the safety rules."
        }

        switch freshness[definition.primaryMuscleGroup]?.status {
        case .due:
            return "This area is due for work."
        case .ready:
            return "This area looks ready."
        case .recovering:
            return "Included with controlled volume."
        case .caution:
            return "Use caution today."
        case nil:
            return "Balanced accessory work."
        }
    }

    private func volumeNote(for context: WorkoutContext) -> String {
        if context.shouldReduceVolume {
            return "Volume reduced about 30% because recovery or energy is low."
        }

        if context.canUseFullVolume {
            return "Recovery looks solid, so normal training volume is appropriate."
        }

        return "Normal volume with room to stop early if form drops."
    }
}

