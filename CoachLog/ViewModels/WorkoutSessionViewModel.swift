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

@MainActor
@Observable
final class WorkoutSessionViewModel {
    let plan: WorkoutPlan
    let startedAt: Date
    var inputs: [UUID: SetInput]
    var loggedSets: [UUID: [LoggedSetDraft]]
    var loadSuggestions: [UUID: LoadSuggestion]

    @ObservationIgnored private let progressionEngine: ProgressionEngine
    @ObservationIgnored private var didPrepareFromHistory = false

    init(
        plan: WorkoutPlan,
        startedAt: Date = .now,
        progressionEngine: ProgressionEngine = ProgressionEngine()
    ) {
        self.plan = plan
        self.startedAt = startedAt
        self.inputs = Dictionary(uniqueKeysWithValues: plan.exercises.map { exercise in
            (exercise.id, SetInput(weight: 0, reps: exercise.targetRepsLower, rir: 2))
        })
        self.loggedSets = Dictionary(uniqueKeysWithValues: plan.exercises.map { ($0.id, []) })
        self.loadSuggestions = [:]
        self.progressionEngine = progressionEngine
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
            if let lastWeight = progressionEngine.lastWeight(for: exercise.name, in: sessions) {
                var input = input(for: exercise.id)
                input.weight = nearestWeightOption(to: lastWeight)
                inputs[exercise.id] = input
            }

            if let suggestion = progressionEngine.loadSuggestion(
                for: exercise,
                recentSessions: sessions,
                pain: context.painFlag
            ) {
                loadSuggestions[exercise.id] = suggestion
            }
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

    private func nearestWeightOption(to weight: Double) -> Double {
        let clamped = min(400, max(0, weight))
        return (clamped / 2.5).rounded() * 2.5
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
}
