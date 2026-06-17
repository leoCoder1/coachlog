import Foundation
import Observation

@MainActor
@Observable
final class TodayCoachViewModel {
    var selectedMinutes: AvailableMinutes = .forty
    var selectedEnergy: EnergyLevel = .normal
    var selectedPain: PainFlag = .none
    var selectedGoal: FitnessGoal = .buildMuscle
    var generatedPlan: WorkoutPlan?
    var generatedContext: WorkoutContext?
    var explanation = ""
    var isGenerating = false

    @ObservationIgnored private let generator: WorkoutGenerator
    @ObservationIgnored private let aiService: AIService

    init(
        generator: WorkoutGenerator = WorkoutGenerator(),
        aiService: AIService = PremiumCoachService()
    ) {
        self.generator = generator
        self.aiService = aiService
    }

    func generateWorkout(
        sessions: [WorkoutSession],
        latestRecovery: RecoverySnapshot?
    ) async {
        isGenerating = true
        defer { isGenerating = false }

        let context = WorkoutContext(
            availableMinutes: selectedMinutes,
            energyLevel: selectedEnergy,
            painFlag: selectedPain,
            goal: selectedGoal,
            recovery: latestRecovery.map(RecoverySnapshotSummary.init(snapshot:))
        )

        let result = generator.generate(context: context, sessions: sessions)
        generatedPlan = result.plan
        generatedContext = context
        explanation = await aiService.generateWorkoutExplanation(
            plan: result.plan,
            context: context,
            freshness: result.freshness
        )
    }

    func clearGeneratedPlan() {
        generatedPlan = nil
        generatedContext = nil
        explanation = ""
    }
}
