import Foundation

enum UnitPreferenceKeys {
    static let weightUnit = "coachlog.weightUnit"
    static let lengthUnit = "coachlog.lengthUnit"
}

enum SportPreferenceKeys {
    static let defaultSport = "coachlog.defaultSport"
}

enum CoachSport: String, CaseIterable, Codable, Identifiable {
    case cricket
    case baseball
    case soccer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cricket: "Cricket"
        case .baseball: "Baseball"
        case .soccer: "Soccer"
        }
    }

    var iconName: String {
        switch self {
        case .cricket: "figure.cricket"
        case .baseball: "baseball"
        case .soccer: "soccerball"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .cricket: true
        case .baseball, .soccer: false
        }
    }

    static var currentDefault: CoachSport {
        CoachSport(rawValue: UserDefaults.standard.string(forKey: SportPreferenceKeys.defaultSport) ?? "") ?? .cricket
    }
}

enum WeightUnitPreference: String, CaseIterable, Codable, Identifiable {
    case pounds
    case kilograms

    private static let poundsPerKilogram = 2.2046226218

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pounds: "Pounds"
        case .kilograms: "Kilograms"
        }
    }

    var unitLabel: String {
        switch self {
        case .pounds: "lb"
        case .kilograms: "kg"
        }
    }

    var workoutStep: Double {
        switch self {
        case .pounds: 2.5
        case .kilograms: 1.0
        }
    }

    var bodyWeightStep: Double {
        switch self {
        case .pounds: 0.5
        case .kilograms: 0.5
        }
    }

    static var current: WeightUnitPreference {
        WeightUnitPreference(rawValue: UserDefaults.standard.string(forKey: UnitPreferenceKeys.weightUnit) ?? "") ?? .pounds
    }

    func displayWeight(fromPounds pounds: Double) -> Double {
        switch self {
        case .pounds:
            pounds
        case .kilograms:
            pounds / Self.poundsPerKilogram
        }
    }

    func pounds(fromDisplayWeight value: Double) -> Double {
        switch self {
        case .pounds:
            value
        case .kilograms:
            value * Self.poundsPerKilogram
        }
    }

    func roundedDisplayWeight(fromPounds pounds: Double, step: Double? = nil) -> Double {
        let step = step ?? workoutStep
        return rounded(displayWeight(fromPounds: pounds), step: step)
    }

    func displayWeightValues(
        fromPoundsRange range: ClosedRange<Double>,
        step: Double? = nil
    ) -> [Double] {
        let step = step ?? workoutStep
        let lower = (displayWeight(fromPounds: range.lowerBound) / step).rounded(.up) * step
        let upper = (displayWeight(fromPounds: range.upperBound) / step).rounded(.down) * step
        return steppedValues(from: lower, through: upper, by: step)
    }

    func formattedWeight(
        _ pounds: Double,
        fractionLength: ClosedRange<Int> = 0...1
    ) -> String {
        let value = displayWeight(fromPounds: pounds)
        return "\(value.formatted(.number.precision(.fractionLength(fractionLength)))) \(unitLabel)"
    }
}

enum LengthUnitPreference: String, CaseIterable, Codable, Identifiable {
    case inches
    case centimeters

    private static let centimetersPerInch = 2.54

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inches: "Inches"
        case .centimeters: "Centimeters"
        }
    }

    var unitLabel: String {
        switch self {
        case .inches: "in"
        case .centimeters: "cm"
        }
    }

    var step: Double {
        switch self {
        case .inches: 0.25
        case .centimeters: 0.5
        }
    }

    static var current: LengthUnitPreference {
        LengthUnitPreference(rawValue: UserDefaults.standard.string(forKey: UnitPreferenceKeys.lengthUnit) ?? "") ?? .inches
    }

    func displayLength(fromInches inches: Double) -> Double {
        switch self {
        case .inches:
            inches
        case .centimeters:
            inches * Self.centimetersPerInch
        }
    }

    func inches(fromDisplayLength value: Double) -> Double {
        switch self {
        case .inches:
            value
        case .centimeters:
            value / Self.centimetersPerInch
        }
    }

    func roundedDisplayLength(fromInches inches: Double) -> Double {
        rounded(displayLength(fromInches: inches), step: step)
    }

    func displayLengthValues(fromInchesRange range: ClosedRange<Double>) -> [Double] {
        let lower = (displayLength(fromInches: range.lowerBound) / step).rounded(.up) * step
        let upper = (displayLength(fromInches: range.upperBound) / step).rounded(.down) * step
        return steppedValues(from: lower, through: upper, by: step)
    }

    func formattedLength(
        _ inches: Double,
        fractionLength: ClosedRange<Int> = 0...1
    ) -> String {
        let value = displayLength(fromInches: inches)
        return "\(value.formatted(.number.precision(.fractionLength(fractionLength)))) \(unitLabel)"
    }
}

private func steppedValues(from lowerBound: Double, through upperBound: Double, by step: Double) -> [Double] {
    guard step > 0, lowerBound <= upperBound else { return [] }

    var values: [Double] = []
    var current = lowerBound

    while current <= upperBound + (step / 2) {
        values.append(rounded(current, step: 0.01))
        current += step
    }

    return values
}

private func rounded(_ value: Double, step: Double) -> Double {
    guard step > 0 else { return value }
    return ((value / step).rounded() * step * 100).rounded() / 100
}

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case glutes = "Glutes"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case core = "Core"

    var id: String { rawValue }

    static let dashboardGroups: [MuscleGroup] = [
        .chest,
        .back,
        .legs,
        .glutes,
        .shoulders,
        .biceps,
        .triceps,
        .core
    ]

    var iconName: String {
        switch self {
        case .chest: "figure.arms.open"
        case .back: "figure.strengthtraining.traditional"
        case .legs: "figure.walk"
        case .glutes: "figure.stair.stepper"
        case .shoulders: "figure.strengthtraining.functional"
        case .biceps: "dumbbell"
        case .triceps: "figure.strengthtraining.traditional"
        case .core: "figure.core.training"
        }
    }
}

enum DetailedMuscleGroup: String, CaseIterable, Codable, Identifiable {
    case gluteusMaximus = "Gluteus Maximus"
    case gluteusMedius = "Gluteus Medius"
    case gluteusMinimus = "Gluteus Minimus"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case adductors = "Adductors"
    case forearmFlexors = "Forearm Flexors"
    case forearmExtensors = "Forearm Extensors"
    case brachioradialis = "Brachioradialis"
    case upperChest = "Upper Chest"
    case midChest = "Mid Chest"
    case lowerChest = "Lower Chest"
    case latissimusDorsi = "Latissimus Dorsi"
    case upperBack = "Upper Back"
    case lowerBack = "Lower Back"
    case frontDeltoids = "Front Deltoids"
    case sideDeltoids = "Side Deltoids"
    case rearDeltoids = "Rear Deltoids"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case gastrocnemius = "Gastrocnemius"
    case soleus = "Soleus"
    case rectusAbdominis = "Rectus Abdominis"
    case obliques = "Obliques"

    var id: String { rawValue }

    var category: String {
        switch self {
        case .gluteusMaximus, .gluteusMedius, .gluteusMinimus:
            "Glutes"
        case .quadriceps, .hamstrings, .adductors:
            "Thighs"
        case .forearmFlexors, .forearmExtensors, .brachioradialis:
            "Hands & Forearms"
        case .upperChest, .midChest, .lowerChest:
            "Chest"
        case .latissimusDorsi, .upperBack, .lowerBack:
            "Back"
        case .frontDeltoids, .sideDeltoids, .rearDeltoids:
            "Shoulders"
        case .biceps, .triceps:
            "Arms"
        case .gastrocnemius, .soleus:
            "Calves"
        case .rectusAbdominis, .obliques:
            "Core"
        }
    }

    var parentGroup: MuscleGroup {
        switch self {
        case .upperChest, .midChest, .lowerChest:
            .chest
        case .latissimusDorsi, .upperBack, .lowerBack:
            .back
        case .quadriceps, .hamstrings, .adductors,
             .gastrocnemius, .soleus:
            .legs
        case .gluteusMaximus, .gluteusMedius, .gluteusMinimus:
            .glutes
        case .frontDeltoids, .sideDeltoids, .rearDeltoids:
            .shoulders
        case .biceps, .brachioradialis, .forearmFlexors, .forearmExtensors:
            .biceps
        case .triceps:
            .triceps
        case .rectusAbdominis, .obliques:
            .core
        }
    }

    static func defaults(for group: MuscleGroup) -> [DetailedMuscleGroup] {
        switch group {
        case .chest:
            [.upperChest, .midChest, .lowerChest]
        case .back:
            [.latissimusDorsi, .upperBack, .lowerBack]
        case .legs:
            [.quadriceps, .hamstrings, .adductors, .gastrocnemius]
        case .glutes:
            [.gluteusMaximus, .gluteusMedius, .gluteusMinimus]
        case .shoulders:
            [.frontDeltoids, .sideDeltoids, .rearDeltoids]
        case .biceps:
            [.biceps, .brachioradialis, .forearmFlexors]
        case .triceps:
            [.triceps]
        case .core:
            [.rectusAbdominis, .obliques]
        }
    }

    static func defaults(primary: MuscleGroup, secondary: [MuscleGroup]) -> [DetailedMuscleGroup] {
        var muscles = defaults(for: primary)

        for group in secondary {
            for muscle in defaults(for: group) where !muscles.contains(muscle) {
                muscles.append(muscle)
            }
        }

        return muscles
    }
}

enum Equipment: String, CaseIterable, Codable, Identifiable {
    case bodyweight = "Bodyweight"
    case dumbbell = "Dumbbell"
    case cable = "Cable"
    case machine = "Machine"

    var id: String { rawValue }
}

enum ExerciseKind: String, CaseIterable, Codable, Identifiable {
    case strength = "Strength"
    case stretch = "Stretch"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .strength: "dumbbell"
        case .stretch: "figure.flexibility"
        }
    }
}

enum GymStation: String, CaseIterable, Codable, Identifiable {
    case bodyweight = "Bodyweight Area"
    case dumbbellRack = "Dumbbell Rack"
    case adjustableBench = "Adjustable Bench"
    case cableStack = "Cable Stack"
    case latPulldown = "Lat Pulldown"
    case seatedRow = "Seated Row"
    case chestPress = "Chest Press"
    case legPress = "Leg Press"
    case legCurl = "Leg Curl"
    case assistedPullUp = "Assisted Pull-Up"
    case smithMachine = "Smith Machine"
    case mat = "Mat"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .bodyweight: "figure.strengthtraining.traditional"
        case .dumbbellRack: "dumbbell"
        case .adjustableBench: "rectangle.inset.filled.and.person.filled"
        case .cableStack: "cable.connector"
        case .latPulldown: "figure.strengthtraining.functional"
        case .seatedRow: "figure.rower"
        case .chestPress: "figure.strengthtraining.traditional"
        case .legPress: "figure.walk"
        case .legCurl: "figure.flexibility"
        case .assistedPullUp: "figure.pullup"
        case .smithMachine: "square.grid.3x3"
        case .mat: "rectangle.roundedtop"
        }
    }
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
            [.legs, .glutes]
        case .shoulder:
            [.chest, .shoulders, .triceps]
        case .back:
            [.back, .legs, .glutes]
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

enum WorkoutWeekday: String, CaseIterable, Codable, Identifiable, Hashable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        case .sunday: "Sun"
        }
    }

    var calendarWeekday: Int {
        switch self {
        case .sunday: 1
        case .monday: 2
        case .tuesday: 3
        case .wednesday: 4
        case .thursday: 5
        case .friday: 6
        case .saturday: 7
        }
    }

    static func today(calendar: Calendar = .current, date: Date = .now) -> WorkoutWeekday {
        let weekday = calendar.component(.weekday, from: date)
        return allCases.first { $0.calendarWeekday == weekday } ?? .monday
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
