import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var primaryMuscleGroupRaw: String
    var secondaryMuscleGroupsStorage: String
    var equipmentRaw: String
    var isKneeFriendly: Bool
    var isShoulderFriendly: Bool

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscleGroup: MuscleGroup,
        secondaryMuscleGroups: [MuscleGroup] = [],
        equipment: Equipment,
        isKneeFriendly: Bool,
        isShoulderFriendly: Bool
    ) {
        self.id = id
        self.name = name
        self.primaryMuscleGroupRaw = primaryMuscleGroup.rawValue
        self.secondaryMuscleGroupsStorage = secondaryMuscleGroups.map(\.rawValue).joined(separator: ",")
        self.equipmentRaw = equipment.rawValue
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
}

extension Exercise {
    convenience init(definition: ExerciseDefinition) {
        self.init(
            name: definition.name,
            primaryMuscleGroup: definition.primaryMuscleGroup,
            secondaryMuscleGroups: definition.secondaryMuscleGroups,
            equipment: definition.equipment,
            isKneeFriendly: definition.isKneeFriendly,
            isShoulderFriendly: definition.isShoulderFriendly
        )
    }
}

