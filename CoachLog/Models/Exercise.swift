import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var primaryMuscleGroupRaw: String
    var secondaryMuscleGroupsStorage: String
    var equipmentRaw: String
    var stationRaw: String = GymStation.bodyweight.rawValue
    var primaryDetailedMuscleRaw: String = DetailedMuscleGroup.rectusAbdominis.rawValue
    var secondaryDetailedMuscleRaw: String?
    var kindRaw: String = ExerciseKind.strength.rawValue
    var isCustom: Bool = false
    var isKneeFriendly: Bool
    var isShoulderFriendly: Bool

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscleGroup: MuscleGroup,
        secondaryMuscleGroups: [MuscleGroup] = [],
        equipment: Equipment,
        station: GymStation = .bodyweight,
        primaryDetailedMuscle: DetailedMuscleGroup? = nil,
        secondaryDetailedMuscle: DetailedMuscleGroup? = nil,
        kind: ExerciseKind = .strength,
        isCustom: Bool = false,
        isKneeFriendly: Bool,
        isShoulderFriendly: Bool
    ) {
        let detailedDefaults = DetailedMuscleGroup.defaults(primary: primaryMuscleGroup, secondary: secondaryMuscleGroups)

        self.id = id
        self.name = name
        self.primaryMuscleGroupRaw = primaryMuscleGroup.rawValue
        self.secondaryMuscleGroupsStorage = secondaryMuscleGroups.map(\.rawValue).joined(separator: ",")
        self.equipmentRaw = equipment.rawValue
        self.stationRaw = station.rawValue
        self.primaryDetailedMuscleRaw = (primaryDetailedMuscle ?? detailedDefaults[0]).rawValue
        self.secondaryDetailedMuscleRaw = secondaryDetailedMuscle?.rawValue ?? detailedDefaults.dropFirst().first?.rawValue
        self.kindRaw = kind.rawValue
        self.isCustom = isCustom
        self.isKneeFriendly = isKneeFriendly
        self.isShoulderFriendly = isShoulderFriendly
    }

    var primaryMuscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: primaryMuscleGroupRaw) ?? .core }
        set { primaryMuscleGroupRaw = newValue.rawValue }
    }

    var secondaryMuscleGroups: [MuscleGroup] {
        get {
            secondaryMuscleGroupsStorage
                .split(separator: ",")
                .compactMap { MuscleGroup(rawValue: String($0)) }
        }
        set {
            secondaryMuscleGroupsStorage = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .bodyweight }
        set { equipmentRaw = newValue.rawValue }
    }

    var station: GymStation {
        get { GymStation(rawValue: stationRaw) ?? .bodyweight }
        set { stationRaw = newValue.rawValue }
    }

    var primaryDetailedMuscle: DetailedMuscleGroup {
        get { DetailedMuscleGroup(rawValue: primaryDetailedMuscleRaw) ?? DetailedMuscleGroup.defaults(for: primaryMuscleGroup)[0] }
        set { primaryDetailedMuscleRaw = newValue.rawValue }
    }

    var secondaryDetailedMuscle: DetailedMuscleGroup? {
        get {
            guard let secondaryDetailedMuscleRaw else { return nil }
            return DetailedMuscleGroup(rawValue: secondaryDetailedMuscleRaw)
        }
        set { secondaryDetailedMuscleRaw = newValue?.rawValue }
    }

    var kind: ExerciseKind {
        get { ExerciseKind(rawValue: kindRaw) ?? .strength }
        set { kindRaw = newValue.rawValue }
    }

    var detailedMuscles: [DetailedMuscleGroup] {
        var muscles = [primaryDetailedMuscle]

        if let secondaryDetailedMuscle, secondaryDetailedMuscle != primaryDetailedMuscle {
            muscles.append(secondaryDetailedMuscle)
        }

        return muscles
    }
}

extension Exercise {
    convenience init(definition: ExerciseDefinition) {
        self.init(
            name: definition.name,
            primaryMuscleGroup: definition.primaryMuscleGroup,
            secondaryMuscleGroups: definition.secondaryMuscleGroups,
            equipment: definition.equipment,
            station: definition.station,
            primaryDetailedMuscle: definition.primaryDetailedMuscle,
            secondaryDetailedMuscle: definition.secondaryDetailedMuscle,
            kind: definition.kind,
            isCustom: false,
            isKneeFriendly: definition.isKneeFriendly,
            isShoulderFriendly: definition.isShoulderFriendly
        )
    }

    func apply(definition: ExerciseDefinition) {
        primaryMuscleGroup = definition.primaryMuscleGroup
        secondaryMuscleGroups = definition.secondaryMuscleGroups
        equipment = definition.equipment
        station = definition.station
        primaryDetailedMuscle = definition.primaryDetailedMuscle
        secondaryDetailedMuscle = definition.secondaryDetailedMuscle
        kind = definition.kind
        isCustom = false
        isKneeFriendly = definition.isKneeFriendly
        isShoulderFriendly = definition.isShoulderFriendly
    }
}
