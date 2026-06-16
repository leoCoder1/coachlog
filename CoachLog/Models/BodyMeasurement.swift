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
    var neck: Double?
    var shoulders: Double?
    var abdomen: Double?
    var hip: Double?
    var calf: Double?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weight: Double,
        waist: Double,
        chest: Double,
        arm: Double,
        thigh: Double,
        neck: Double? = nil,
        shoulders: Double? = nil,
        abdomen: Double? = nil,
        hip: Double? = nil,
        calf: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.waist = waist
        self.chest = chest
        self.arm = arm
        self.thigh = thigh
        self.neck = neck
        self.shoulders = shoulders
        self.abdomen = abdomen
        self.hip = hip
        self.calf = calf
    }
}
