import Foundation

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case core = "Core"

    var id: String { rawValue }

    static let dashboardGroups: [MuscleGroup] = [
        .chest,
        .back,
        .legs,
        .shoulders,
        .biceps,
        .triceps,
        .core
    ]

    var iconName: String {
        switch self {
        case .chest: "figure.strengthtraining.traditional"
        case .back: "figure.rower"
        case .legs: "figure.walk"
        case .shoulders: "figure.arms.open"
        case .biceps: "dumbbell"
        case .triceps: "bolt"
        case .core: "figure.core.training"
        }
    }
}

enum Equipment: String, CaseIterable, Codable, Identifiable {
    case bodyweight = "Bodyweight"
    case dumbbell = "Dumbbell"
    case cable = "Cable"
    case machine = "Machine"

    var id: String { rawValue }
}

enum EnergyLevel: String, CaseIterable, Codable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        }
    }
}

enum PainFlag: String, CaseIterable, Codable, Identifiable {
    case none
    case knee
    case shoulder
    case back
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "None"
        case .knee: "Knee"
        case .shoulder: "Shoulder"
        case .back: "Back"
        case .other: "Other"
        }
    }

    var cautionMuscleGroups: Set<MuscleGroup> {
        switch self {
        case .none:
            []
        case .knee:
            [.legs]
        case .shoulder:
            [.chest, .shoulders, .triceps]
        case .back:
            [.back, .legs]
        case .other:
            []
        }
    }
}

enum AvailableMinutes: Int, CaseIterable, Codable, Identifiable {
    case twenty = 20
    case forty = 40
    case sixty = 60

    var id: Int { rawValue }

    var displayName: String { "\(rawValue) min" }

    var exerciseCount: Int {
        switch self {
        case .twenty: 3
        case .forty: 5
        case .sixty: 7
        }
    }
}

enum FitnessGoal: String, CaseIterable, Codable, Identifiable {
    case buildMuscle
    case fatLoss
    case strength
    case generalFitness

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .buildMuscle: "Build Muscle"
        case .fatLoss: "Fat Loss"
        case .strength: "Strength"
        case .generalFitness: "General Fitness"
        }
    }
}

enum FreshnessStatus: String, CaseIterable, Codable, Identifiable {
    case ready = "Ready"
    case recovering = "Recovering"
    case due = "Due"
    case caution = "Caution"

    var id: String { rawValue }
}

