import Foundation
import SwiftData

@Model
final class StrengthBaselineTest {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var date: Date
    var weight: Double
    var reps: Int

    init(
        id: UUID = UUID(),
        exerciseName: String,
        date: Date = .now,
        weight: Double,
        reps: Int
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.date = date
        self.weight = weight
        self.reps = reps
    }

    var estimatedOneRepMax: Double {
        guard reps > 0 else { return weight }
        return weight * (1 + Double(reps) / 30)
    }

    var retestDueDate: Date {
        Calendar.current.date(byAdding: .day, value: 28, to: date) ?? date
    }
}

struct StrengthBaselineSummary: Identifiable {
    var id: String { exerciseName }
    var exerciseName: String
    var first: StrengthBaselineTest?
    var latest: StrengthBaselineTest?

    var percentChange: Double? {
        guard let first, let latest, first.id != latest.id, first.estimatedOneRepMax > 0 else {
            return nil
        }

        return ((latest.estimatedOneRepMax - first.estimatedOneRepMax) / first.estimatedOneRepMax) * 100
    }

    var isRetestDue: Bool {
        guard let latest else { return false }
        return latest.retestDueDate <= .now
    }
}

enum StrengthBaselineLibrary {
    static let keyExerciseNames = [
        "Dumbbell Bench Press",
        "Lat Pulldown",
        "Goblet Squat",
        "Romanian Deadlift"
    ]

    static func summary(
        for exerciseName: String,
        tests: [StrengthBaselineTest]
    ) -> StrengthBaselineSummary {
        let matching = tests
            .filter { $0.exerciseName == exerciseName }
            .sorted { $0.date < $1.date }

        return StrengthBaselineSummary(
            exerciseName: exerciseName,
            first: matching.first,
            latest: matching.last
        )
    }
}
