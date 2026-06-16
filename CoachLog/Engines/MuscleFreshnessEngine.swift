import Foundation

struct WeeklyMuscleLoad: Identifiable, Hashable {
    var id: MuscleGroup { group }
    var group: MuscleGroup
    var setCount: Int
    var exerciseCount: Int
    var sessionCount: Int
    var lastTrainingDate: Date?

    var hasWork: Bool {
        setCount > 0
    }

    var setText: String {
        "\(setCount) set\(setCount == 1 ? "" : "s")"
    }

    static func empty(for group: MuscleGroup) -> WeeklyMuscleLoad {
        WeeklyMuscleLoad(
            group: group,
            setCount: 0,
            exerciseCount: 0,
            sessionCount: 0,
            lastTrainingDate: nil
        )
    }
}

final class MuscleFreshnessEngine {
    func statuses(
        from sessions: [WorkoutSession],
        pain: PainFlag,
        referenceDate: Date = .now
    ) -> [MuscleGroup: MuscleFreshnessResult] {
        var latestTrainingDateByGroup: [MuscleGroup: Date] = [:]

        for session in sessions {
            for exercise in session.completedExercises {
                for group in affectedGroups(for: exercise) {
                    if let existing = latestTrainingDateByGroup[group] {
                        latestTrainingDateByGroup[group] = max(existing, session.date)
                    } else {
                        latestTrainingDateByGroup[group] = session.date
                    }
                }
            }
        }

        return MuscleGroup.dashboardGroups.reduce(into: [:]) { results, group in
            if pain.cautionMuscleGroups.contains(group) {
                results[group] = MuscleFreshnessResult(
                    group: group,
                    status: .caution,
                    daysSinceTraining: latestTrainingDateByGroup[group].map { daysBetween($0, referenceDate) },
                    note: "Pain flag is related to this area."
                )
                return
            }

            guard let latestDate = latestTrainingDateByGroup[group] else {
                results[group] = MuscleFreshnessResult(
                    group: group,
                    status: .due,
                    daysSinceTraining: nil,
                    note: "No recent work logged."
                )
                return
            }

            let hoursSinceTraining = referenceDate.timeIntervalSince(latestDate) / 3600
            let daysSinceTraining = daysBetween(latestDate, referenceDate)

            if hoursSinceTraining < 48 {
                results[group] = MuscleFreshnessResult(
                    group: group,
                    status: .recovering,
                    daysSinceTraining: daysSinceTraining,
                    note: "Trained in the last 48 hours."
                )
            } else if daysSinceTraining >= 4 {
                results[group] = MuscleFreshnessResult(
                    group: group,
                    status: .due,
                    daysSinceTraining: daysSinceTraining,
                    note: "Four or more days since direct work."
                )
            } else {
                results[group] = MuscleFreshnessResult(
                    group: group,
                    status: .ready,
                    daysSinceTraining: daysSinceTraining,
                    note: "Two to three days since direct work."
                )
            }
        }
    }

    func weeklyLoads(
        from sessions: [WorkoutSession],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [MuscleGroup: WeeklyMuscleLoad] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return emptyWeeklyLoads()
        }

        var setCounts: [MuscleGroup: Int] = [:]
        var exerciseCounts: [MuscleGroup: Int] = [:]
        var sessionIDs: [MuscleGroup: Set<UUID>] = [:]
        var lastTrainingDates: [MuscleGroup: Date] = [:]

        for session in sessions where week.contains(session.date) {
            for exercise in session.completedExercises {
                for group in affectedGroups(for: exercise) {
                    setCounts[group, default: 0] += exercise.sets.count
                    exerciseCounts[group, default: 0] += 1
                    sessionIDs[group, default: []].insert(session.id)

                    if let existing = lastTrainingDates[group] {
                        lastTrainingDates[group] = max(existing, session.date)
                    } else {
                        lastTrainingDates[group] = session.date
                    }
                }
            }
        }

        return MuscleGroup.dashboardGroups.reduce(into: [:]) { result, group in
            result[group] = WeeklyMuscleLoad(
                group: group,
                setCount: setCounts[group, default: 0],
                exerciseCount: exerciseCounts[group, default: 0],
                sessionCount: sessionIDs[group]?.count ?? 0,
                lastTrainingDate: lastTrainingDates[group]
            )
        }
    }

    func weeklyLoggedSetCount(
        from sessions: [WorkoutSession],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return 0
        }

        return sessions
            .filter { week.contains($0.date) }
            .flatMap(\.completedExercises)
            .flatMap(\.sets)
            .count
    }

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return max(0, calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0)
    }

    private func affectedGroups(for exercise: CompletedExercise) -> [MuscleGroup] {
        var groups = [exercise.muscleGroup]

        if let definition = ExerciseLibrary.definitions.first(where: { $0.name == exercise.exerciseName }) {
            for group in definition.secondaryMuscleGroups where !groups.contains(group) {
                groups.append(group)
            }
        }

        return groups
    }

    private func emptyWeeklyLoads() -> [MuscleGroup: WeeklyMuscleLoad] {
        MuscleGroup.dashboardGroups.reduce(into: [:]) { result, group in
            result[group] = WeeklyMuscleLoad.empty(for: group)
        }
    }
}
