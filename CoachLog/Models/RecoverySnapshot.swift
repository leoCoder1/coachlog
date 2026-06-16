import Foundation
import SwiftData

@Model
final class RecoverySnapshot {
    @Attribute(.unique) var id: UUID
    var date: Date
    var sleepHours: Double
    var restingHeartRate: Double
    var hrv: Double
    var readinessScore: Int

    init(
        id: UUID = UUID(),
        date: Date = .now,
        sleepHours: Double,
        restingHeartRate: Double,
        hrv: Double,
        readinessScore: Int
    ) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.restingHeartRate = restingHeartRate
        self.hrv = hrv
        self.readinessScore = readinessScore
    }

    static var mock: RecoverySnapshot {
        RecoverySnapshot(
            sleepHours: 7.2,
            restingHeartRate: 58,
            hrv: 62,
            readinessScore: 78
        )
    }
}

