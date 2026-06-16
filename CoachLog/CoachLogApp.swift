import SwiftData
import SwiftUI

@main
struct CoachLogApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutTemplate.self,
            WorkoutTemplateExercise.self,
            WorkoutSession.self,
            CompletedExercise.self,
            WorkoutSet.self,
            BodyMeasurement.self,
            RecoverySnapshot.self,
            StrengthBaselineTest.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create CoachLog SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
