import Foundation

enum ProgressionAction: String, Hashable {
    case increase
    case hold
    case deload
}

struct ProgressionRecommendation: Identifiable, Hashable {
    var id = UUID()
    var exerciseName: String
    var action: ProgressionAction
    var message: String
    var maxIncreasePercentRange: ClosedRange<Double>?
}

struct LoadSuggestion: Identifiable, Hashable {
    var id = UUID()
    var exerciseName: String
    var lastWeight: Double
    var suggestedWeight: Double
    var message: String
}

final class ProgressionEngine {
    func lastCompletedExercise(
        named exerciseName: String,
        in sessions: [WorkoutSession]
    ) -> CompletedExercise? {
        sessions
            .sorted { $0.date > $1.date }
            .compactMap { session in
                session.completedExercises.first { $0.exerciseName == exerciseName }
            }
            .first
    }

    func lastWeight(
        for exerciseName: String,
        in sessions: [WorkoutSession]
    ) -> Double? {
        lastCompletedExercise(named: exerciseName, in: sessions)?
            .sets
            .sorted { $0.timestamp > $1.timestamp }
            .first?
            .weight
    }

    func loadSuggestion(
        for plannedExercise: PlannedExercise,
        recentSessions: [WorkoutSession],
        pain: PainFlag
    ) -> LoadSuggestion? {
        guard let previousExercise = lastCompletedExercise(named: plannedExercise.name, in: recentSessions),
              let lastWeight = previousExercise.sets.sorted(by: { $0.timestamp > $1.timestamp }).first?.weight
        else {
            return nil
        }

        let recommendation = recommendation(
            for: previousExercise,
            recentSessions: recentSessions,
            pain: pain,
            targetReps: plannedExercise.targetRepsLower
        )

        guard recommendation.action == .increase,
              let cap = recommendation.maxIncreasePercentRange,
              lastWeight > 0
        else {
            return LoadSuggestion(
                exerciseName: plannedExercise.name,
                lastWeight: lastWeight,
                suggestedWeight: lastWeight,
                message: "Last time was \(lastWeight.formattedWeight) lb. \(recommendation.message)"
            )
        }

        let smallestPracticalJump = plannedExercise.muscleGroup == .legs ? 5.0 : 2.5
        let maxAllowedWeight = lastWeight * (1 + cap.upperBound / 100)
        let nextPracticalWeight = lastWeight + smallestPracticalJump

        guard nextPracticalWeight <= maxAllowedWeight else {
            return LoadSuggestion(
                exerciseName: plannedExercise.name,
                lastWeight: lastWeight,
                suggestedWeight: lastWeight,
                message: "Last time was \(lastWeight.formattedWeight) lb. Hold until the next jump fits the \(cap.upperBound.formatted(.number.precision(.fractionLength(0...1))))% cap."
            )
        }

        return LoadSuggestion(
            exerciseName: plannedExercise.name,
            lastWeight: lastWeight,
            suggestedWeight: nextPracticalWeight,
            message: "Last time was \(lastWeight.formattedWeight) lb. Try \(nextPracticalWeight.formattedWeight) lb if warm-ups feel clean."
        )
    }

    func recommendation(
        for completedExercise: CompletedExercise,
        recentSessions: [WorkoutSession],
        pain: PainFlag,
        targetReps: Int = 10
    ) -> ProgressionRecommendation {
        if pain != .none {
            return ProgressionRecommendation(
                exerciseName: completedExercise.exerciseName,
                action: .hold,
                message: "Pain was reported, so do not increase load next time.",
                maxIncreasePercentRange: nil
            )
        }

        if shouldDeload(exerciseName: completedExercise.exerciseName, recentSessions: recentSessions) {
            return ProgressionRecommendation(
                exerciseName: completedExercise.exerciseName,
                action: .deload,
                message: "Performance has dropped across multiple sessions. Deload by reducing volume 30-40% and keeping the same pattern lighter.",
                maxIncreasePercentRange: nil
            )
        }

        let sets = completedExercise.sets
        guard !sets.isEmpty else {
            return ProgressionRecommendation(
                exerciseName: completedExercise.exerciseName,
                action: .hold,
                message: "No sets logged yet. Hold the plan until there is data.",
                maxIncreasePercentRange: nil
            )
        }

        let allHitTargetWithRoom = sets.allSatisfy { $0.reps >= targetReps && $0.rir >= 2 }
        let mostlyTooEasy = Double(sets.filter { $0.rir >= 3 }.count) / Double(sets.count) >= 0.6
        let maxEffortOrSharpDrop = sets.contains { $0.rir == 0 } || repsDroppedSharply(sets)

        if maxEffortOrSharpDrop {
            return ProgressionRecommendation(
                exerciseName: completedExercise.exerciseName,
                action: .hold,
                message: "Effort was near max or reps dropped sharply. Hold load and improve consistency.",
                maxIncreasePercentRange: nil
            )
        }

        if allHitTargetWithRoom || mostlyTooEasy {
            let cap = increaseCap(for: completedExercise.muscleGroup)
            return ProgressionRecommendation(
                exerciseName: completedExercise.exerciseName,
                action: .increase,
                message: "You hit the target with reps in reserve. A small increase is reasonable next time.",
                maxIncreasePercentRange: cap
            )
        }

        return ProgressionRecommendation(
            exerciseName: completedExercise.exerciseName,
            action: .hold,
            message: "Hold weight next time and aim for cleaner reps before adding load.",
            maxIncreasePercentRange: nil
        )
    }

    private func repsDroppedSharply(_ sets: [WorkoutSet]) -> Bool {
        guard let first = sets.first?.reps, let last = sets.last?.reps else { return false }
        return first - last >= 4
    }

    private func shouldDeload(exerciseName: String, recentSessions: [WorkoutSession]) -> Bool {
        let matchingExercises = recentSessions
            .sorted { $0.date > $1.date }
            .compactMap { session in
                session.completedExercises.first { $0.exerciseName == exerciseName }
            }
            .prefix(3)

        let volumes = matchingExercises.map { exercise in
            exercise.sets.reduce(0) { $0 + $1.volume }
        }

        guard volumes.count >= 3 else { return false }
        return volumes[0] < volumes[1] && volumes[1] < volumes[2]
    }

    private func increaseCap(for muscleGroup: MuscleGroup) -> ClosedRange<Double> {
        switch muscleGroup {
        case .legs:
            5...10
        case .chest, .back, .shoulders, .biceps, .triceps, .core:
            2.5...5
        }
    }
}

private extension Double {
    var formattedWeight: String {
        formatted(.number.precision(.fractionLength(0...1)))
    }
}
