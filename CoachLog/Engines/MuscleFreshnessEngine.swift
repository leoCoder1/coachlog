import Foundation

final class MuscleFreshnessEngine {
    func statuses(
        from sessions: [WorkoutSession],
        pain: PainFlag,
        referenceDate: Date = .now
    ) -> [MuscleGroup: MuscleFreshnessResult] {
        var latestTrainingDateByGroup: [MuscleGroup: Date] = [:]

        for session in sessions {
            for exercise in session.completedExercises {
                let group = exercise.muscleGroup
                if let existing = latestTrainingDateByGroup[group] {
                    latestTrainingDateByGroup[group] = max(existing, session.date)
                } else {
                    latestTrainingDateByGroup[group] = session.date
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
            let daysSinceTraining = max(0, Int(hoursSinceTraining / 24))

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

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0)
    }
}

