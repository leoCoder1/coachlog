import Foundation

enum AICoachPreferenceKeys {
    static let isPremiumEnabled = "coachlog.aiPremium.isEnabled"
    static let endpointURL = "coachlog.aiPremium.endpointURL"
    static let defaultEndpointURL = "https://aicoach-foes5b5rkq-uc.a.run.app"
}

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

struct PremiumCoachService: AIService {
    var fallback: AIService = RuleBasedCoachService()
    var defaults: UserDefaults = .standard
    var session: URLSession = .shared

    func generateWorkoutExplanation(
        plan: WorkoutPlan,
        context: WorkoutContext,
        freshness: [MuscleGroup: MuscleFreshnessResult]
    ) async -> String {
        let fallbackMessage = await fallback.generateWorkoutExplanation(
            plan: plan,
            context: context,
            freshness: freshness
        )

        let request = AICoachAPIRequest(
            task: .workoutExplanation,
            context: AICoachWorkoutContextPayload(context: context),
            plan: AICoachPlanPayload(plan: plan),
            freshness: freshness.values
                .sorted { $0.group.rawValue < $1.group.rawValue }
                .map(AICoachFreshnessPayload.init(result:)),
            recentSessions: [],
            measurements: [],
            progression: nil,
            fallbackMessage: fallbackMessage
        )

        return await remoteMessage(for: request) ?? fallbackMessage
    }

    func generateProgressSummary(
        sessions: [WorkoutSession],
        measurements: [BodyMeasurement]
    ) async -> String {
        let fallbackMessage = await fallback.generateProgressSummary(
            sessions: sessions,
            measurements: measurements
        )

        let request = AICoachAPIRequest(
            task: .progressSummary,
            context: nil,
            plan: nil,
            freshness: [],
            recentSessions: sessions
                .sorted { $0.date > $1.date }
                .prefix(12)
                .map(AICoachSessionPayload.init(session:)),
            measurements: measurements
                .sorted { $0.date > $1.date }
                .prefix(8)
                .map(AICoachMeasurementPayload.init(measurement:)),
            progression: nil,
            fallbackMessage: fallbackMessage
        )

        return await remoteMessage(for: request) ?? fallbackMessage
    }

    func generateNextSessionAdvice(
        lastSession: WorkoutSession?,
        recommendation: ProgressionRecommendation?
    ) async -> String {
        let fallbackMessage = await fallback.generateNextSessionAdvice(
            lastSession: lastSession,
            recommendation: recommendation
        )

        let request = AICoachAPIRequest(
            task: .nextSessionAdvice,
            context: nil,
            plan: nil,
            freshness: [],
            recentSessions: lastSession.map { [AICoachSessionPayload(session: $0)] } ?? [],
            measurements: [],
            progression: recommendation.map(AICoachProgressionPayload.init(recommendation:)),
            fallbackMessage: fallbackMessage
        )

        return await remoteMessage(for: request) ?? fallbackMessage
    }

    private func remoteMessage(for request: AICoachAPIRequest) async -> String? {
        let storedEndpoint = defaults.string(forKey: AICoachPreferenceKeys.endpointURL) ?? ""
        let endpointString = storedEndpoint.isEmpty ? AICoachPreferenceKeys.defaultEndpointURL : storedEndpoint

        guard defaults.bool(forKey: AICoachPreferenceKeys.isPremiumEnabled),
              let endpointURL = URL(string: endpointString),
              endpointURL.scheme?.hasPrefix("http") == true else {
            return nil
        }

        do {
            var urlRequest = URLRequest(url: endpointURL)
            urlRequest.httpMethod = "POST"
            urlRequest.timeoutInterval = 14
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.httpBody = try AICoachAPIRequest.encoder.encode(request)

            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                return nil
            }

            let apiResponse = try JSONDecoder().decode(AICoachAPIResponse.self, from: data)
            let message = apiResponse.message.trimmingCharacters(in: .whitespacesAndNewlines)
            return message.isEmpty ? nil : message
        } catch {
            return nil
        }
    }
}

private enum AICoachTask: String, Encodable {
    case workoutExplanation
    case progressSummary
    case nextSessionAdvice
}

private struct AICoachAPIRequest: Encodable {
    var task: AICoachTask
    var context: AICoachWorkoutContextPayload?
    var plan: AICoachPlanPayload?
    var freshness: [AICoachFreshnessPayload]
    var recentSessions: [AICoachSessionPayload]
    var measurements: [AICoachMeasurementPayload]
    var progression: AICoachProgressionPayload?
    var fallbackMessage: String

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}

private struct AICoachAPIResponse: Decodable {
    var message: String
}

private struct AICoachWorkoutContextPayload: Encodable {
    var availableMinutes: Int
    var energyLevel: String
    var painFlag: String
    var goal: String
    var recovery: AICoachRecoveryPayload?

    init(context: WorkoutContext) {
        availableMinutes = context.availableMinutes.rawValue
        energyLevel = context.energyLevel.rawValue
        painFlag = context.painFlag.rawValue
        goal = context.goal.rawValue

        if let recovery = context.recovery {
            self.recovery = AICoachRecoveryPayload(recovery: recovery)
        } else {
            self.recovery = nil
        }
    }
}

private struct AICoachRecoveryPayload: Encodable {
    var sleepHours: Double
    var restingHeartRate: Double
    var hrv: Double
    var readinessScore: Int

    init(recovery: RecoverySnapshotSummary) {
        sleepHours = recovery.sleepHours
        restingHeartRate = recovery.restingHeartRate
        hrv = recovery.hrv
        readinessScore = recovery.readinessScore
    }
}

private struct AICoachPlanPayload: Encodable {
    var focusMuscleGroups: [String]
    var volumeAdjustmentNote: String
    var weeklyRotationNote: String?
    var exercises: [AICoachPlannedExercisePayload]

    init(plan: WorkoutPlan) {
        focusMuscleGroups = plan.focusMuscleGroups.map(\.rawValue)
        volumeAdjustmentNote = plan.volumeAdjustmentNote
        weeklyRotationNote = plan.weeklyRotationNote
        exercises = plan.exercises.map(AICoachPlannedExercisePayload.init(exercise:))
    }
}

private struct AICoachPlannedExercisePayload: Encodable {
    var name: String
    var primaryMuscle: String
    var secondaryMuscles: [String]
    var detailedMuscles: [String]
    var equipment: String
    var station: String
    var kind: String
    var targetSets: Int
    var targetRepsLower: Int
    var targetRepsUpper: Int
    var coachingNote: String

    init(exercise: PlannedExercise) {
        name = exercise.name
        primaryMuscle = exercise.muscleGroup.rawValue
        secondaryMuscles = exercise.secondaryMuscleGroups.map(\.rawValue)
        detailedMuscles = exercise.detailedMuscles.map(\.rawValue)
        equipment = exercise.equipment.rawValue
        station = exercise.station.rawValue
        kind = exercise.kind.rawValue
        targetSets = exercise.targetSets
        targetRepsLower = exercise.targetRepsLower
        targetRepsUpper = exercise.targetRepsUpper
        coachingNote = exercise.coachingNote
    }
}

private struct AICoachFreshnessPayload: Encodable {
    var muscleGroup: String
    var status: String
    var daysSinceTraining: Int?
    var note: String

    init(result: MuscleFreshnessResult) {
        muscleGroup = result.group.rawValue
        status = result.status.rawValue
        daysSinceTraining = result.daysSinceTraining
        note = result.note
    }
}

private struct AICoachSessionPayload: Encodable {
    var date: Date
    var durationMinutes: Int
    var energyLevel: String
    var painFlag: String
    var goal: String
    var exercises: [AICoachCompletedExercisePayload]

    init(session: WorkoutSession) {
        date = session.date
        durationMinutes = Int((session.duration / 60).rounded())
        energyLevel = session.energyLevel.rawValue
        painFlag = session.painFlag.rawValue
        goal = session.goal.rawValue
        exercises = session.completedExercises.map(AICoachCompletedExercisePayload.init(exercise:))
    }
}

private struct AICoachCompletedExercisePayload: Encodable {
    var name: String
    var muscleGroup: String
    var sets: [AICoachSetPayload]

    init(exercise: CompletedExercise) {
        name = exercise.exerciseName
        muscleGroup = exercise.muscleGroup.rawValue
        sets = exercise.sets.map(AICoachSetPayload.init(set:))
    }
}

private struct AICoachSetPayload: Encodable {
    var weightPounds: Double
    var reps: Int
    var rir: Int

    init(set: WorkoutSet) {
        weightPounds = set.weight
        reps = set.reps
        rir = set.rir
    }
}

private struct AICoachMeasurementPayload: Encodable {
    var date: Date
    var weightPounds: Double
    var waistInches: Double
    var chestInches: Double
    var armInches: Double
    var thighInches: Double
    var abdomenInches: Double?

    init(measurement: BodyMeasurement) {
        date = measurement.date
        weightPounds = measurement.weight
        waistInches = measurement.waist
        chestInches = measurement.chest
        armInches = measurement.arm
        thighInches = measurement.thigh
        abdomenInches = measurement.abdomen
    }
}

private struct AICoachProgressionPayload: Encodable {
    var exerciseName: String
    var action: String
    var message: String

    init(recommendation: ProgressionRecommendation) {
        exerciseName = recommendation.exerciseName
        action = recommendation.action.rawValue
        message = recommendation.message
    }
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
