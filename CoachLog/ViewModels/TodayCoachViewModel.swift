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
    var guidance: TodayCoachGuidance?
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
        recoverySnapshots: [RecoverySnapshot],
        measurements: [BodyMeasurement]
    ) async {
        isGenerating = true
        defer { isGenerating = false }

        let context = WorkoutContext(
            availableMinutes: selectedMinutes,
            energyLevel: selectedEnergy,
            painFlag: selectedPain,
            goal: selectedGoal,
            recovery: recoverySnapshots.first.map(RecoverySnapshotSummary.init(snapshot:))
        )

        let result = generator.generate(context: context, sessions: sessions)
        generatedPlan = result.plan
        generatedContext = context
        let todayGuidance = await aiService.generateTodayGuidance(
            plan: result.plan,
            context: context,
            freshness: result.freshness,
            weeklyLoads: result.weeklyLoads,
            sessions: sessions,
            recoverySnapshots: recoverySnapshots,
            measurements: measurements
        )
        guidance = todayGuidance
        explanation = todayGuidance.message
    }

    func clearGeneratedPlan() {
        generatedPlan = nil
        generatedContext = nil
        guidance = nil
        explanation = ""
    }
}
