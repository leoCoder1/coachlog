import Foundation

enum SportsProgram: String, CaseIterable, Identifiable {
    case mobility
    case strength

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mobility: "Prep"
        case .strength: "Strength"
        }
    }
}

enum SportsPrepPhase: String, CaseIterable, Identifiable {
    case preGame
    case postGame

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preGame: "Before"
        case .postGame: "After"
        }
    }

    var iconName: String {
        switch self {
        case .preGame: "figure.run"
        case .postGame: "figure.flexibility"
        }
    }
}

enum SportsRoutineDepth: String, CaseIterable, Identifiable {
    case minimum
    case full

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimum: "Minimum"
        case .full: "Full"
        }
    }
}

enum SportsRoutineBucket: String {
    case minimum
    case fullAddOn

    var displayName: String {
        switch self {
        case .minimum: "Minimum"
        case .fullAddOn: "Full add-on"
        }
    }
}

enum CricketRole: String, CaseIterable, Identifiable {
    case allRounder
    case batsman
    case bowler

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .allRounder: "All-round"
        case .batsman: "Batsman"
        case .bowler: "Bowler"
        }
    }
}

struct SportsTrainingPlan: Identifiable, Hashable {
    var id: String {
        [
            sport.rawValue,
            program.rawValue,
            phase?.rawValue ?? "none",
            depth.rawValue,
            role.rawValue
        ].joined(separator: "-")
    }

    var sport: CoachSport
    var program: SportsProgram
    var phase: SportsPrepPhase?
    var depth: SportsRoutineDepth
    var role: CricketRole
    var title: String
    var intent: String
    var blocks: [SportsRoutineBlock]
    var focusAreas: [String]
    var estimatedSeconds: Int

    var totalSeconds: Int {
        if estimatedSeconds > 0 {
            return estimatedSeconds
        }

        return blocks.flatMap(\.items).reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }

    var itemCount: Int {
        blocks.flatMap(\.items).count
    }

    var formattedTotalTime: String {
        let seconds = totalSeconds
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60

        if remainingSeconds == 0 {
            return "\(minutes) min"
        }

        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }

    var availableMinutes: AvailableMinutes {
        switch totalSeconds / 60 {
        case 0...20: .twenty
        case 21...40: .forty
        default: .sixty
        }
    }

    var workoutGoal: FitnessGoal {
        switch program {
        case .mobility: .generalFitness
        case .strength: .strength
        }
    }

    var allItems: [SportsRoutineItem] {
        blocks.flatMap(\.items)
    }

    var workoutPlan: WorkoutPlan {
        let exercises = allItems.map(\.exercise)
        return WorkoutPlan(
            exercises: exercises,
            focusMuscleGroups: Array(Set(exercises.map(\.muscleGroup))).sorted { $0.rawValue < $1.rawValue },
            volumeAdjustmentNote: program == .strength
                ? "Sport strength plan for cricket-specific power and resilience."
                : "Sport mobility routine logged from the Sports tab.",
            weeklyRotationNote: "Sports sessions count toward muscle freshness and weekly load."
        )
    }
}

struct SportsRoutineBlock: Identifiable, Hashable {
    var title: String
    var subtitle: String
    var items: [SportsRoutineItem]

    var id: String { title }
}

struct SportsRoutineItem: Identifiable, Hashable {
    var exercise: PlannedExercise
    var durationSeconds: Int?
    var cue: String
    var bucket: SportsRoutineBucket

    var id: String { exercise.name }

    var formattedDuration: String? {
        guard let durationSeconds else { return nil }

        if durationSeconds < 60 {
            return "\(durationSeconds)s"
        }

        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60

        if seconds == 0 {
            return "\(minutes)m"
        }

        return "\(minutes)m \(seconds)s"
    }

    var routineSubtitle: String {
        if let formattedDuration {
            return "\(formattedDuration) · \(exercise.kind.rawValue) · \(exercise.station.rawValue)"
        }

        return "\(exercise.targetSets) sets · \(exercise.targetRepRange) reps · \(exercise.station.rawValue)"
    }
}

struct SportsResearchNote: Identifiable {
    var text: String
    var iconName: String

    var id: String { text }
}

struct SportsResearchSource: Identifiable {
    var title: String
    var url: URL

    var id: String { title }
}

enum SportsTrainingLibrary {
    static func plan(
        sport: CoachSport,
        program: SportsProgram,
        phase: SportsPrepPhase,
        depth: SportsRoutineDepth,
        role: CricketRole
    ) -> SportsTrainingPlan? {
        guard sport == .cricket else { return nil }

        switch program {
        case .mobility:
            return CricketSportsLibrary.mobilityPlan(phase: phase, depth: depth, role: role)
        case .strength:
            return CricketSportsLibrary.strengthPlan(depth: depth, role: role)
        }
    }

    static let researchNotes: [SportsResearchNote] = [
        SportsResearchNote(
            text: "Dynamic stretching belongs before play because it raises temperature, uses full range movement and supports speed, agility and acceleration.",
            iconName: "bolt"
        ),
        SportsResearchNote(
            text: "Static stretching is placed after play because long holds can blunt quick power before competition, but help restore range during cool-down.",
            iconName: "moon"
        ),
        SportsResearchNote(
            text: "Cricket injury patterns make shoulders, lower back, hamstrings, hips, calves, hands and forearms priority areas.",
            iconName: "target"
        ),
        SportsResearchNote(
            text: "Fast bowlers need extra trunk control, thoracic rotation, hip-adductor, hamstring, ankle and posterior shoulder preparation.",
            iconName: "figure.cricket"
        )
    ]

    static let sources: [SportsResearchSource] = [
        SportsResearchSource(
            title: "Hospital for Special Surgery: static vs dynamic stretching",
            url: URL(string: "https://www.hss.edu/health-library/move-better/static-dynamic-stretching")!
        ),
        SportsResearchSource(
            title: "Better Health Victoria and Sports Medicine Australia: cricket injury prevention",
            url: URL(string: "https://www.betterhealth.vic.gov.au/health/healthyliving/cricket-preventing-injury")!
        ),
        SportsResearchSource(
            title: "PubMed: cricket injury prevention programme protocol",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/28971855/")!
        ),
        SportsResearchSource(
            title: "PubMed: injury prevention strategies for pace bowlers",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/30178303/")!
        ),
        SportsResearchSource(
            title: "Cricket stretching guide for dynamic and static routines",
            url: URL(string: "https://www.clashpths.com/Sports-Activities/Cricket/Stretching-Guide-for-Cricket/a~3048/article.html")!
        )
    ]
}

private enum CricketSportsLibrary {
    static func mobilityPlan(
        phase: SportsPrepPhase,
        depth: SportsRoutineDepth,
        role: CricketRole
    ) -> SportsTrainingPlan {
        switch phase {
        case .preGame:
            return preGamePlan(depth: depth, role: role)
        case .postGame:
            return postGamePlan(depth: depth, role: role)
        }
    }

    static func strengthPlan(depth: SportsRoutineDepth, role: CricketRole) -> SportsTrainingPlan {
        let blocks = filteredBlocks([
            SportsRoutineBlock(
                title: "Cricket power base",
                subtitle: "Power, core stiffness and single-leg control for repeated cricket efforts.",
                items: strengthBase
            ),
            SportsRoutineBlock(
                title: roleBlockTitle(for: role),
                subtitle: strengthRoleSubtitle(for: role),
                items: strengthRoleItems(for: role)
            )
        ], for: depth)

        return SportsTrainingPlan(
            sport: .cricket,
            program: .strength,
            phase: nil,
            depth: depth,
            role: role,
            title: "\(depth.displayName) cricket strength",
            intent: strengthIntent(for: depth, role: role),
            blocks: blocks,
            focusAreas: ["Rotational power", "Core", "Shoulders", "Glutes", "Hamstrings", "Adductors"],
            estimatedSeconds: depth == .minimum ? 20 * 60 : 40 * 60
        )
    }

    private static func preGamePlan(depth: SportsRoutineDepth, role: CricketRole) -> SportsTrainingPlan {
        let blocks = filteredBlocks([
            SportsRoutineBlock(
                title: "Dynamic base",
                subtitle: "Move continuously and stay pain-free. Build from easy to sharp, never forced.",
                items: preGameBase
            ),
            SportsRoutineBlock(
                title: roleBlockTitle(for: role),
                subtitle: preGameRoleSubtitle(for: role),
                items: preGameRoleItems(for: role)
            )
        ], for: depth)

        return SportsTrainingPlan(
            sport: .cricket,
            program: .mobility,
            phase: .preGame,
            depth: depth,
            role: role,
            title: "\(depth.displayName) before cricket: dynamic warm-up",
            intent: preGameIntent(for: depth),
            blocks: blocks,
            focusAreas: ["Shoulders", "T-spine", "Hips", "Hamstrings", "Calves", "Forearms"],
            estimatedSeconds: 0
        )
    }

    private static func postGamePlan(depth: SportsRoutineDepth, role: CricketRole) -> SportsTrainingPlan {
        let blocks = filteredBlocks([
            SportsRoutineBlock(
                title: "Static cool-down",
                subtitle: "Breathe slowly. Hold mild tension only, with no bouncing and no pain.",
                items: postGameBase
            ),
            SportsRoutineBlock(
                title: roleBlockTitle(for: role),
                subtitle: postGameRoleSubtitle(for: role),
                items: postGameRoleItems(for: role)
            )
        ], for: depth)

        return SportsTrainingPlan(
            sport: .cricket,
            program: .mobility,
            phase: .postGame,
            depth: depth,
            role: role,
            title: "\(depth.displayName) after cricket: static cool-down",
            intent: postGameIntent(for: depth),
            blocks: blocks,
            focusAreas: ["Calves", "Quads", "Hamstrings", "Glutes", "Lats", "Shoulders", "Forearms"],
            estimatedSeconds: 0
        )
    }

    private static func filteredBlocks(_ blocks: [SportsRoutineBlock], for depth: SportsRoutineDepth) -> [SportsRoutineBlock] {
        blocks.compactMap { block in
            let items = depth == .minimum
                ? block.items.filter { $0.bucket == .minimum }
                : block.items

            guard !items.isEmpty else { return nil }
            return SportsRoutineBlock(title: block.title, subtitle: block.subtitle, items: items)
        }
    }

    private static let preGameBase: [SportsRoutineItem] = [
        mobility(
            "Jog, side shuffle, back pedal",
            seconds: 60,
            cue: "Stay light on the balls of your feet and change direction every 10 seconds.",
            bucket: .minimum
        ),
        mobility(
            "Arm circles to scapular hugs",
            seconds: 45,
            cue: "Circle small to large, then wrap and open the arms while keeping ribs down.",
            bucket: .minimum
        ),
        mobility(
            "Front and lateral leg swings",
            seconds: 60,
            cue: "Use a post or teammate for balance and swing under control on both legs.",
            bucket: .minimum
        ),
        mobility(
            "World's Greatest Stretch",
            seconds: 75,
            cue: "Step into a long lunge, elbow toward instep, then rotate the chest open.",
            bucket: .minimum
        ),
        mobility(
            "Walking lunge, reach, calf raise",
            seconds: 60,
            cue: "Reach overhead as the back hip opens, then drive up into a controlled calf raise.",
            bucket: .fullAddOn
        ),
        mobility(
            "High knees, butt kicks, pogo hops",
            seconds: 60,
            cue: "Cycle through 20 seconds each and finish springy, not breathless.",
            bucket: .fullAddOn
        )
    ]

    private static let postGameBase: [SportsRoutineItem] = [
        mobility(
            "Slow walk with nasal breathing",
            seconds: 60,
            cue: "Walk easily and lengthen the exhale before you start the longer holds.",
            bucket: .minimum
        ),
        mobility(
            "Calf Wall Stretch",
            seconds: 60,
            cue: "Hold 30 seconds per side with heel down and toes straight ahead.",
            bucket: .minimum
        ),
        mobility(
            "Half-kneeling hip flexor and quad",
            seconds: 60,
            cue: "Tuck the pelvis slightly, squeeze the back glute and hold 30 seconds per side.",
            bucket: .minimum
        ),
        mobility(
            "Seated Hamstring Stretch",
            seconds: 60,
            cue: "Hinge from the hips with a long spine and hold 30 seconds per side.",
            bucket: .minimum
        ),
        mobility(
            "Figure Four Glute Stretch",
            seconds: 60,
            cue: "Keep the ankle crossed over the knee and draw the thigh in gently.",
            bucket: .fullAddOn
        ),
        mobility(
            "Child's Pose",
            seconds: 60,
            cue: "Walk both hands to one side for 30 seconds, then switch sides.",
            bucket: .fullAddOn
        ),
        mobility(
            "Cross-Body Shoulder Stretch",
            seconds: 60,
            cue: "Relax the neck and hold the arm across the chest for 30 seconds per side.",
            bucket: .minimum
        ),
        mobility(
            "Forearm flexor and extensor stretch",
            seconds: 60,
            cue: "Use gentle palm-up and palm-down holds for batting, bowling and fielding grip work.",
            bucket: .minimum
        )
    ]

    private static let strengthBase: [SportsRoutineItem] = [
        strength(
            "Medicine ball rotational throw",
            sets: 3,
            reps: 5...6,
            cue: "Throw from the hips and trunk, then reset fully between reps.",
            bucket: .minimum
        ),
        strength(
            "Split squat",
            sets: 3,
            reps: 6...8,
            cue: "Drive through the front foot and keep the pelvis level.",
            bucket: .minimum
        ),
        strength(
            "Pallof Press",
            sets: 3,
            reps: 8...12,
            cue: "Brace hard and resist rotation on every rep.",
            bucket: .minimum
        ),
        strength(
            "Single-leg Romanian deadlift",
            sets: 3,
            reps: 6...8,
            cue: "Hinge long, keep hips square and own the hamstring range.",
            bucket: .fullAddOn
        )
    ]

    private static func preGameRoleItems(for role: CricketRole) -> [SportsRoutineItem] {
        switch role {
        case .allRounder:
            [
                mobility(
                    "Shadow bat, throw, bowl ramp",
                    seconds: 90,
                    cue: "Rehearse each pattern at 50, 70 and 80 percent effort without chasing speed.",
                    bucket: .minimum
                ),
                mobility(
                    "Wrist rolls and finger pumps",
                    seconds: 30,
                    cue: "Move through open-close fists, wrist circles and gentle pronation-supination.",
                    bucket: .fullAddOn
                )
            ]
        case .batsman:
            [
                mobility(
                    "Shadow batting hip turn",
                    seconds: 60,
                    cue: "Step, brace and rotate through the hips while the head stays steady.",
                    bucket: .minimum
                ),
                mobility(
                    "Crease shuffle to sprint start",
                    seconds: 45,
                    cue: "Shuffle laterally, then take two sharp running-between-wickets steps.",
                    bucket: .minimum
                ),
                mobility(
                    "Standing thoracic openers",
                    seconds: 45,
                    cue: "Rotate around the rib cage, not the lower back.",
                    bucket: .fullAddOn
                ),
                mobility(
                    "Wrist rolls and bat grip pulses",
                    seconds: 30,
                    cue: "Keep the grip quick and relaxed so the forearms are warm, not fatigued.",
                    bucket: .fullAddOn
                )
            ]
        case .bowler:
            [
                mobility(
                    "Bowling walk-through build-ups",
                    seconds: 75,
                    cue: "Progress from walk-through to smooth run-up at 50, 65 and 80 percent.",
                    bucket: .minimum
                ),
                mobility(
                    "Thoracic rotations with reach",
                    seconds: 45,
                    cue: "Open the bowling-side shoulder while keeping hips square and controlled.",
                    bucket: .minimum
                ),
                mobility(
                    "Single-leg balance to calf pop",
                    seconds: 45,
                    cue: "Balance, hinge slightly, then pop up into a short calf raise on each side.",
                    bucket: .fullAddOn
                ),
                mobility(
                    "Scapular wall slides or swimmers",
                    seconds: 45,
                    cue: "Move slowly and keep the shoulder blades gliding without shrugging.",
                    bucket: .minimum
                )
            ]
        }
    }

    private static func postGameRoleItems(for role: CricketRole) -> [SportsRoutineItem] {
        switch role {
        case .allRounder:
            [
                mobility(
                    "Open-book trunk rotation",
                    seconds: 60,
                    cue: "Lie on the side, stack knees and open the top arm for 30 seconds each way.",
                    bucket: .minimum
                )
            ]
        case .batsman:
            [
                mobility(
                    "Open-book trunk rotation",
                    seconds: 60,
                    cue: "Let the shoulder blade settle toward the ground without forcing the low back.",
                    bucket: .minimum
                ),
                mobility(
                    "Bat grip forearm release",
                    seconds: 30,
                    cue: "Use a gentle prayer stretch and reverse prayer stretch for 15 seconds each.",
                    bucket: .fullAddOn
                )
            ]
        case .bowler:
            [
                mobility(
                    "Overhead lat and triceps side stretch",
                    seconds: 60,
                    cue: "Reach the bowling arm overhead and side bend gently for 30 seconds each side.",
                    bucket: .minimum
                ),
                mobility(
                    "Adductor rock-back hold",
                    seconds: 60,
                    cue: "Set one knee wide, rock back until mild tension, then hold 30 seconds each side.",
                    bucket: .fullAddOn
                )
            ]
        }
    }

    private static func strengthRoleItems(for role: CricketRole) -> [SportsRoutineItem] {
        switch role {
        case .allRounder:
            [
                strength(
                    "Dumbbell Row",
                    sets: 3,
                    reps: 8...10,
                    cue: "Pull the elbow toward the hip and pause with the shoulder blade set.",
                    bucket: .minimum
                ),
                strength(
                    "Cable Woodchop",
                    sets: 3,
                    reps: 8...12,
                    cue: "Rotate through ribs and hips while keeping the finish controlled.",
                    bucket: .fullAddOn
                )
            ]
        case .batsman:
            [
                strength(
                    "Cable Woodchop",
                    sets: 3,
                    reps: 8...12,
                    cue: "Drive the hips first and finish tall for bat-speed transfer.",
                    bucket: .minimum
                ),
                strength(
                    "Lateral lunge",
                    sets: 3,
                    reps: 6...8,
                    cue: "Sit into the hip and push the ground away for crease movement.",
                    bucket: .minimum
                ),
                strength(
                    "Push-ups",
                    sets: 3,
                    reps: 8...15,
                    cue: "Keep ribs down and finish with strong shoulder-blade control.",
                    bucket: .fullAddOn
                )
            ]
        case .bowler:
            [
                strength(
                    "External rotation with band",
                    sets: 3,
                    reps: 12...15,
                    cue: "Keep the elbow pinned and rotate slowly for posterior shoulder capacity.",
                    bucket: .minimum
                ),
                strength(
                    "Copenhagen side plank",
                    sets: 2,
                    reps: 15...25,
                    cue: "Use seconds as reps and keep hips high for adductor strength.",
                    bucket: .minimum
                ),
                strength(
                    "Calf Raise",
                    sets: 3,
                    reps: 10...15,
                    cue: "Pause at the top and lower slowly for front-foot and run-up resilience.",
                    bucket: .fullAddOn
                )
            ]
        }
    }

    private static func mobility(
        _ name: String,
        seconds: Int,
        cue: String,
        bucket: SportsRoutineBucket
    ) -> SportsRoutineItem {
        let exercise = plannedExercise(
            name,
            fallbackKind: .stretch,
            targetSets: 1,
            targetReps: seconds...seconds,
            coachingNote: cue
        )

        return SportsRoutineItem(
            exercise: exercise,
            durationSeconds: seconds,
            cue: cue,
            bucket: bucket
        )
    }

    private static func strength(
        _ name: String,
        sets: Int,
        reps: ClosedRange<Int>,
        cue: String,
        bucket: SportsRoutineBucket
    ) -> SportsRoutineItem {
        let exercise = plannedExercise(
            name,
            fallbackKind: .strength,
            targetSets: sets,
            targetReps: reps,
            coachingNote: cue
        )

        return SportsRoutineItem(
            exercise: exercise,
            durationSeconds: nil,
            cue: cue,
            bucket: bucket
        )
    }

    private static func plannedExercise(
        _ name: String,
        fallbackKind: ExerciseKind,
        targetSets: Int,
        targetReps: ClosedRange<Int>,
        coachingNote: String
    ) -> PlannedExercise {
        if let definition = ExerciseLibrary.definitions.first(where: { $0.name == name }) {
            return PlannedExercise(
                name: definition.name,
                muscleGroup: definition.primaryMuscleGroup,
                secondaryMuscleGroups: definition.secondaryMuscleGroups,
                primaryDetailedMuscle: definition.primaryDetailedMuscle,
                secondaryDetailedMuscle: definition.secondaryDetailedMuscle,
                detailedMuscles: definition.detailedMuscles,
                equipment: definition.equipment,
                station: definition.station,
                kind: definition.kind,
                targetSets: targetSets,
                targetRepsLower: targetReps.lowerBound,
                targetRepsUpper: targetReps.upperBound,
                coachingNote: coachingNote
            )
        }

        return PlannedExercise(
            name: name,
            muscleGroup: .core,
            secondaryMuscleGroups: [],
            primaryDetailedMuscle: .rectusAbdominis,
            secondaryDetailedMuscle: nil,
            detailedMuscles: [.rectusAbdominis],
            equipment: .bodyweight,
            station: .bodyweight,
            kind: fallbackKind,
            targetSets: targetSets,
            targetRepsLower: targetReps.lowerBound,
            targetRepsUpper: targetReps.upperBound,
            coachingNote: coachingNote
        )
    }

    private static func preGameIntent(for depth: SportsRoutineDepth) -> String {
        switch depth {
        case .minimum:
            "Use this when time is tight before a match or net session. It keeps the must-do dynamic work for temperature, joints and cricket-specific rhythm."
        case .full:
            "Use this when you have the full window before a match, net session or hard fielding block. It adds extra prep without tiring you."
        }
    }

    private static func postGameIntent(for depth: SportsRoutineDepth) -> String {
        switch depth {
        case .minimum:
            "Use this when you need a short cool-down after play. It keeps the priority static holds for the areas most likely to feel stiff later."
        case .full:
            "Use this after play when you have the full window to settle heart rate, unload common cricket hot spots and reduce next-day stiffness."
        }
    }

    private static func strengthIntent(for depth: SportsRoutineDepth, role: CricketRole) -> String {
        let roleText = role.displayName.lowercased()
        switch depth {
        case .minimum:
            return "A short \(roleText) strength plan for the highest-return cricket muscles when training time is limited."
        case .full:
            return "A fuller \(roleText) strength plan for rotational power, shoulder resilience and lower-body transfer."
        }
    }

    private static func roleBlockTitle(for role: CricketRole) -> String {
        switch role {
        case .allRounder: "All-rounder finish"
        case .batsman: "Batsman finish"
        case .bowler: "Bowler finish"
        }
    }

    private static func preGameRoleSubtitle(for role: CricketRole) -> String {
        switch role {
        case .allRounder:
            "A short ramp through batting, throwing and bowling patterns."
        case .batsman:
            "Extra rotation, crease movement and grip prep before batting."
        case .bowler:
            "Extra shoulder, trunk, hip and ankle prep before spells."
        }
    }

    private static func postGameRoleSubtitle(for role: CricketRole) -> String {
        switch role {
        case .allRounder:
            "A final trunk opener for a balanced cricket cool-down."
        case .batsman:
            "Extra trunk and forearm recovery after shots and running."
        case .bowler:
            "Extra posterior chain, lat and adductor recovery after bowling."
        }
    }

    private static func strengthRoleSubtitle(for role: CricketRole) -> String {
        switch role {
        case .allRounder:
            "Balanced pulling and rotation for batting, bowling and fielding."
        case .batsman:
            "Bat-speed, crease coverage and upper-body transfer."
        case .bowler:
            "Shoulder capacity, adductor control and lower-leg resilience."
        }
    }
}
