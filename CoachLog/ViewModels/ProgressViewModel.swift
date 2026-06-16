import Foundation

struct WeeklyVolumePoint: Identifiable {
    var id: Date { weekStart }
    var weekStart: Date
    var volume: Double
}

struct BestLift: Identifiable {
    var id: String { exerciseName }
    var exerciseName: String
    var weight: Double
}

struct BodyWeightPoint: Identifiable {
    var id: Date { date }
    var date: Date
    var weight: Double
}

enum ProgressViewModel {
    static func weeklyWorkoutCount(_ sessions: [WorkoutSession], referenceDate: Date = .now) -> Int {
        sessions.filter {
            Calendar.current.isDate($0.date, equalTo: referenceDate, toGranularity: .weekOfYear)
        }.count
    }

    static func weeklyVolumeTrend(_ sessions: [WorkoutSession], referenceDate: Date = .now) -> [WeeklyVolumePoint] {
        let calendar = Calendar.current
        let weekStarts = (0..<6).compactMap {
            calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: -$0, to: referenceDate) ?? referenceDate)?.start
        }.reversed()

        return weekStarts.map { weekStart in
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let volume = sessions
                .filter { $0.date >= weekStart && $0.date < weekEnd }
                .flatMap(\.completedExercises)
                .flatMap(\.sets)
                .reduce(0) { $0 + $1.volume }

            return WeeklyVolumePoint(weekStart: weekStart, volume: volume)
        }
    }

    static func bestLifts(_ sessions: [WorkoutSession]) -> [BestLift] {
        var bestByExercise: [String: Double] = [:]

        for exercise in sessions.flatMap(\.completedExercises) {
            let bestWeight = exercise.sets.map(\.weight).max() ?? 0
            bestByExercise[exercise.exerciseName] = max(bestByExercise[exercise.exerciseName] ?? 0, bestWeight)
        }

        return bestByExercise
            .map { BestLift(exerciseName: $0.key, weight: $0.value) }
            .sorted { $0.weight > $1.weight }
            .prefix(5)
            .map { $0 }
    }

    static func bodyWeightTrend(_ measurements: [BodyMeasurement]) -> [BodyWeightPoint] {
        measurements
            .sorted { $0.date < $1.date }
            .suffix(12)
            .map { BodyWeightPoint(date: $0.date, weight: $0.weight) }
    }

    static func encouragementCards(
        sessions: [WorkoutSession],
        measurements: [BodyMeasurement]
    ) -> [String] {
        var cards: [String] = []
        let weeklyCount = weeklyWorkoutCount(sessions)

        if weeklyCount > 0 {
            cards.append("You trained \(weeklyCount) time\(weeklyCount == 1 ? "" : "s") this week. That is the habit that compounds.")
        }

        let trend = weeklyVolumeTrend(sessions)
        if let first = trend.first?.volume, let last = trend.last?.volume, first > 0, last > first {
            let increase = ((last - first) / first) * 100
            cards.append("Your training volume is up \(increase.formatted(.number.precision(.fractionLength(0))))% across the recent trend.")
        }

        if measurements.count >= 2,
           let first = measurements.sorted(by: { $0.date < $1.date }).first,
           let last = measurements.sorted(by: { $0.date < $1.date }).last,
           last.arm > first.arm {
            cards.append("Your arm measurement increased while training stayed consistent.")
        }

        if cards.isEmpty {
            cards.append("Log a few workouts and CoachLog will start finding useful progress signals.")
        }

        return cards
    }
}

