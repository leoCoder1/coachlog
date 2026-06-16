import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weight: Double
    var waist: Double
    var chest: Double
    var arm: Double
    var thigh: Double

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weight: Double,
        waist: Double,
        chest: Double,
        arm: Double,
        thigh: Double
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.waist = waist
        self.chest = chest
        self.arm = arm
        self.thigh = thigh
    }
}

