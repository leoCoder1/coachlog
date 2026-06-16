import Foundation
import SwiftData

enum DataSeeder {
    @MainActor
    static func seedExercisesIfNeeded(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        ExerciseLibrary.definitions
            .map(Exercise.init(definition:))
            .forEach(modelContext.insert)

        try? modelContext.save()
    }

    @MainActor
    @discardableResult
    static func seedDemoHistoryIfNeeded(in modelContext: ModelContext) -> Bool {
        var didInsert = false

        didInsert = insertMissingDemoSessions(in: modelContext) || didInsert
        didInsert = insertMissingDemoMeasurements(in: modelContext) || didInsert
        didInsert = insertMissingDemoRecoverySnapshots(in: modelContext) || didInsert
        didInsert = insertMissingDemoBaselines(in: modelContext) || didInsert

        if didInsert {
            try? modelContext.save()
        }

        return didInsert
    }

    @MainActor
    private static func insertMissingDemoSessions(in modelContext: ModelContext) -> Bool {
        let existingIDs = Set(((try? modelContext.fetch(FetchDescriptor<WorkoutSession>())) ?? []).map(\.id))
        var inserted = false

        for session in demoSessions where !existingIDs.contains(session.id) {
            modelContext.insert(session)
            inserted = true
        }

        return inserted
    }

    @MainActor
    private static func insertMissingDemoMeasurements(in modelContext: ModelContext) -> Bool {
        let existingMeasurements = (try? modelContext.fetch(FetchDescriptor<BodyMeasurement>())) ?? []
        var existingByID = Dictionary(uniqueKeysWithValues: existingMeasurements.map { ($0.id, $0) })
        var changed = false

        for measurement in demoMeasurements {
            if let existing = existingByID[measurement.id] {
                changed = backfillExtendedMeasurementFields(existing, from: measurement) || changed
            } else {
                modelContext.insert(measurement)
                existingByID[measurement.id] = measurement
                changed = true
            }
        }

        return changed
    }

    @MainActor
    private static func insertMissingDemoRecoverySnapshots(in modelContext: ModelContext) -> Bool {
        let existingIDs = Set(((try? modelContext.fetch(FetchDescriptor<RecoverySnapshot>())) ?? []).map(\.id))
        var inserted = false

        for snapshot in demoRecoverySnapshots where !existingIDs.contains(snapshot.id) {
            modelContext.insert(snapshot)
            inserted = true
        }

        return inserted
    }

    @MainActor
    private static func insertMissingDemoBaselines(in modelContext: ModelContext) -> Bool {
        let existingIDs = Set(((try? modelContext.fetch(FetchDescriptor<StrengthBaselineTest>())) ?? []).map(\.id))
        var inserted = false

        for baseline in demoBaselines where !existingIDs.contains(baseline.id) {
            modelContext.insert(baseline)
            inserted = true
        }

        return inserted
    }

    private static var demoSessions: [WorkoutSession] {
        [
            workout(
                id: "7B6B89AC-0E96-4ED2-9DA4-70229D8FF201",
                daysAgo: 1,
                duration: 42,
                energy: .normal,
                goal: .buildMuscle,
                exercises: [
                    exercise("Dumbbell Bench Press", .chest, [(55, 10, 2), (55, 9, 2), (55, 8, 1)]),
                    exercise("Incline Dumbbell Bench Press", .chest, [(32.5, 11, 2), (32.5, 10, 2)]),
                    exercise("Triceps Pressdown", .triceps, [(35, 12, 2), (35, 11, 2)])
                ]
            ),
            workout(
                id: "0B0C477B-0866-495A-A928-681BC25099DD",
                daysAgo: 3,
                duration: 45,
                energy: .high,
                goal: .strength,
                exercises: [
                    exercise("Lat Pulldown", .back, [(95, 10, 2), (95, 9, 2), (90, 10, 2)]),
                    exercise("Bent Over Barbell Row", .back, [(75, 10, 2), (75, 9, 1)]),
                    exercise("Biceps Curl", .biceps, [(25, 12, 2), (25, 11, 2)])
                ]
            ),
            workout(
                id: "3392825F-5876-462D-817D-F31653D75B28",
                daysAgo: 6,
                duration: 39,
                energy: .normal,
                goal: .buildMuscle,
                exercises: [
                    exercise("Goblet Squat", .legs, [(45, 12, 2), (45, 11, 2), (45, 10, 1)]),
                    exercise("Romanian Deadlift", .legs, [(115, 8, 2), (115, 8, 1), (105, 10, 2)]),
                    exercise("Plank", .core, [(0, 45, 2), (0, 40, 2)])
                ]
            ),
            workout(
                id: "D432C28C-3295-45A0-9C4C-4B47F446669A",
                daysAgo: 10,
                duration: 35,
                energy: .low,
                goal: .generalFitness,
                exercises: [
                    exercise("Push-ups", .chest, [(0, 14, 2), (0, 12, 2), (0, 10, 1)]),
                    exercise("Lat Pulldown", .back, [(90, 10, 2), (90, 9, 2)]),
                    exercise("Biceps Curl", .biceps, [(22.5, 12, 2), (22.5, 10, 2)])
                ]
            ),
            workout(
                id: "3C7CBFD5-EE7D-43E4-B1CF-C5A8A0655B43",
                daysAgo: 17,
                duration: 51,
                energy: .normal,
                goal: .strength,
                exercises: [
                    exercise("Dumbbell Bench Press", .chest, [(50, 10, 2), (50, 9, 2), (50, 8, 1)]),
                    exercise("Goblet Squat", .legs, [(40, 12, 2), (40, 12, 2), (40, 10, 1)]),
                    exercise("Triceps Pressdown", .triceps, [(30, 12, 2), (30, 11, 2)])
                ]
            ),
            workout(
                id: "586BD1F5-D833-44E0-B203-117011873690",
                daysAgo: 24,
                duration: 44,
                energy: .normal,
                goal: .buildMuscle,
                exercises: [
                    exercise("Lat Pulldown", .back, [(85, 11, 2), (85, 10, 2), (85, 9, 1)]),
                    exercise("Romanian Deadlift", .legs, [(105, 8, 2), (105, 8, 2)]),
                    exercise("Dumbbell Bench Press", .chest, [(47.5, 10, 2), (47.5, 9, 2)])
                ]
            )
        ]
    }

    private static var demoMeasurements: [BodyMeasurement] {
        [
            measurement("F0809FF4-388C-42BB-B906-D0A733259201", daysAgo: 42, weight: 184.0, waist: 35.0, chest: 39.5, arm: 13.75, thigh: 21.5, neck: 15.6, shoulders: 42.0, abdomen: 37.2, hip: 41.2, calf: 14.0),
            measurement("5CA9C215-10F5-438F-AD15-F6ED35AE9C12", daysAgo: 35, weight: 183.0, waist: 34.8, chest: 39.8, arm: 13.9, thigh: 21.7, neck: 15.6, shoulders: 42.2, abdomen: 36.8, hip: 41.0, calf: 14.1),
            measurement("6E8114E0-7C50-4F6D-BB44-BB354CC8132C", daysAgo: 28, weight: 182.4, waist: 34.6, chest: 40.0, arm: 14.0, thigh: 21.9, neck: 15.5, shoulders: 42.5, abdomen: 36.4, hip: 40.8, calf: 14.1),
            measurement("E53CC749-073D-48DA-BB46-2CD6B555CC76", daysAgo: 21, weight: 181.8, waist: 34.4, chest: 40.2, arm: 14.1, thigh: 22.0, neck: 15.4, shoulders: 42.8, abdomen: 36.0, hip: 40.7, calf: 14.2),
            measurement("C32283EC-D8C6-4B7C-B2A2-56698B9310AE", daysAgo: 14, weight: 181.1, waist: 34.2, chest: 40.3, arm: 14.2, thigh: 22.1, neck: 15.4, shoulders: 43.0, abdomen: 35.7, hip: 40.5, calf: 14.2),
            measurement("7D2C8461-05FA-41EB-B996-3BD2E897156C", daysAgo: 2, weight: 180.5, waist: 34.0, chest: 40.5, arm: 14.25, thigh: 22.25, neck: 15.3, shoulders: 43.3, abdomen: 35.3, hip: 40.3, calf: 14.25)
        ]
    }

    private static var demoRecoverySnapshots: [RecoverySnapshot] {
        [
            RecoverySnapshot(
                id: uuid("21C3FC6F-D63A-43B7-A89C-4D6784965811"),
                date: daysAgo(2, hour: 7),
                sleepHours: 6.8,
                restingHeartRate: 61,
                hrv: 54,
                readinessScore: 70
            ),
            RecoverySnapshot(
                id: uuid("D7D55145-B1EF-4E4B-94AE-F86F5321489C"),
                date: daysAgo(1, hour: 7),
                sleepHours: 7.5,
                restingHeartRate: 58,
                hrv: 63,
                readinessScore: 82
            )
        ]
    }

    private static var demoBaselines: [StrengthBaselineTest] {
        [
            baseline("998BC69D-3D5C-47C2-B6DF-92D1C3EEB001", "Dumbbell Bench Press", daysAgo: 56, weight: 45, reps: 8),
            baseline("60BC7D48-7E8D-41F1-8D8D-629029E9B002", "Dumbbell Bench Press", daysAgo: 7, weight: 55, reps: 8),
            baseline("E1114C7B-15C3-4D48-8995-32DC29C3B003", "Lat Pulldown", daysAgo: 50, weight: 80, reps: 8),
            baseline("3F707583-74F9-4C44-B47B-9EC5E1B9B004", "Lat Pulldown", daysAgo: 12, weight: 95, reps: 8),
            baseline("24910246-19B6-4742-A728-B6C68499B005", "Goblet Squat", daysAgo: 65, weight: 35, reps: 10),
            baseline("F9A9953A-7F16-4384-A708-665C9683B006", "Goblet Squat", daysAgo: 34, weight: 45, reps: 10),
            baseline("50D0FC10-F462-43D0-A55D-B8CB4AF5B007", "Romanian Deadlift", daysAgo: 60, weight: 95, reps: 6),
            baseline("43ED39B7-64DE-4B75-A6DF-25B1BE57B008", "Romanian Deadlift", daysAgo: 5, weight: 115, reps: 6)
        ]
    }

    private static func workout(
        id: String,
        daysAgo: Int,
        duration: Int,
        energy: EnergyLevel,
        goal: FitnessGoal,
        exercises: [CompletedExercise]
    ) -> WorkoutSession {
        WorkoutSession(
            id: uuid(id),
            date: self.daysAgo(daysAgo),
            duration: TimeInterval(duration * 60),
            energyLevel: energy,
            painFlag: .none,
            availableMinutes: .forty,
            goal: goal,
            completedExercises: exercises
        )
    }

    private static func exercise(
        _ name: String,
        _ group: MuscleGroup,
        _ setValues: [(Double, Int, Int)]
    ) -> CompletedExercise {
        CompletedExercise(
            exerciseName: name,
            muscleGroup: group,
            sets: setValues.enumerated().map { index, value in
                WorkoutSet(
                    weight: value.0,
                    reps: value.1,
                    rir: value.2,
                    timestamp: Date().addingTimeInterval(TimeInterval(index * 180))
                )
            }
        )
    }

    private static func measurement(
        _ id: String,
        daysAgo: Int,
        weight: Double,
        waist: Double,
        chest: Double,
        arm: Double,
        thigh: Double,
        neck: Double,
        shoulders: Double,
        abdomen: Double,
        hip: Double,
        calf: Double
    ) -> BodyMeasurement {
        BodyMeasurement(
            id: uuid(id),
            date: self.daysAgo(daysAgo, hour: 8),
            weight: weight,
            waist: waist,
            chest: chest,
            arm: arm,
            thigh: thigh,
            neck: neck,
            shoulders: shoulders,
            abdomen: abdomen,
            hip: hip,
            calf: calf
        )
    }

    private static func backfillExtendedMeasurementFields(_ existing: BodyMeasurement, from demo: BodyMeasurement) -> Bool {
        var changed = false

        if existing.neck == nil {
            existing.neck = demo.neck
            changed = true
        }
        if existing.shoulders == nil {
            existing.shoulders = demo.shoulders
            changed = true
        }
        if existing.abdomen == nil {
            existing.abdomen = demo.abdomen
            changed = true
        }
        if existing.hip == nil {
            existing.hip = demo.hip
            changed = true
        }
        if existing.calf == nil {
            existing.calf = demo.calf
            changed = true
        }

        return changed
    }

    private static func baseline(
        _ id: String,
        _ exerciseName: String,
        daysAgo: Int,
        weight: Double,
        reps: Int
    ) -> StrengthBaselineTest {
        StrengthBaselineTest(
            id: uuid(id),
            exerciseName: exerciseName,
            date: self.daysAgo(daysAgo, hour: 9),
            weight: weight,
            reps: reps
        )
    }

    private static func daysAgo(_ days: Int, hour: Int = 18) -> Date {
        let calendar = Calendar.current
        let shiftedDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var components = calendar.dateComponents([.year, .month, .day], from: shiftedDate)
        components.hour = hour
        components.minute = 30
        return calendar.date(from: components) ?? shiftedDate
    }

    private static func uuid(_ string: String) -> UUID {
        UUID(uuidString: string) ?? UUID()
    }
}
