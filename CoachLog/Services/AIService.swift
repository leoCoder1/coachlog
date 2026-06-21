import Foundation

enum AICoachPreferenceKeys {
    static let isPremiumEnabled = "coachlog.aiPremium.isEnabled"
    static let endpointURL = "coachlog.aiPremium.endpointURL"
    static let defaultEndpointURL = "https://aicoach-foes5b5rkq-uc.a.run.app"
}

enum AICoachTrainingMode: String, Codable, CaseIterable, Hashable {
    case push
    case normal
    case hold
    case deload
    case rest

    var displayName: String {
        switch self {
        case .push: "Push"
        case .normal: "Normal"
        case .hold: "Hold"
        case .deload: "Deload"
        case .rest: "Rest"
        }
    }

    var priority: Int {
        switch self {
        case .rest: 0
        case .deload: 1
        case .hold: 2
        case .normal: 3
        case .push: 4
        }
    }

    static func conservative(_ lhs: AICoachTrainingMode, _ rhs: AICoachTrainingMode) -> AICoachTrainingMode {
        lhs.priority <= rhs.priority ? lhs : rhs
    }
}

enum AICoachExerciseAction: String, Codable, Hashable {
    case increase
    case hold
    case reduce
    case substitute

    var displayName: String {
        switch self {
        case .increase: "Increase"
        case .hold: "Hold"
        case .reduce: "Reduce"
        case .substitute: "Swap"
        }
    }
}

struct AICoachExerciseAdvice: Codable, Hashable, Identifiable {
    var id: String { exerciseName }
    var exerciseName: String
    var action: AICoachExerciseAction
    var suggestedWeightPounds: Double?
    var reason: String

    func suggestedWeightText(unit: WeightUnitPreference) -> String? {
        guard let suggestedWeightPounds else { return nil }
        return unit.formattedWeight(suggestedWeightPounds)
    }
}

struct TodayCoachGuidance: Codable, Hashable {
    var trainingMode: AICoachTrainingMode
    var message: String
    var exerciseAdvice: [AICoachExerciseAdvice]
    var source: String

    func advice(for exerciseName: String) -> AICoachExerciseAdvice? {
        exerciseAdvice.first {
            $0.exerciseName.localizedCaseInsensitiveCompare(exerciseName) == .orderedSame
        }
    }
}

protocol AIService {
    func generateTodayGuidance(
        plan: WorkoutPlan,
        context: WorkoutContext,
        freshness: [MuscleGroup: MuscleFreshnessResult],
        weeklyLoads: [MuscleGroup: WeeklyMuscleLoad],
        sessions: [WorkoutSession],
        recoverySnapshots: [RecoverySnapshot],
        measurements: [BodyMeasurement]
    ) async -> TodayCoachGuidance

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

    private let progressionEngine = ProgressionEngine()

    func generateTodayGuidance(
        plan: WorkoutPlan,
        context: WorkoutContext,
        freshness: [MuscleGroup: MuscleFreshnessResult],
        weeklyLoads: [MuscleGroup: WeeklyMuscleLoad],
        sessions: [WorkoutSession],
        recoverySnapshots: [RecoverySnapshot],
        measurements: [BodyMeasurement]
    ) async -> TodayCoachGuidance {
        let fallbackGuidance = await fallback.generateTodayGuidance(
            plan: plan,
            context: context,
            freshness: freshness,
            weeklyLoads: weeklyLoads,
            sessions: sessions,
            recoverySnapshots: recoverySnapshots,
            measurements: measurements
        )

        let recentSessions = recentSessions(from: sessions)
        let request = AICoachAPIRequest(
            task: .todayAdvisor,
            context: AICoachWorkoutContextPayload(context: context),
            plan: AICoachPlanPayload(plan: plan),
            freshness: freshness.values
                .sorted { $0.group.rawValue < $1.group.rawValue }
                .map(AICoachFreshnessPayload.init(result:)),
            weeklyLoads: weeklyLoads.values
                .sorted { $0.group.rawValue < $1.group.rawValue }
                .map(AICoachWeeklyLoadPayload.init(load:)),
            recentSessions: recentSessions.map(AICoachSessionPayload.init(session:)),
            recoveryTrend: recoverySnapshots
                .sorted { $0.date > $1.date }
                .prefix(14)
                .map(AICoachRecoveryTrendPayload.init(snapshot:)),
            measurements: measurements
                .sorted { $0.date > $1.date }
                .prefix(8)
                .map(AICoachMeasurementPayload.init(measurement:)),
            exerciseProgressions: exerciseProgressions(
                for: plan,
                sessions: recentSessions,
                pain: context.painFlag
            ),
            progression: nil,
            fallbackMessage: fallbackGuidance.message,
            fallbackGuidance: fallbackGuidance
        )

        guard let remoteGuidance = await remoteGuidance(for: request) else {
            return fallbackGuidance
        }

        return conservativelyMerged(remote: remoteGuidance, fallback: fallbackGuidance)
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
            weeklyLoads: [],
            recentSessions: sessions
                .sorted { $0.date > $1.date }
                .prefix(12)
                .map(AICoachSessionPayload.init(session:)),
            recoveryTrend: [],
            measurements: measurements
                .sorted { $0.date > $1.date }
                .prefix(8)
                .map(AICoachMeasurementPayload.init(measurement:)),
            exerciseProgressions: [],
            progression: nil,
            fallbackMessage: fallbackMessage,
            fallbackGuidance: nil
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
            weeklyLoads: [],
            recentSessions: lastSession.map { [AICoachSessionPayload(session: $0)] } ?? [],
            recoveryTrend: [],
            measurements: [],
            exerciseProgressions: [],
            progression: recommendation.map(AICoachProgressionPayload.init(recommendation:)),
            fallbackMessage: fallbackMessage,
            fallbackGuidance: nil
        )

        return await remoteMessage(for: request) ?? fallbackMessage
    }

    private func remoteMessage(for request: AICoachAPIRequest) async -> String? {
        guard let apiResponse = await remoteResponse(for: request) else {
            return nil
        }

        let message = apiResponse.message.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? nil : message
    }

    private func remoteGuidance(for request: AICoachAPIRequest) async -> TodayCoachGuidance? {
        guard let apiResponse = await remoteResponse(for: request) else {
            return nil
        }

        let message = apiResponse.message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return nil }

        return TodayCoachGuidance(
            trainingMode: apiResponse.trainingMode ?? request.fallbackGuidance?.trainingMode ?? .normal,
            message: message,
            exerciseAdvice: apiResponse.exerciseAdvice ?? request.fallbackGuidance?.exerciseAdvice ?? [],
            source: apiResponse.source ?? "premium"
        )
    }

    private func remoteResponse(for request: AICoachAPIRequest) async -> AICoachAPIResponse? {
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
            urlRequest.timeoutInterval = 18
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.httpBody = try AICoachAPIRequest.encoder.encode(request)

            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                return nil
            }

            return try JSONDecoder().decode(AICoachAPIResponse.self, from: data)
        } catch {
            return nil
        }
    }

    private func recentSessions(from sessions: [WorkoutSession]) -> [WorkoutSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -42, to: .now) ?? .distantPast
        return sessions
            .filter { $0.date >= cutoff }
            .sorted { $0.date > $1.date }
            .prefix(18)
            .map { $0 }
    }

    private func exerciseProgressions(
        for plan: WorkoutPlan,
        sessions: [WorkoutSession],
        pain: PainFlag
    ) -> [AICoachExerciseProgressionPayload] {
        plan.exercises.compactMap { exercise in
            AICoachExerciseProgressionPayload(
                exercise: exercise,
                sessions: sessions,
                pain: pain,
                progressionEngine: progressionEngine
            )
        }
    }

    private func conservativelyMerged(
        remote: TodayCoachGuidance,
        fallback: TodayCoachGuidance
    ) -> TodayCoachGuidance {
        let trainingMode = AICoachTrainingMode.conservative(remote.trainingMode, fallback.trainingMode)
        let fallbackAdviceByName = Dictionary(
            uniqueKeysWithValues: fallback.exerciseAdvice.map { ($0.exerciseName.lowercased(), $0) }
        )

        var mergedAdvice: [AICoachExerciseAdvice] = []
        let remoteAdviceByName = Dictionary(
            uniqueKeysWithValues: remote.exerciseAdvice.map { ($0.exerciseName.lowercased(), $0) }
        )

        for fallbackAdvice in fallback.exerciseAdvice {
            guard var remoteAdvice = remoteAdviceByName[fallbackAdvice.exerciseName.lowercased()] else {
                mergedAdvice.append(fallbackAdvice)
                continue
            }

            remoteAdvice = conservativelyMerged(remote: remoteAdvice, fallback: fallbackAdvice)
            mergedAdvice.append(remoteAdvice)
        }

        for remoteAdvice in remote.exerciseAdvice
        where fallbackAdviceByName[remoteAdvice.exerciseName.lowercased()] == nil {
            mergedAdvice.append(remoteAdvice)
        }

        let message = trainingMode.priority < remote.trainingMode.priority ? fallback.message : remote.message
        return TodayCoachGuidance(
            trainingMode: trainingMode,
            message: message,
            exerciseAdvice: mergedAdvice,
            source: remote.source
        )
    }

    private func conservativelyMerged(
        remote: AICoachExerciseAdvice,
        fallback: AICoachExerciseAdvice
    ) -> AICoachExerciseAdvice {
        var result = remote

        if remote.action == .increase && fallback.action != .increase {
            result.action = fallback.action
            result.suggestedWeightPounds = fallback.suggestedWeightPounds
            result.reason = fallback.reason
            return result
        }

        if let remoteWeight = remote.suggestedWeightPounds,
           let fallbackWeight = fallback.suggestedWeightPounds,
           remoteWeight > fallbackWeight {
            result.suggestedWeightPounds = fallbackWeight
            result.reason = fallback.reason
        }

        return result
    }
}

private enum AICoachTask: String, Encodable {
    case todayAdvisor
    case progressSummary
    case nextSessionAdvice
}

private struct AICoachAPIRequest: Encodable {
    var task: AICoachTask
    var context: AICoachWorkoutContextPayload?
    var plan: AICoachPlanPayload?
    var freshness: [AICoachFreshnessPayload]
    var weeklyLoads: [AICoachWeeklyLoadPayload]
    var recentSessions: [AICoachSessionPayload]
    var recoveryTrend: [AICoachRecoveryTrendPayload]
    var measurements: [AICoachMeasurementPayload]
    var exerciseProgressions: [AICoachExerciseProgressionPayload]
    var progression: AICoachProgressionPayload?
    var fallbackMessage: String
    var fallbackGuidance: TodayCoachGuidance?

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}

private struct AICoachAPIResponse: Decodable {
    var message: String
    var trainingMode: AICoachTrainingMode?
    var exerciseAdvice: [AICoachExerciseAdvice]?
    var source: String?
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

private struct AICoachRecoveryTrendPayload: Encodable {
    var date: Date
    var sleepHours: Double
    var restingHeartRate: Double
    var hrv: Double
    var readinessScore: Int
    var source: String?

    init(snapshot: RecoverySnapshot) {
        date = snapshot.date
        sleepHours = snapshot.sleepHours
        restingHeartRate = snapshot.restingHeartRate
        hrv = snapshot.hrv
        readinessScore = snapshot.readinessScore
        source = snapshot.source
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

private struct AICoachWeeklyLoadPayload: Encodable {
    var muscleGroup: String
    var setCount: Int
    var exerciseCount: Int
    var sessionCount: Int
    var lastTrainingDate: Date?

    init(load: WeeklyMuscleLoad) {
        muscleGroup = load.group.rawValue
        setCount = load.setCount
        exerciseCount = load.exerciseCount
        sessionCount = load.sessionCount
        lastTrainingDate = load.lastTrainingDate
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

private struct AICoachExerciseProgressionPayload: Encodable {
    var exerciseName: String
    var action: String
    var message: String
    var lastWeightPounds: Double?
    var suggestedWeightPounds: Double?
    var targetRepsLower: Int
    var targetRepsUpper: Int

    init?(
        exercise: PlannedExercise,
        sessions: [WorkoutSession],
        pain: PainFlag,
        progressionEngine: ProgressionEngine
    ) {
        guard let previousExercise = progressionEngine.lastCompletedExercise(
            named: exercise.name,
            in: sessions
        ) else {
            return nil
        }

        let recommendation = progressionEngine.recommendation(
            for: previousExercise,
            recentSessions: sessions,
            pain: pain,
            targetReps: exercise.targetRepsLower
        )
        let suggestion = progressionEngine.loadSuggestion(
            for: exercise,
            recentSessions: sessions,
            pain: pain
        )

        exerciseName = exercise.name
        action = recommendation.action.rawValue
        message = recommendation.message
        lastWeightPounds = suggestion?.lastWeight ?? progressionEngine.lastWeight(for: exercise.name, in: sessions)
        suggestedWeightPounds = suggestion?.suggestedWeight
        targetRepsLower = exercise.targetRepsLower
        targetRepsUpper = exercise.targetRepsUpper
    }
}

struct RuleBasedCoachService: AIService {
    private let progressionEngine = ProgressionEngine()

    func generateTodayGuidance(
        plan: WorkoutPlan,
        context: WorkoutContext,
        freshness: [MuscleGroup: MuscleFreshnessResult],
        weeklyLoads: [MuscleGroup: WeeklyMuscleLoad],
        sessions: [WorkoutSession],
        recoverySnapshots: [RecoverySnapshot],
        measurements: [BodyMeasurement]
    ) async -> TodayCoachGuidance {
        let advice = exerciseAdvice(for: plan, sessions: sessions, context: context)
        let mode = trainingMode(context: context, advice: advice)
        let message = workoutMessage(
            plan: plan,
            context: context,
            freshness: freshness,
            weeklyLoads: weeklyLoads,
            advice: advice
        )

        return TodayCoachGuidance(
            trainingMode: mode,
            message: message,
            exerciseAdvice: advice,
            source: "local"
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

        return "Log a few sessions and AI Coach will start connecting training volume, recovery, and body measurements."
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

    private func workoutMessage(
        plan: WorkoutPlan,
        context: WorkoutContext,
        freshness: [MuscleGroup: MuscleFreshnessResult],
        weeklyLoads: [MuscleGroup: WeeklyMuscleLoad],
        advice: [AICoachExerciseAdvice]
    ) -> String {
        let focus = plan.focusMuscleGroups.map(\.rawValue).joined(separator: ", ")
        let increase = advice.first { $0.action == .increase }
        let dueGroup = plan.focusMuscleGroups.first { freshness[$0]?.status == .due }
        let recoveringGroup = MuscleGroup.dashboardGroups.first { freshness[$0]?.status == .recovering }

        if context.painFlag != .none {
            return withRotationNote(
                "Today is pain-aware. Keep the workout in a pain-free range, choose swaps early, and do not chase load increases until \(context.painFlag.displayName.lowercased()) discomfort clears.",
                plan: plan
            )
        }

        if context.shouldReduceVolume {
            return withRotationNote(
                "Readiness says to train lighter today. Keep \(focus.lowercased()) work crisp, stop before form drops, and use the session to preserve rhythm rather than set records.",
                plan: plan
            )
        }

        if context.canUseFullVolume, let increase {
            let weightText = increase.suggestedWeightPounds.map {
                WeightUnitPreference.current.formattedWeight($0)
            }
            let pushText = weightText.map { "try \($0) on \(increase.exerciseName)" }
                ?? "push \(increase.exerciseName) slightly"
            return withRotationNote(
                "Readiness looks strong, so \(pushText) if warm-ups feel clean. Keep two good reps in reserve and let the rest of the plan support \(focus.lowercased()).",
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
            "We are choosing \(focus) because those areas best match your freshness, time, and energy today. \(plan.volumeAdjustmentNote)",
            plan: plan
        )
    }

    private func exerciseAdvice(
        for plan: WorkoutPlan,
        sessions: [WorkoutSession],
        context: WorkoutContext
    ) -> [AICoachExerciseAdvice] {
        plan.exercises.compactMap { exercise in
            guard let previousExercise = progressionEngine.lastCompletedExercise(
                named: exercise.name,
                in: sessions
            ) else {
                return nil
            }

            let recommendation = progressionEngine.recommendation(
                for: previousExercise,
                recentSessions: sessions,
                pain: context.painFlag,
                targetReps: exercise.targetRepsLower
            )
            let suggestion = progressionEngine.loadSuggestion(
                for: exercise,
                recentSessions: sessions,
                pain: context.painFlag
            )

            return AICoachExerciseAdvice(
                exerciseName: exercise.name,
                action: adviceAction(for: recommendation.action),
                suggestedWeightPounds: suggestion?.suggestedWeight,
                reason: recommendation.message
            )
        }
    }

    private func trainingMode(
        context: WorkoutContext,
        advice: [AICoachExerciseAdvice]
    ) -> AICoachTrainingMode {
        if context.painFlag != .none {
            return .hold
        }

        if context.shouldReduceVolume {
            return .deload
        }

        if context.canUseFullVolume && advice.contains(where: { $0.action == .increase }) {
            return .push
        }

        return .normal
    }

    private func adviceAction(for action: ProgressionAction) -> AICoachExerciseAction {
        switch action {
        case .increase: .increase
        case .hold: .hold
        case .deload: .reduce
        }
    }

    private func withRotationNote(_ message: String, plan: WorkoutPlan) -> String {
        guard let weeklyRotationNote = plan.weeklyRotationNote else {
            return message
        }

        return "\(message) \(weeklyRotationNote)"
    }
}
