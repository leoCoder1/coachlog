import Foundation

protocol AIService {
    func generateWorkoutExplanation(
        plan: WorkoutPlan,
        context: WorkoutContext,
        freshness: [MuscleGroup: MuscleFreshnessResult]
    ) async -> String

    func generateProgressSummary(
        sessions: [WorkoutSession],
        measurements: [BodyMeasurement]
    ) async -> String

    func generateNextSessionAdvice(
        lastSession: WorkoutSession?,
        recommendation: ProgressionRecommendation?
    ) async -> String
}

struct RuleBasedCoachService: AIService {
    func generateWorkoutExplanation(
        plan: WorkoutPlan,
        context: WorkoutContext,
        freshness: [MuscleGroup: MuscleFreshnessResult]
    ) async -> String {
        let focus = plan.focusMuscleGroups.map(\.rawValue).joined(separator: ", ")
        let dueGroup = plan.focusMuscleGroups.first { freshness[$0]?.status == .due }
        let recoveringGroup = MuscleGroup.dashboardGroups.first { freshness[$0]?.status == .recovering }

        if context.painFlag != .none {
            return withRotationNote(
                "We are keeping today pain-aware. The workout avoids movements that could aggravate \(context.painFlag.displayName.lowercased()) discomfort, and load increases stay off the table until that flag clears.",
                plan: plan
            )
        }

        if let dueGroup, let recoveringGroup {
            return withRotationNote(
                "We are choosing \(focus) because \(dueGroup.rawValue.lowercased()) is due and \(recoveringGroup.rawValue.lowercased()) is still recovering. Keep two good reps in reserve on most sets.",
                plan: plan
            )
        }

        return withRotationNote(
            "We are choosing \(focus) because those areas are the best match for your freshness, time, and energy today. \(plan.volumeAdjustmentNote)",
            plan: plan
        )
    }

    func generateProgressSummary(
        sessions: [WorkoutSession],
        measurements: [BodyMeasurement]
    ) async -> String {
        let weeklyCount = ProgressViewModel.weeklyWorkoutCount(sessions)

        if weeklyCount >= 3 {
            return "You trained \(weeklyCount) times this week. That is the habit that compounds."
        }

        if let latestMeasurement = measurements.sorted(by: { $0.date > $1.date }).first {
            return "Latest weight is \(WeightUnitPreference.current.formattedWeight(latestMeasurement.weight, fractionLength: 1...1)). Keep the trend slow enough that training performance stays steady."
        }

        return "Log a few sessions and CoachLog will start connecting training volume, recovery, and body measurements."
    }

    func generateNextSessionAdvice(
        lastSession: WorkoutSession?,
        recommendation: ProgressionRecommendation?
    ) async -> String {
        guard let lastSession else {
            return "Start with a clean session today. The first goal is useful data, not perfect numbers."
        }

        if lastSession.painFlag != .none {
            return "Pain was reported last session. Next time, choose substitutions early and do not increase load."
        }

        if let recommendation {
            return recommendation.message
        }

        return "Repeat the strongest patterns from the last session and only add load where reps stayed clean."
    }

    private func withRotationNote(_ message: String, plan: WorkoutPlan) -> String {
        guard let weeklyRotationNote = plan.weeklyRotationNote else {
            return message
        }

        return "\(message) \(weeklyRotationNote)"
    }
}
