import Foundation

struct PendingSharedWorkoutImport: Identifiable, Hashable {
    let id = UUID()
    var workout: SharedWorkoutPayload
}

struct SharedWorkoutPayload: Codable, Hashable, Identifiable {
    static let urlScheme = "coachlog"
    private static let urlHost = "share-workout"
    private static let payloadQueryName = "payload"

    var version: Int
    var id: UUID
    var name: String
    var goalRaw: String
    var scheduledWeekdayRaw: String?
    var exercises: [SharedWorkoutExercisePayload]

    init(
        version: Int = 1,
        id: UUID = UUID(),
        name: String,
        goal: FitnessGoal,
        scheduledWeekday: WorkoutWeekday?,
        exercises: [SharedWorkoutExercisePayload]
    ) {
        self.version = version
        self.id = id
        self.name = name
        self.goalRaw = goal.rawValue
        self.scheduledWeekdayRaw = scheduledWeekday?.rawValue
        self.exercises = exercises
    }

    init(template: WorkoutTemplate) {
        self.init(
            id: template.id,
            name: template.name,
            goal: template.goal,
            scheduledWeekday: template.scheduledWeekday,
            exercises: template.orderedExercises.map(SharedWorkoutExercisePayload.init(templateExercise:))
        )
    }

    var goal: FitnessGoal {
        FitnessGoal(rawValue: goalRaw) ?? .generalFitness
    }

    var scheduledWeekday: WorkoutWeekday? {
        guard let scheduledWeekdayRaw else { return nil }
        return WorkoutWeekday(rawValue: scheduledWeekdayRaw)
    }

    var scheduleLabel: String {
        scheduledWeekday?.rawValue ?? "Any day"
    }

    var exerciseCountText: String {
        "\(exercises.count) \(exercises.count == 1 ? "movement" : "movements")"
    }

    var estimatedMinutes: Int {
        let minutes = exercises.reduce(0) { total, exercise in
            let minutesPerSet = exercise.kind == .stretch ? 1 : 3
            return total + max(1, exercise.targetSets) * minutesPerSet
        }

        return max(10, minutes)
    }

    var shareURL: URL? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }

        var components = URLComponents()
        components.scheme = Self.urlScheme
        components.host = Self.urlHost
        components.queryItems = [
            URLQueryItem(name: Self.payloadQueryName, value: data.base64URLEncodedString)
        ]

        return components.url
    }

    var shareMessage: String {
        "Open this CoachLog link to preview the workout, then add or discard it in your own account."
    }

    static func workout(from url: URL) -> SharedWorkoutPayload? {
        guard url.scheme?.lowercased() == urlScheme,
              url.host?.lowercased() == urlHost,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let encodedPayload = components.queryItems?.first(where: { $0.name == payloadQueryName })?.value,
              let data = encodedPayload.base64URLDecodedData,
              let workout = try? JSONDecoder().decode(SharedWorkoutPayload.self, from: data),
              !workout.exercises.isEmpty else {
            return nil
        }

        return workout
    }

    func makeTemplate(existingNames: Set<String>) -> WorkoutTemplate {
        WorkoutTemplate(
            name: uniqueImportName(existingNames: existingNames),
            goal: goal,
            scheduledWeekday: scheduledWeekday,
            templateExercises: exercises.enumerated().map { index, exercise in
                exercise.makeTemplateExercise(orderIndex: index)
            }
        )
    }

    private func uniqueImportName(existingNames: Set<String>) -> String {
        let baseName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Shared Workout"
            : name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard existingNames.contains(baseName) else {
            return baseName
        }

        let sharedName = "\(baseName) (Shared)"
        guard existingNames.contains(sharedName) else {
            return sharedName
        }

        var copyIndex = 2
        while existingNames.contains("\(baseName) (Shared \(copyIndex))") {
            copyIndex += 1
        }

        return "\(baseName) (Shared \(copyIndex))"
    }
}

struct SharedWorkoutExercisePayload: Codable, Hashable, Identifiable {
    var id: UUID
    var exerciseName: String
    var primaryMuscleGroupRaw: String
    var secondaryMuscleGroupRaws: [String]
    var equipmentRaw: String
    var stationRaw: String
    var primaryDetailedMuscleRaw: String
    var secondaryDetailedMuscleRaw: String?
    var kindRaw: String
    var targetSets: Int
    var targetRepsLower: Int
    var targetRepsUpper: Int
    var coachingNote: String

    init(templateExercise: WorkoutTemplateExercise) {
        self.id = templateExercise.id
        self.exerciseName = templateExercise.exerciseName
        self.primaryMuscleGroupRaw = templateExercise.primaryMuscleGroupRaw
        self.secondaryMuscleGroupRaws = templateExercise.secondaryMuscleGroups.map(\.rawValue)
        self.equipmentRaw = templateExercise.equipmentRaw
        self.stationRaw = templateExercise.stationRaw
        self.primaryDetailedMuscleRaw = templateExercise.primaryDetailedMuscleRaw
        self.secondaryDetailedMuscleRaw = templateExercise.secondaryDetailedMuscleRaw
        self.kindRaw = templateExercise.kindRaw
        self.targetSets = templateExercise.targetSets
        self.targetRepsLower = templateExercise.targetRepsLower
        self.targetRepsUpper = templateExercise.targetRepsUpper
        self.coachingNote = templateExercise.coachingNote
    }

    var primaryMuscleGroup: MuscleGroup {
        MuscleGroup(rawValue: primaryMuscleGroupRaw) ?? .core
    }

    var secondaryMuscleGroups: [MuscleGroup] {
        secondaryMuscleGroupRaws.compactMap(MuscleGroup.init(rawValue:))
    }

    var equipment: Equipment {
        Equipment(rawValue: equipmentRaw) ?? .bodyweight
    }

    var station: GymStation {
        GymStation(rawValue: stationRaw) ?? .bodyweight
    }

    var primaryDetailedMuscle: DetailedMuscleGroup {
        DetailedMuscleGroup(rawValue: primaryDetailedMuscleRaw) ?? DetailedMuscleGroup.defaults(for: primaryMuscleGroup)[0]
    }

    var secondaryDetailedMuscle: DetailedMuscleGroup? {
        guard let secondaryDetailedMuscleRaw else { return nil }
        return DetailedMuscleGroup(rawValue: secondaryDetailedMuscleRaw)
    }

    var kind: ExerciseKind {
        ExerciseKind(rawValue: kindRaw) ?? .strength
    }

    var targetRepRange: String {
        "\(targetRepsLower)-\(targetRepsUpper)"
    }

    func makeTemplateExercise(orderIndex: Int) -> WorkoutTemplateExercise {
        WorkoutTemplateExercise(
            sourceExerciseID: nil,
            orderIndex: orderIndex,
            exerciseName: exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Shared Movement" : exerciseName,
            primaryMuscleGroup: primaryMuscleGroup,
            secondaryMuscleGroups: secondaryMuscleGroups,
            equipment: equipment,
            station: station,
            primaryDetailedMuscle: primaryDetailedMuscle,
            secondaryDetailedMuscle: secondaryDetailedMuscle,
            kind: kind,
            targetSets: max(1, targetSets),
            targetRepsLower: max(1, min(targetRepsLower, targetRepsUpper)),
            targetRepsUpper: max(targetRepsLower, targetRepsUpper),
            coachingNote: coachingNote
        )
    }
}

private extension Data {
    var base64URLEncodedString: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension String {
    var base64URLDecodedData: Data? {
        var base64 = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padding = base64.count % 4
        if padding > 0 {
            base64.append(String(repeating: "=", count: 4 - padding))
        }

        return Data(base64Encoded: base64)
    }
}
