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
}

