import Foundation
import SwiftData

@Model
final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    var weight: Double
    var reps: Int
    var rir: Int
    var timestamp: Date

    init(
        id: UUID = UUID(),
        weight: Double,
        reps: Int,
        rir: Int,
        timestamp: Date = .now
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.rir = rir
        self.timestamp = timestamp
    }

    var volume: Double {
        weight * Double(reps)
    }
}

