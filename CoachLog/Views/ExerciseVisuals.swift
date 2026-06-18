import AVKit
import SwiftUI
import UIKit

struct ExerciseMediaAsset: Hashable {
    var imageAssetName: String?
    var videoResourceName: String?

    var videoURL: URL? {
        guard let videoResourceName else { return nil }
        return Bundle.main.url(forResource: videoResourceName, withExtension: "mp4")
    }

    var hasVideo: Bool {
        videoURL != nil
    }
}

enum ExerciseMediaLibrary {
    static let representativeExercisesByGroup: [MuscleGroup: String] = [
        .chest: "Cable Chest Fly",
        .back: "Lat Pulldown",
        .legs: "Goblet Squat",
        .glutes: "Glute Bridge",
        .shoulders: "Dumbbell Shoulder Press",
        .biceps: "Biceps Curl",
        .triceps: "Triceps Pressdown",
        .core: "Plank"
    ]

    private static let mediaByExerciseName: [String: ExerciseMediaAsset] = [
        "Push-ups": ExerciseMediaAsset(
            imageAssetName: "exercise-push-ups",
            videoResourceName: nil
        ),
        "Dumbbell Bench Press": ExerciseMediaAsset(
            imageAssetName: "exercise-dumbbell-bench-press",
            videoResourceName: nil
        ),
        "Cable Chest Fly": ExerciseMediaAsset(
            imageAssetName: "exercise-cable-chest-fly",
            videoResourceName: "exercise-cable-chest-fly"
        ),
        "Lat Pulldown": ExerciseMediaAsset(
            imageAssetName: "exercise-lat-pulldown",
            videoResourceName: "exercise-lat-pulldown"
        ),
        "Seated Row": ExerciseMediaAsset(
            imageAssetName: "exercise-seated-row",
            videoResourceName: nil
        ),
        "Assisted Pull-up": ExerciseMediaAsset(
            imageAssetName: "exercise-assisted-pull-up",
            videoResourceName: nil
        ),
        "Goblet Squat": ExerciseMediaAsset(
            imageAssetName: "exercise-goblet-squat",
            videoResourceName: "exercise-goblet-squat"
        ),
        "Glute Bridge": ExerciseMediaAsset(
            imageAssetName: "exercise-glute-bridge",
            videoResourceName: "exercise-glute-bridge"
        ),
        "Dumbbell Hip Thrust": ExerciseMediaAsset(
            imageAssetName: "exercise-dumbbell-hip-thrust",
            videoResourceName: "exercise-dumbbell-hip-thrust"
        ),
        "Cable Glute Kickback": ExerciseMediaAsset(
            imageAssetName: "exercise-cable-glute-kickback",
            videoResourceName: "exercise-cable-glute-kickback"
        ),
        "Side-Lying Hip Abduction": ExerciseMediaAsset(
            imageAssetName: "exercise-side-lying-hip-abduction",
            videoResourceName: "exercise-side-lying-hip-abduction"
        ),
        "Figure Four Glute Stretch": ExerciseMediaAsset(
            imageAssetName: "exercise-figure-four-glute-stretch",
            videoResourceName: nil
        ),
        "Romanian Deadlift": ExerciseMediaAsset(
            imageAssetName: "exercise-romanian-deadlift",
            videoResourceName: "exercise-romanian-deadlift"
        ),
        "Leg Press": ExerciseMediaAsset(
            imageAssetName: "exercise-leg-press",
            videoResourceName: nil
        ),
        "Seated Leg Curl": ExerciseMediaAsset(
            imageAssetName: "exercise-seated-leg-curl",
            videoResourceName: nil
        ),
        "Dumbbell Reverse Lunge": ExerciseMediaAsset(
            imageAssetName: "exercise-dumbbell-reverse-lunge",
            videoResourceName: "exercise-dumbbell-reverse-lunge"
        ),
        "Step-up": ExerciseMediaAsset(
            imageAssetName: "exercise-step-up",
            videoResourceName: "exercise-step-up"
        ),
        "World's Greatest Stretch": ExerciseMediaAsset(
            imageAssetName: "exercise-world-s-greatest-stretch",
            videoResourceName: "exercise-world-s-greatest-stretch"
        ),
        "Dumbbell Shoulder Press": ExerciseMediaAsset(
            imageAssetName: "exercise-dumbbell-shoulder-press",
            videoResourceName: "exercise-dumbbell-shoulder-press"
        ),
        "Dumbbell Lateral Raise": ExerciseMediaAsset(
            imageAssetName: "exercise-dumbbell-lateral-raise",
            videoResourceName: nil
        ),
        "Biceps Curl": ExerciseMediaAsset(
            imageAssetName: "exercise-biceps-curl",
            videoResourceName: "exercise-biceps-curl"
        ),
        "Triceps Pressdown": ExerciseMediaAsset(
            imageAssetName: "exercise-triceps-pressdown",
            videoResourceName: "exercise-triceps-pressdown"
        ),
        "Plank": ExerciseMediaAsset(
            imageAssetName: "exercise-plank",
            videoResourceName: "exercise-plank"
        ),
        "Dead Bug": ExerciseMediaAsset(
            imageAssetName: "exercise-dead-bug",
            videoResourceName: nil
        ),
        "Doorway Chest Stretch": ExerciseMediaAsset(
            imageAssetName: "exercise-doorway-chest-stretch",
            videoResourceName: nil
        ),
        "Calf Raise": ExerciseMediaAsset(
            imageAssetName: "exercise-calf-raise",
            videoResourceName: nil
        ),
        "Jog, side shuffle, back pedal": ExerciseMediaAsset(
            imageAssetName: "exercise-jog-side-shuffle-back-pedal",
            videoResourceName: nil
        ),
        "Arm circles to scapular hugs": ExerciseMediaAsset(
            imageAssetName: "exercise-arm-circles-to-scapular-hugs",
            videoResourceName: nil
        ),
        "Front and lateral leg swings": ExerciseMediaAsset(
            imageAssetName: "exercise-front-and-lateral-leg-swings",
            videoResourceName: nil
        ),
        "Walking lunge, reach, calf raise": ExerciseMediaAsset(
            imageAssetName: "exercise-walking-lunge-reach-calf-raise",
            videoResourceName: nil
        ),
        "High knees, butt kicks, pogo hops": ExerciseMediaAsset(
            imageAssetName: "exercise-high-knees-butt-kicks-pogo-hops",
            videoResourceName: nil
        ),
        "Slow walk with nasal breathing": ExerciseMediaAsset(
            imageAssetName: "exercise-slow-walk-with-nasal-breathing",
            videoResourceName: nil
        ),
        "Calf Wall Stretch": ExerciseMediaAsset(
            imageAssetName: "exercise-calf-wall-stretch",
            videoResourceName: nil
        ),
        "Half-kneeling hip flexor and quad": ExerciseMediaAsset(
            imageAssetName: "exercise-half-kneeling-hip-flexor-and-quad",
            videoResourceName: nil
        ),
        "Seated Hamstring Stretch": ExerciseMediaAsset(
            imageAssetName: "exercise-seated-hamstring-stretch",
            videoResourceName: nil
        ),
        "Child's Pose": ExerciseMediaAsset(
            imageAssetName: "exercise-childs-pose",
            videoResourceName: nil
        ),
        "Cross-Body Shoulder Stretch": ExerciseMediaAsset(
            imageAssetName: "exercise-cross-body-shoulder-stretch",
            videoResourceName: nil
        ),
        "Forearm flexor and extensor stretch": ExerciseMediaAsset(
            imageAssetName: "exercise-forearm-flexor-and-extensor-stretch",
            videoResourceName: nil
        ),
        "Medicine ball rotational throw": ExerciseMediaAsset(
            imageAssetName: "exercise-medicine-ball-rotational-throw",
            videoResourceName: nil
        ),
        "Split squat": ExerciseMediaAsset(
            imageAssetName: "exercise-split-squat",
            videoResourceName: nil
        ),
        "Pallof Press": ExerciseMediaAsset(
            imageAssetName: "exercise-pallof-press",
            videoResourceName: nil
        ),
        "Single-leg Romanian deadlift": ExerciseMediaAsset(
            imageAssetName: "exercise-single-leg-romanian-deadlift",
            videoResourceName: nil
        ),
        "Shadow bat, throw, bowl ramp": ExerciseMediaAsset(
            imageAssetName: "exercise-shadow-bat-throw-bowl-ramp",
            videoResourceName: nil
        ),
        "Wrist rolls and finger pumps": ExerciseMediaAsset(
            imageAssetName: "exercise-wrist-rolls-and-finger-pumps",
            videoResourceName: nil
        ),
        "Shadow batting hip turn": ExerciseMediaAsset(
            imageAssetName: "exercise-shadow-batting-hip-turn",
            videoResourceName: nil
        ),
        "Crease shuffle to sprint start": ExerciseMediaAsset(
            imageAssetName: "exercise-crease-shuffle-to-sprint-start",
            videoResourceName: nil
        ),
        "Standing thoracic openers": ExerciseMediaAsset(
            imageAssetName: "exercise-standing-thoracic-openers",
            videoResourceName: nil
        ),
        "Wrist rolls and bat grip pulses": ExerciseMediaAsset(
            imageAssetName: "exercise-wrist-rolls-and-bat-grip-pulses",
            videoResourceName: nil
        ),
        "Bowling walk-through build-ups": ExerciseMediaAsset(
            imageAssetName: "exercise-bowling-walk-through-build-ups",
            videoResourceName: nil
        ),
        "Thoracic rotations with reach": ExerciseMediaAsset(
            imageAssetName: "exercise-thoracic-rotations-with-reach",
            videoResourceName: nil
        ),
        "Single-leg balance to calf pop": ExerciseMediaAsset(
            imageAssetName: "exercise-single-leg-balance-to-calf-pop",
            videoResourceName: nil
        ),
        "Scapular wall slides or swimmers": ExerciseMediaAsset(
            imageAssetName: "exercise-scapular-wall-slides-or-swimmers",
            videoResourceName: nil
        ),
        "Open-book trunk rotation": ExerciseMediaAsset(
            imageAssetName: "exercise-open-book-trunk-rotation",
            videoResourceName: nil
        ),
        "Bat grip forearm release": ExerciseMediaAsset(
            imageAssetName: "exercise-bat-grip-forearm-release",
            videoResourceName: nil
        ),
        "Overhead lat and triceps side stretch": ExerciseMediaAsset(
            imageAssetName: "exercise-overhead-lat-and-triceps-side-stretch",
            videoResourceName: nil
        ),
        "Adductor rock-back hold": ExerciseMediaAsset(
            imageAssetName: "exercise-adductor-rock-back-hold",
            videoResourceName: nil
        ),
        "Dumbbell Row": ExerciseMediaAsset(
            imageAssetName: "exercise-dumbbell-row",
            videoResourceName: nil
        ),
        "Cable Woodchop": ExerciseMediaAsset(
            imageAssetName: "exercise-cable-woodchop",
            videoResourceName: nil
        ),
        "Lateral lunge": ExerciseMediaAsset(
            imageAssetName: "exercise-lateral-lunge",
            videoResourceName: nil
        ),
        "External rotation with band": ExerciseMediaAsset(
            imageAssetName: "exercise-external-rotation-with-band",
            videoResourceName: nil
        ),
        "Copenhagen side plank": ExerciseMediaAsset(
            imageAssetName: "exercise-copenhagen-side-plank",
            videoResourceName: nil
        )
    ]

    static func media(for exerciseName: String) -> ExerciseMediaAsset {
        mediaByExerciseName[exerciseName] ?? ExerciseMediaAsset(imageAssetName: nil, videoResourceName: nil)
    }

    static func imageAssetName(for exercise: PlannedExercise) -> String? {
        if let imageAssetName = media(for: exercise.name).imageAssetName {
            return imageAssetName
        }

        if let representativeName = representativeExercisesByGroup[exercise.muscleGroup],
           let imageAssetName = mediaByExerciseName[representativeName]?.imageAssetName {
            return imageAssetName
        }

        return mediaByExerciseName["Goblet Squat"]?.imageAssetName
    }
}

enum ExerciseMuscleTargetLibrary {
    private static let assetByExerciseName: [String: String] = [
        "Biceps Curl": "muscle-target-biceps-curl",
        "Cable Curl": "muscle-target-biceps-curl",
        "Incline Dumbbell Curl": "muscle-target-biceps-curl",
        "Lat Pulldown": "muscle-target-lat-pulldown",
        "Assisted Pull-up": "muscle-target-lat-pulldown",
        "Goblet Squat": "muscle-target-goblet-squat",
        "Leg Press": "muscle-target-goblet-squat",
        "Glute Bridge": "muscle-target-gluteus-maximus",
        "Dumbbell Hip Thrust": "muscle-target-gluteus-maximus",
        "Cable Glute Kickback": "muscle-target-gluteus-maximus",
        "Side-Lying Hip Abduction": "muscle-target-gluteus-maximus",
        "Figure Four Glute Stretch": "muscle-target-gluteus-maximus",
        "Plank": "muscle-target-plank",
        "Dead Bug": "muscle-target-plank",
        "Side Plank": "muscle-target-plank",
        "Pallof Press": "muscle-target-plank",
        "Calf Raise": "muscle-target-calf-raise",
        "Calf Wall Stretch": "muscle-target-calf-raise"
    ]

    static func assetName(
        for exerciseName: String,
        primary: DetailedMuscleGroup
    ) -> String? {
        if let assetName = assetByExerciseName[exerciseName] {
            return assetName
        }

        return assetName(for: primary)
    }

    private static func assetName(for muscle: DetailedMuscleGroup) -> String? {
        switch muscle {
        case .upperChest:
            "muscle-target-upper-chest"
        case .midChest, .lowerChest:
            "muscle-target-mid-chest"
        case .triceps:
            "muscle-target-triceps"
        case .biceps:
            "muscle-target-biceps-curl"
        case .latissimusDorsi:
            "muscle-target-lat-pulldown"
        case .upperBack:
            "muscle-target-upper-back"
        case .lowerBack:
            "muscle-target-lower-back"
        case .quadriceps:
            "muscle-target-goblet-squat"
        case .adductors:
            "muscle-target-goblet-squat"
        case .hamstrings:
            "muscle-target-hamstrings"
        case .gluteusMaximus, .gluteusMedius, .gluteusMinimus:
            "muscle-target-gluteus-maximus"
        case .frontDeltoids:
            "muscle-target-front-deltoids"
        case .sideDeltoids:
            "muscle-target-side-deltoids"
        case .rearDeltoids:
            "muscle-target-rear-deltoids"
        case .forearmFlexors, .forearmExtensors, .brachioradialis:
            "muscle-target-forearm-flexors"
        case .rectusAbdominis, .obliques:
            "muscle-target-plank"
        case .gastrocnemius, .soleus:
            "muscle-target-calf-raise"
        }
    }
}

struct ExerciseVisualHeader: View {
    var exercise: PlannedExercise
    var subtitle: String
    var note: String?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ExerciseIllustrationThumbnail(exercise: exercise, size: 58)

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.coachSecondaryText)
                    .lineLimit(2)

                ExerciseMuscleChipRow(
                    groups: exercise.affectedMuscleGroups,
                    primary: exercise.primaryDetailedMuscle,
                    secondary: exercise.secondaryDetailedMuscle,
                    supporting: exercise.detailedMuscles
                )

                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            ExerciseMuscleTargetBadge(
                exerciseName: exercise.name,
                primary: exercise.primaryDetailedMuscle,
                secondary: exercise.secondaryDetailedMuscle,
                supporting: exercise.detailedMuscles
            )
            .frame(
                width: 64,
                height: 64
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), primary muscle: \(exercise.primaryDetailedMuscle.rawValue), secondary muscle: \(exercise.secondaryDetailedMuscle?.rawValue ?? "none")")
    }
}

struct ExerciseIllustrationThumbnail: View {
    var exercise: PlannedExercise
    var size: CGFloat

    @State private var isShowingInstructions = false

    private var media: ExerciseMediaAsset {
        ExerciseMediaLibrary.media(for: exercise.name)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.coachSurfaceElevated)

            if let image = resolvedImage {
                thumbnailImage(image)
            } else {
                fallbackPreview
            }

            if media.hasVideo {
                playOverlay
            }
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.coachBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onTapGesture {
            isShowingInstructions = true
        }
        .sheet(isPresented: $isShowingInstructions) {
            ExerciseInstructionSheet(exercise: exercise, media: media)
        }
    }

    private var resolvedImage: UIImage? {
        if let imageAssetName = ExerciseMediaLibrary.imageAssetName(for: exercise),
           let image = UIImage(named: imageAssetName) {
            return image
        }

        return UIImage(named: exercise.illustrationAssetName)
    }

    private func thumbnailImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var playOverlay: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Image(systemName: "play.fill")
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.84))
                    .frame(width: size * 0.34, height: size * 0.34)
                    .background(CoachGradient.accent)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.28), radius: 6, y: 3)
                    .padding(size * 0.08)
            }
        }
    }

    private var fallbackPreview: some View {
        ZStack {
            MuscleImpactMap(
                primary: exercise.primaryDetailedMuscle,
                secondary: exercise.secondaryDetailedMuscle,
                supporting: exercise.detailedMuscles,
                orientation: exercise.primaryDetailedMuscle.preferredMapOrientation
            )
            .frame(width: size * 0.44, height: size * 0.66)
            .offset(x: -size * 0.18)

            MuscleGroupGlyph(group: exercise.muscleGroup)
                .frame(width: size * 0.32, height: size * 0.32)
                .offset(x: size * 0.20, y: -size * 0.10)

            Capsule()
                .fill(Color.coachAccent.opacity(0.28))
                .frame(width: size * 0.46, height: 3)
                .offset(x: size * 0.16, y: size * 0.24)
        }
        .padding(8)
    }
}

private struct ExerciseInstructionSheet: View {
    @Environment(\.dismiss) private var dismiss

    var exercise: PlannedExercise
    var media: ExerciseMediaAsset

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    private var guidance: ExerciseGuidance {
        ExerciseGuidanceLibrary.guidance(for: exercise.name, exercise: exercise)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(exercise.name)
                            .font(.title3.weight(.bold))

                        if media.hasVideo {
                            VideoPlayer(player: player)
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.coachBorder, lineWidth: 1)
                                }
                        } else {
                            ExerciseInstructionMuscleMapCard(exercise: exercise)
                        }

                        ExerciseGuidanceView(guidance: guidance)
                    }
                    .padding()
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: startPlayback)
            .onDisappear(perform: stopPlayback)
        }
        .preferredColorScheme(.dark)
    }

    private func startPlayback() {
        guard let url = media.videoURL else { return }

        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        player = queuePlayer
        queuePlayer.play()
    }

    private func stopPlayback() {
        player?.pause()
        player = nil
        looper = nil
    }
}

private struct ExerciseVideoMetaBadge: View {
    var title: String
    var systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.coachSecondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.coachSurfaceElevated)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.coachBorder, lineWidth: 1)
            }
    }
}

private struct ExerciseInstructionMuscleMapCard: View {
    var exercise: PlannedExercise

    var body: some View {
        HStack(spacing: 14) {
            ExerciseMuscleTargetBadge(
                exerciseName: exercise.name,
                primary: exercise.primaryDetailedMuscle,
                secondary: exercise.secondaryDetailedMuscle,
                supporting: exercise.detailedMuscles
            )
            .frame(width: 104, height: 104)

            VStack(alignment: .leading, spacing: 8) {
                Text("Target map")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.coachAccent)

                Text(exercise.specificMuscleSummary)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.coachSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.coachBorder, lineWidth: 1)
        }
    }
}

private struct ExerciseGuidanceView: View {
    var guidance: ExerciseGuidance

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExerciseGuidanceStepsCard(steps: guidance.steps)

            HStack(alignment: .top, spacing: 10) {
                ExerciseGuidanceCallout(
                    title: "Pro tip",
                    message: guidance.proTip,
                    systemImage: "sparkles",
                    tint: Color.freshness(.ready)
                )

                ExerciseGuidanceCallout(
                    title: "Avoid",
                    message: guidance.avoid,
                    systemImage: "exclamationmark.triangle.fill",
                    tint: Color.coachWarm
                )
            }
        }
    }
}

private struct ExerciseGuidanceStepsCard: View {
    var steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How to move", systemImage: "list.number")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.coachAccent)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.black.opacity(0.86))
                            .frame(width: 22, height: 22)
                            .background(CoachGradient.accent)
                            .clipShape(Circle())

                        Text(step)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.90))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.coachSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.coachAccent.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct ExerciseGuidanceCallout: View {
    var title: String
    var message: String
    var systemImage: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)

            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(12)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.24), lineWidth: 1)
        }
    }
}

private struct ExerciseGuidance: Hashable {
    var steps: [String]
    var proTip: String
    var avoid: String
}

private enum ExerciseGuidanceLibrary {
    static func guidance(for exerciseName: String, exercise: PlannedExercise) -> ExerciseGuidance {
        guidanceByExerciseName[exerciseName] ?? ExerciseGuidance(
            steps: [
                "Set up at the \(exercise.station.rawValue.lowercased()) with \(exercise.equipment.rawValue.lowercased()) and brace before moving.",
                exercise.kind == .stretch
                    ? "Ease into the stretch until you feel the target area without forcing range."
                    : "Move through a smooth controlled rep while keeping tension on \(exercise.primaryDetailedMuscle.rawValue.lowercased()).",
                exercise.kind == .stretch
                    ? "Breathe slowly, hold the position, then release back to the start under control."
                    : "Return to the starting position under control before the next rep."
            ],
            proTip: "Keep the movement strict enough that \(exercise.primaryDetailedMuscle.rawValue.lowercased()) stays the main target.",
            avoid: "Do not chase range by twisting, bouncing, or losing posture."
        )
    }

    private static let guidanceByExerciseName: [String: ExerciseGuidance] = [
        "Cable Chest Fly": ExerciseGuidance(
            steps: [
                "Set both pulleys around chest height and stand centered with a staggered stance.",
                "Keep a soft bend in the elbows and bring the handles together in front of the chest.",
                "Return slowly until the chest opens without letting the shoulders roll forward."
            ],
            proTip: "Think about hugging a wide barrel so the chest does the work.",
            avoid: "Avoid locking the elbows or letting the cables pull your shoulders into a shrug."
        ),
        "Lat Pulldown": ExerciseGuidance(
            steps: [
                "Grip the bar slightly wider than shoulder width and sit tall with thighs secured.",
                "Pull elbows down toward your ribs while keeping the chest lifted.",
                "Control the bar back overhead until the arms are long without losing posture."
            ],
            proTip: "Start each rep by pulling the shoulder blades down before bending the elbows.",
            avoid: "Avoid leaning far back or yanking the bar behind your neck."
        ),
        "Goblet Squat": ExerciseGuidance(
            steps: [
                "Hold one dumbbell close to the chest and set feet about shoulder width.",
                "Sit hips down and back until thighs reach at least parallel.",
                "Drive through the whole foot and stand tall with knees tracking over toes."
            ],
            proTip: "Keep elbows pointed down so the dumbbell stays close and your torso stays upright.",
            avoid: "Avoid heels lifting, knees collapsing inward, or rounding the lower back."
        ),
        "Glute Bridge": ExerciseGuidance(
            steps: [
                "Lie on your back with knees bent, feet flat, and heels close to the glutes.",
                "Press through both heels and lift hips until shoulders, hips, and knees align.",
                "Squeeze briefly at the top, then lower the hips back to the mat with control."
            ],
            proTip: "Keep ribs down and pelvis neutral so the squeeze comes from the glutes.",
            avoid: "Avoid arching the lower back or letting the knees cave inward."
        ),
        "Dumbbell Hip Thrust": ExerciseGuidance(
            steps: [
                "Set shoulder blades against the bench and hold the dumbbell across the hip crease.",
                "Drive through the heels and lift until the torso is parallel to the floor.",
                "Pause with glutes squeezed, then lower until the hips return near the floor."
            ],
            proTip: "Tuck the chin slightly and keep ribs down at the top.",
            avoid: "Avoid overextending the lower back or letting the dumbbell shift."
        ),
        "Cable Glute Kickback": ExerciseGuidance(
            steps: [
                "Attach the ankle strap low and hold the cable machine lightly for balance.",
                "Hinge forward slightly with hips square and the working leg under the hip.",
                "Kick back by squeezing the glute, then return under control with cable tension."
            ],
            proTip: "Stop the kick before your low back arches; small clean range beats a high swing.",
            avoid: "Avoid rotating the hips open, leaning sideways, or using momentum."
        ),
        "Side-Lying Hip Abduction": ExerciseGuidance(
            steps: [
                "Lie on your side with hips stacked and the top leg straight.",
                "Point the top toes slightly down and lift the leg with the side glute.",
                "Pause briefly, then lower without rolling your torso backward."
            ],
            proTip: "Keep the pelvis still; the top leg should move, not your whole body.",
            avoid: "Avoid turning toes upward or kicking the leg forward."
        ),
        "Figure Four Glute Stretch": ExerciseGuidance(
            steps: [
                "Lie on your back with both knees bent and feet flat on the mat.",
                "Cross one ankle over the opposite thigh just above the knee.",
                "Pull the uncrossed thigh toward the chest until you feel a glute stretch."
            ],
            proTip: "Relax your head and shoulders so the stretch stays in the hip.",
            avoid: "Avoid pulling directly on the knee or twisting the pelvis."
        ),
        "Romanian Deadlift": ExerciseGuidance(
            steps: [
                "Stand tall with dumbbells in front of the thighs and knees softly bent.",
                "Push hips back and slide the dumbbells close down the legs.",
                "Stop around mid-shin or at a hamstring stretch, then drive hips forward to stand."
            ],
            proTip: "Keep shins nearly vertical and think hips back, not knees forward.",
            avoid: "Avoid rounding the back or letting the dumbbells drift away from your legs."
        ),
        "Dumbbell Reverse Lunge": ExerciseGuidance(
            steps: [
                "Stand tall with dumbbells at your sides and feet hip-width apart.",
                "Step one leg back into a long lunge and lower with the front foot flat.",
                "Push through the front heel and midfoot to return to the starting stance."
            ],
            proTip: "Keep the front knee tracking over the toes and the pelvis square.",
            avoid: "Avoid a short step, knee collapse, or swinging the dumbbells."
        ),
        "Step-up": ExerciseGuidance(
            steps: [
                "Place one full foot on a stable box with the chest tall.",
                "Drive through the foot on the box and stand all the way up.",
                "Step down slowly to the exact starting position before repeating."
            ],
            proTip: "Make the top leg do the lift; the floor leg should not jump you up.",
            avoid: "Avoid pushing hard off the back foot or letting the knee cave inward."
        ),
        "World's Greatest Stretch": ExerciseGuidance(
            steps: [
                "Start in a strong high plank with hands under shoulders.",
                "Step one foot outside the same-side hand into a runner's lunge.",
                "Lower the elbow toward the foot, rotate open, then return to plank."
            ],
            proTip: "Move slowly enough to keep the hips low and the spine long.",
            avoid: "Avoid rushing the transition or collapsing into the shoulders."
        ),
        "Dumbbell Shoulder Press": ExerciseGuidance(
            steps: [
                "Start with dumbbells at shoulder height and wrists stacked over elbows.",
                "Brace the core and press both dumbbells overhead until arms are long.",
                "Lower to shoulder height with control before the next rep."
            ],
            proTip: "Keep ribs down so the press stays in the shoulders, not the lower back.",
            avoid: "Avoid flaring the ribs, shrugging, or letting the dumbbells drift forward."
        ),
        "Biceps Curl": ExerciseGuidance(
            steps: [
                "Stand tall with dumbbells at your sides and palms facing forward.",
                "Curl the weights by bending the elbows while keeping upper arms still.",
                "Squeeze at the top, then lower fully with control."
            ],
            proTip: "Control the lowering phase; that is where a lot of the training effect happens.",
            avoid: "Avoid swinging the torso or letting elbows travel far forward."
        ),
        "Triceps Pressdown": ExerciseGuidance(
            steps: [
                "Stand tall at the cable stack with elbows pinned near your ribs.",
                "Press the handle down until elbows fully extend without locking aggressively.",
                "Return to about forearm-parallel while keeping the upper arms still."
            ],
            proTip: "Imagine pushing the handle through the floor while shoulders stay relaxed.",
            avoid: "Avoid leaning your body weight into the cable or letting elbows flare."
        ),
        "Plank": ExerciseGuidance(
            steps: [
                "Set elbows under shoulders and extend legs with feet about hip-width.",
                "Brace abs and glutes so the body forms a straight line.",
                "Hold steady while breathing slowly through the full interval."
            ],
            proTip: "Push the floor away slightly to keep the upper back active.",
            avoid: "Avoid sagging hips, hiking hips high, or holding your breath."
        ),
        "Push-ups": ExerciseGuidance(
            steps: [
                "Set hands just outside shoulder width with the body in a straight line.",
                "Lower the chest toward the floor while elbows track about 30 to 45 degrees from the ribs.",
                "Press the floor away until arms are long without letting hips sag."
            ],
            proTip: "Squeeze glutes and brace abs before every rep.",
            avoid: "Avoid flaring elbows straight out or letting the head drop."
        ),
        "Dumbbell Bench Press": ExerciseGuidance(
            steps: [
                "Lie on the bench with feet planted and dumbbells over the chest.",
                "Lower the dumbbells until elbows are slightly below the torso.",
                "Press up and in until the weights return over the chest."
            ],
            proTip: "Keep shoulder blades set against the bench for a stable press.",
            avoid: "Avoid bouncing at the bottom or letting wrists bend backward."
        ),
        "Incline Dumbbell Press": ExerciseGuidance(
            steps: [
                "Set the bench to a low incline and start dumbbells near upper chest level.",
                "Press up over the shoulders while keeping ribs down.",
                "Lower with control until the upper chest opens comfortably."
            ],
            proTip: "Use a modest incline so the upper chest works without turning it into a shoulder press.",
            avoid: "Avoid shrugging or letting elbows drift too far behind the body."
        ),
        "Machine Chest Press": ExerciseGuidance(
            steps: [
                "Set the seat so handles start around mid-chest height.",
                "Press the handles forward until arms are long without locking hard.",
                "Return slowly until elbows come just behind the torso."
            ],
            proTip: "Keep your back against the pad and drive evenly through both hands.",
            avoid: "Avoid letting shoulders roll forward at the end range."
        ),
        "Smith Machine Bench Press": ExerciseGuidance(
            steps: [
                "Position the bench so the bar tracks over the mid-chest.",
                "Unrack with shoulder blades set and lower the bar under control.",
                "Press back up while keeping feet planted and wrists stacked."
            ],
            proTip: "Set safety stops just below your controlled bottom position.",
            avoid: "Avoid setting the bench too high or pressing toward the neck."
        ),
        "Overhead Cable Triceps Extension": ExerciseGuidance(
            steps: [
                "Face away from the cable with elbows bent and hands behind the head.",
                "Brace the ribs down and extend the elbows until arms are long.",
                "Return slowly while keeping upper arms mostly fixed."
            ],
            proTip: "Let the triceps stretch at the bottom without losing rib position.",
            avoid: "Avoid arching your lower back or letting elbows flare wide."
        ),
        "Close-Grip Push-ups": ExerciseGuidance(
            steps: [
                "Set hands slightly narrower than shoulders with body in a plank line.",
                "Lower with elbows staying close to the ribs.",
                "Press back up by driving through palms and extending the elbows."
            ],
            proTip: "Think chest and triceps together, not just dropping into the shoulders.",
            avoid: "Avoid collapsing through the upper back or letting elbows flare."
        ),
        "Seated Row": ExerciseGuidance(
            steps: [
                "Sit tall with feet braced and arms reaching long.",
                "Pull elbows toward the ribs while keeping the chest lifted.",
                "Return until arms are long and shoulder blades protract under control."
            ],
            proTip: "Pause briefly when elbows pass the torso.",
            avoid: "Avoid leaning far back or yanking with momentum."
        ),
        "Assisted Pull-up": ExerciseGuidance(
            steps: [
                "Set assistance so you can control the full range.",
                "Start from long arms, pull shoulder blades down, then drive elbows toward the ribs.",
                "Lower slowly back to a full controlled hang."
            ],
            proTip: "Use less assistance only when reps stay smooth.",
            avoid: "Avoid kicking, craning the neck, or stopping short at the bottom."
        ),
        "Cable Row": ExerciseGuidance(
            steps: [
                "Set the cable around mid-torso height and stand or sit tall.",
                "Pull the handle toward the ribs with elbows close.",
                "Reach forward under control without rounding the lower back."
            ],
            proTip: "Let the shoulder blade move, then finish by squeezing it back.",
            avoid: "Avoid shrugging or turning the row into a torso swing."
        ),
        "Dumbbell Row": ExerciseGuidance(
            steps: [
                "Support one hand on a bench or hinge with a flat back.",
                "Pull the dumbbell toward the hip, keeping the elbow close.",
                "Lower until the arm is long without rotating the torso."
            ],
            proTip: "Aim the elbow toward the back pocket to bias the lats.",
            avoid: "Avoid twisting open or pulling the weight toward the shoulder."
        ),
        "Cable Curl": ExerciseGuidance(
            steps: [
                "Stand tall facing the low cable with elbows near the ribs.",
                "Curl the handle up without moving the upper arms.",
                "Lower until elbows are straight while keeping cable tension."
            ],
            proTip: "Keep wrists neutral and squeeze the biceps at the top.",
            avoid: "Avoid leaning back or letting elbows drift forward."
        ),
        "Incline Dumbbell Curl": ExerciseGuidance(
            steps: [
                "Sit on an incline bench with arms hanging behind the torso.",
                "Curl the dumbbells while keeping upper arms still.",
                "Lower fully until the biceps stretch under control."
            ],
            proTip: "Use lighter weights than standing curls and own the stretch.",
            avoid: "Avoid swinging or lifting the shoulders off the bench."
        ),
        "Leg Press": ExerciseGuidance(
            steps: [
                "Set feet about shoulder width on the platform.",
                "Lower the sled until knees bend deeply while hips stay down.",
                "Press through the full foot and stop short of hard knee lockout."
            ],
            proTip: "Use a range where the pelvis does not tuck under.",
            avoid: "Avoid knees caving inward or bouncing out of the bottom."
        ),
        "Seated Leg Curl": ExerciseGuidance(
            steps: [
                "Set the pad so knees line up with the machine axis.",
                "Curl heels down and back until hamstrings fully contract.",
                "Return slowly without letting the weight stack slam."
            ],
            proTip: "Pause at the curled position for cleaner hamstring tension.",
            avoid: "Avoid hips lifting off the seat or rushing the return."
        ),
        "Calf Raise": ExerciseGuidance(
            steps: [
                "Stand tall with balls of feet planted and heels free to move.",
                "Rise onto the toes and pause briefly at the top.",
                "Lower slowly until the calves stretch, then repeat."
            ],
            proTip: "Keep pressure through the big toe and second toe.",
            avoid: "Avoid bouncing or rolling ankles outward."
        ),
        "Dumbbell Lateral Raise": ExerciseGuidance(
            steps: [
                "Stand tall with dumbbells by the sides and elbows softly bent.",
                "Raise arms out to the sides until hands reach about shoulder height.",
                "Lower slowly without letting the weights swing."
            ],
            proTip: "Lead with elbows and keep traps relaxed.",
            avoid: "Avoid shrugging or turning the thumbs sharply downward."
        ),
        "Cable Lateral Raise": ExerciseGuidance(
            steps: [
                "Set the cable low and stand side-on with the handle in the outside hand.",
                "Raise the arm out to the side with a slight elbow bend.",
                "Lower across the body under control while keeping tension."
            ],
            proTip: "Start light and keep the motion smooth from the side delt.",
            avoid: "Avoid leaning away so much that momentum does the work."
        ),
        "Machine Shoulder Press": ExerciseGuidance(
            steps: [
                "Adjust the seat so handles start around shoulder height.",
                "Brace the torso and press overhead until arms are long.",
                "Lower to the start position with control."
            ],
            proTip: "Keep ribs down and back supported throughout the press.",
            avoid: "Avoid shrugging hard or letting elbows drift far behind the body."
        ),
        "Dead Bug": ExerciseGuidance(
            steps: [
                "Lie on your back with hips and knees bent and arms above shoulders.",
                "Brace abs, then extend the opposite arm and leg slowly.",
                "Return to center and alternate sides without the low back lifting."
            ],
            proTip: "Exhale as the limbs extend to keep ribs down.",
            avoid: "Avoid speed or range that makes the back arch."
        ),
        "Side Plank": ExerciseGuidance(
            steps: [
                "Set the elbow under the shoulder and stack feet or stagger them.",
                "Lift hips until the body forms a straight line.",
                "Hold while breathing and keeping the top hip stacked."
            ],
            proTip: "Push the floor away to keep the shoulder stable.",
            avoid: "Avoid rolling the chest down or letting hips sag."
        ),
        "Pallof Press": ExerciseGuidance(
            steps: [
                "Stand side-on to a cable or band with hands at the chest.",
                "Brace and press the hands straight forward without rotating.",
                "Bring hands back to the chest under control."
            ],
            proTip: "Use a stance that lets the core resist rotation cleanly.",
            avoid: "Avoid twisting toward the anchor or shrugging."
        ),
        "Lat Prayer Stretch": ExerciseGuidance(
            steps: [
                "Kneel facing a bench or box and place hands on the surface.",
                "Sit hips back while keeping arms long.",
                "Let the chest sink gently until the lats stretch."
            ],
            proTip: "Turn thumbs up slightly to make the shoulder position friendlier.",
            avoid: "Avoid forcing the chest down or pinching the shoulders."
        ),
        "Thread the Needle": ExerciseGuidance(
            steps: [
                "Start on hands and knees with hips over knees.",
                "Slide one arm under the body and rotate the chest toward the floor.",
                "Breathe into the upper back, return to center, then switch sides."
            ],
            proTip: "Keep hips mostly still so the rotation comes from the upper back.",
            avoid: "Avoid pressing the neck into the floor or rushing the rotation."
        ),
        "Doorway Chest Stretch": ExerciseGuidance(
            steps: [
                "Place forearm on a doorway with elbow around shoulder height.",
                "Step through gently until the front of the chest stretches.",
                "Hold with ribs down, then switch sides."
            ],
            proTip: "Change elbow height slightly to find the best chest stretch.",
            avoid: "Avoid twisting aggressively or letting the shoulder roll forward."
        ),
        "Wrist Flexor Stretch": ExerciseGuidance(
            steps: [
                "Extend one arm with palm facing up.",
                "Use the opposite hand to gently draw fingers back.",
                "Hold light tension, then switch sides."
            ],
            proTip: "Keep the elbow long but not aggressively locked.",
            avoid: "Avoid numbness, tingling, or pulling on individual fingers hard."
        ),
        "Hip Flexor Lunge Stretch": ExerciseGuidance(
            steps: [
                "Set a half-kneeling lunge with the back knee padded.",
                "Tuck the pelvis and squeeze the back glute.",
                "Shift forward gently until the front of the hip stretches."
            ],
            proTip: "Reach the same-side arm overhead if you need more side-body length.",
            avoid: "Avoid arching the lower back to fake more range."
        ),
        "Standing Quad Stretch": ExerciseGuidance(
            steps: [
                "Stand tall and hold a wall or rack for balance.",
                "Bend one knee and hold the ankle behind you.",
                "Pull heel toward glute while keeping knees close, then switch sides."
            ],
            proTip: "Squeeze the glute on the stretching side to protect the low back.",
            avoid: "Avoid yanking the foot or letting the knee flare far outward."
        ),
        "Cobra Press-Up": ExerciseGuidance(
            steps: [
                "Lie face down with hands under or slightly ahead of shoulders.",
                "Press the chest up while hips stay heavy toward the floor.",
                "Lower back down slowly and repeat or hold gently."
            ],
            proTip: "Use only as much arm pressure as your low back tolerates comfortably.",
            avoid: "Avoid pinching pain or forcing end range."
        ),
        "Cat-Cow": ExerciseGuidance(
            steps: [
                "Start on hands and knees with a neutral spine.",
                "Round the back up and tuck the pelvis for cat.",
                "Reverse by gently arching and lifting the chest for cow."
            ],
            proTip: "Move segment by segment with slow breathing.",
            avoid: "Avoid forcing the neck into extreme positions."
        ),
        "Medicine ball rotational throw": ExerciseGuidance(
            steps: [
                "Stand side-on to a wall with the ball near the back hip.",
                "Drive from hips and trunk to throw the ball into the wall.",
                "Catch or retrieve, reset fully, and repeat with crisp reps."
            ],
            proTip: "Power should start from the ground and hips, not just the arms.",
            avoid: "Avoid rapid sloppy reps or twisting through a soft front knee."
        ),
        "Split squat": ExerciseGuidance(
            steps: [
                "Set a long staggered stance with the front foot flat.",
                "Lower straight down until the front thigh works hard.",
                "Drive through the front foot to return tall."
            ],
            proTip: "Keep pelvis level and torso stacked over the hips.",
            avoid: "Avoid bouncing, short stance, or front knee collapse."
        ),
        "Single-leg Romanian deadlift": ExerciseGuidance(
            steps: [
                "Stand on one leg with a soft knee and hips square.",
                "Hinge back as the free leg reaches behind you.",
                "Return by driving the hip forward and keeping balance."
            ],
            proTip: "Reach long through the back heel to keep the pelvis from opening.",
            avoid: "Avoid rounding the back or rotating the torso open."
        ),
        "Cable Woodchop": ExerciseGuidance(
            steps: [
                "Set the cable high or low depending on the chop direction.",
                "Brace and rotate through the trunk and hips as the hands travel across the body.",
                "Return slowly to the start without losing stance."
            ],
            proTip: "Let the hips and ribs rotate together like an athletic swing.",
            avoid: "Avoid pulling only with arms or letting the cable yank you back."
        ),
        "Lateral lunge": ExerciseGuidance(
            steps: [
                "Step wide to one side with toes mostly forward.",
                "Sit into the stepping hip while the other leg stays long.",
                "Push the ground away to return to the start."
            ],
            proTip: "Keep the working foot flat and chest proud.",
            avoid: "Avoid knee collapse or shifting weight onto the toes."
        ),
        "External rotation with band": ExerciseGuidance(
            steps: [
                "Anchor a light band at elbow height and pin the elbow near the ribs.",
                "Rotate the hand outward while keeping the upper arm still.",
                "Return slowly until the forearm points forward."
            ],
            proTip: "Place a small towel between elbow and ribs to keep position clean.",
            avoid: "Avoid twisting the torso or using a band that is too heavy."
        ),
        "Copenhagen side plank": ExerciseGuidance(
            steps: [
                "Set the top leg on a bench and elbow under shoulder.",
                "Lift hips into a side plank while the bottom leg assists as needed.",
                "Hold with hips high, then lower under control."
            ],
            proTip: "Start with the knee on the bench before progressing to the foot.",
            avoid: "Avoid sagging hips or sharp groin discomfort."
        ),
        "Jog, side shuffle, back pedal": ExerciseGuidance(
            steps: [
                "Start with an easy jog for 10 to 15 seconds to raise temperature.",
                "Switch to short side shuffles with hips low and feet light.",
                "Finish with controlled back pedals, keeping eyes forward and steps short."
            ],
            proTip: "Change direction smoothly every few steps so ankles and hips warm up together.",
            avoid: "Avoid crossing feet during shuffles or leaning back during back pedals."
        ),
        "Arm circles to scapular hugs": ExerciseGuidance(
            steps: [
                "Stand tall and make small arm circles forward and backward.",
                "Gradually widen the circles while keeping ribs stacked over the pelvis.",
                "Open the arms wide, then wrap them across the chest and alternate the top arm."
            ],
            proTip: "Let the shoulder blades glide instead of forcing the arms behind you.",
            avoid: "Avoid shrugging, arching the back, or swinging past a comfortable range."
        ),
        "Front and lateral leg swings": ExerciseGuidance(
            steps: [
                "Hold a post or wall lightly and stand tall on one leg.",
                "Swing the free leg forward and back under control for half the time.",
                "Turn slightly and swing side to side, then switch legs."
            ],
            proTip: "Use a range you can control without the torso rocking.",
            avoid: "Avoid kicking aggressively or twisting the standing knee."
        ),
        "Walking lunge, reach, calf raise": ExerciseGuidance(
            steps: [
                "Step into a long lunge and reach both arms overhead.",
                "Keep the front foot flat while the back hip opens.",
                "Drive up, rise briefly onto the front toes, then step into the next rep."
            ],
            proTip: "Move slowly enough to feel hip extension before the calf raise.",
            avoid: "Avoid a short step, knee collapse, or bouncing out of the lunge."
        ),
        "High knees, butt kicks, pogo hops": ExerciseGuidance(
            steps: [
                "Run in place with high knees and a tall chest for the first segment.",
                "Switch to butt kicks, keeping knees pointed down and cadence quick.",
                "Finish with small pogo hops from the ankles with soft knees."
            ],
            proTip: "Stay springy and relaxed; this should prime speed, not drain you.",
            avoid: "Avoid stomping, leaning back, or turning the pogo hops into deep squats."
        ),
        "Shadow bat, throw, bowl ramp": ExerciseGuidance(
            steps: [
                "Rehearse a smooth batting swing at easy effort.",
                "Flow into a light throwing pattern with the shoulder relaxed.",
                "Finish with a bowling walk-through, building effort gradually."
            ],
            proTip: "Use 50, 70, then 80 percent effort so the nervous system ramps up cleanly.",
            avoid: "Avoid max-speed swings or throws before the body is warm."
        ),
        "Wrist rolls and finger pumps": ExerciseGuidance(
            steps: [
                "Open and close the hands quickly for several reps.",
                "Circle both wrists in each direction with relaxed shoulders.",
                "Turn palms up and down slowly to warm pronation and supination."
            ],
            proTip: "Keep the grip loose so the forearms feel warm rather than pumped.",
            avoid: "Avoid forcing wrist range or clenching hard for the whole interval."
        ),
        "Shadow batting hip turn": ExerciseGuidance(
            steps: [
                "Set a batting stance with knees soft and head steady.",
                "Step and rotate the hips as if initiating a controlled shot.",
                "Reset the stance between reps and alternate easy swing patterns."
            ],
            proTip: "Let the hips lead while the head stays quiet over the base.",
            avoid: "Avoid spinning on a locked knee or over-rotating through the lower back."
        ),
        "Crease shuffle to sprint start": ExerciseGuidance(
            steps: [
                "Shuffle laterally two to three quick steps with hips low.",
                "Plant the outside foot under control.",
                "Drive into two short sprint-start steps, then reset."
            ],
            proTip: "Keep the first sprint steps short and sharp like running between wickets.",
            avoid: "Avoid crossing feet, landing tall, or letting knees cave inward."
        ),
        "Standing thoracic openers": ExerciseGuidance(
            steps: [
                "Stand tall with hands lightly across the chest or behind the head.",
                "Rotate the rib cage to one side while hips stay mostly square.",
                "Return through center and rotate the other way with steady breathing."
            ],
            proTip: "Think ribs turning over hips, not the lower back twisting hard.",
            avoid: "Avoid forcing the neck or letting the pelvis spin with every rep."
        ),
        "Wrist rolls and bat grip pulses": ExerciseGuidance(
            steps: [
                "Hold an imaginary bat or light handle with relaxed shoulders.",
                "Pulse the grip open and closed without squeezing hard.",
                "Finish with slow wrist circles in both directions."
            ],
            proTip: "Keep the pulses quick but light so bat control feels responsive.",
            avoid: "Avoid fatiguing the forearms before batting."
        ),
        "Bowling walk-through build-ups": ExerciseGuidance(
            steps: [
                "Start with a walking bowling action and easy arm speed.",
                "Progress to a smooth walk-through with trunk rotation and hip drive.",
                "Finish near match rhythm without going all-out."
            ],
            proTip: "Build effort in small jumps so shoulder, trunk, and front leg sync up.",
            avoid: "Avoid abrupt max-effort deliveries or collapsing through the front knee."
        ),
        "Thoracic rotations with reach": ExerciseGuidance(
            steps: [
                "Set a stable half-kneeling or split stance with hips square.",
                "Rotate the chest toward the working side and reach the arm long.",
                "Return to center slowly, then repeat with control."
            ],
            proTip: "Exhale as you rotate to find upper-back range without forcing it.",
            avoid: "Avoid twisting through the low back or letting the front knee drift inward."
        ),
        "Single-leg balance to calf pop": ExerciseGuidance(
            steps: [
                "Balance on one foot with a slight bend in the knee.",
                "Hinge forward a little while keeping hips level.",
                "Return tall and pop into a small controlled calf raise."
            ],
            proTip: "Own the balance first; the calf pop should be short and crisp.",
            avoid: "Avoid rushing, wobbling through the ankle, or locking the knee."
        ),
        "Scapular wall slides or swimmers": ExerciseGuidance(
            steps: [
                "Stand against a wall for slides or lie face down for swimmers.",
                "Move the arms slowly while shoulder blades glide down and around the ribs.",
                "Pause where control is hardest, then return without shrugging."
            ],
            proTip: "Choose the version that keeps the neck relaxed and ribs down.",
            avoid: "Avoid forcing overhead range or pinching the front of the shoulder."
        ),
        "Slow walk with nasal breathing": ExerciseGuidance(
            steps: [
                "Walk at an easy pace after play with shoulders relaxed.",
                "Breathe in through the nose and lengthen each exhale.",
                "Let the heart rate settle before moving into longer holds."
            ],
            proTip: "Use this as the bridge from competition intensity to recovery work.",
            avoid: "Avoid stopping abruptly if you are still breathing hard."
        ),
        "Calf Wall Stretch": ExerciseGuidance(
            steps: [
                "Place both hands on a wall and step one foot back.",
                "Keep the back heel down and toes pointing straight ahead.",
                "Lean forward until the calf stretches, hold, then switch sides."
            ],
            proTip: "Slightly bend the back knee on a second hold to bias the soleus.",
            avoid: "Avoid turning the back foot outward or bouncing into the wall."
        ),
        "Half-kneeling hip flexor and quad": ExerciseGuidance(
            steps: [
                "Set a half-kneeling stance with the back knee padded on the mat.",
                "Tuck the pelvis slightly and squeeze the back-side glute.",
                "Shift forward gently until the front of the hip and quad stretch."
            ],
            proTip: "Keep ribs down so the stretch stays in the hip instead of the low back.",
            avoid: "Avoid arching the lower back or driving the front knee far past control."
        ),
        "Seated Hamstring Stretch": ExerciseGuidance(
            steps: [
                "Sit tall with one leg extended and the other leg relaxed.",
                "Hinge forward from the hips with a long spine.",
                "Hold mild hamstring tension, then switch sides."
            ],
            proTip: "Reach the chest forward rather than rounding down toward the knee.",
            avoid: "Avoid locking the knee aggressively or pulling on the toes."
        ),
        "Child's Pose": ExerciseGuidance(
            steps: [
                "Kneel on the mat and sit hips back toward the heels.",
                "Reach both arms forward and let the chest soften toward the floor.",
                "Walk hands to each side to bias the lats, then return to center."
            ],
            proTip: "Breathe into the ribs and upper back on each long exhale.",
            avoid: "Avoid forcing hips to heels if knees feel irritated."
        ),
        "Cross-Body Shoulder Stretch": ExerciseGuidance(
            steps: [
                "Stand tall and bring one arm across the chest.",
                "Use the opposite arm to gently draw it closer without lifting the shoulder.",
                "Hold with the neck relaxed, then switch sides."
            ],
            proTip: "Keep the stretched shoulder down away from the ear.",
            avoid: "Avoid pulling directly on the elbow joint or twisting the torso."
        ),
        "Forearm flexor and extensor stretch": ExerciseGuidance(
            steps: [
                "Extend one arm with palm up and gently draw fingers back.",
                "Hold briefly, then turn palm down and gently flex the wrist.",
                "Repeat on the other side with relaxed shoulders."
            ],
            proTip: "Use light pressure; forearm tissue responds better to patience than force.",
            avoid: "Avoid numbness, tingling, or aggressive finger pulling."
        ),
        "Open-book trunk rotation": ExerciseGuidance(
            steps: [
                "Lie on one side with knees stacked and bent.",
                "Reach the top arm forward, then open it across the body toward the floor.",
                "Breathe into the open position, return slowly, then switch sides."
            ],
            proTip: "Let the upper back rotate while knees stay stacked.",
            avoid: "Avoid forcing the shoulder to the floor or rolling the hips open."
        ),
        "Bat grip forearm release": ExerciseGuidance(
            steps: [
                "Bring palms together in a gentle prayer stretch.",
                "Lower the hands until the forearms feel light tension.",
                "Switch to the back-of-hands position briefly, then shake the hands loose."
            ],
            proTip: "Keep pressure mild so grip feels restored after batting.",
            avoid: "Avoid collapsing the wrists sharply or stretching into tingling."
        ),
        "Overhead lat and triceps side stretch": ExerciseGuidance(
            steps: [
                "Reach one arm overhead and bend the elbow so the hand moves behind the head.",
                "Hold the elbow lightly and side bend away from the stretching side.",
                "Breathe into the ribs and lat, then switch sides."
            ],
            proTip: "Keep both feet grounded so the side body lengthens evenly.",
            avoid: "Avoid cranking the neck or arching the lower back."
        ),
        "Adductor rock-back hold": ExerciseGuidance(
            steps: [
                "Start on hands and knees, then extend one knee wide to the side.",
                "Keep the spine long and rock hips back until the inner thigh stretches.",
                "Hold mild tension, return forward, then switch sides."
            ],
            proTip: "Point the extended-side toes forward or slightly up based on comfort.",
            avoid: "Avoid sinking into knee pain or rounding hard through the back."
        )
    ]
}

enum MuscleMapOrientation {
    case front
    case back
}

private extension DetailedMuscleGroup {
    var preferredMapOrientation: MuscleMapOrientation {
        switch self {
        case .latissimusDorsi, .upperBack, .lowerBack,
             .hamstrings, .gluteusMaximus, .gluteusMedius, .gluteusMinimus,
             .rearDeltoids, .triceps, .forearmExtensors,
             .gastrocnemius, .soleus:
            .back
        case .upperChest, .midChest, .lowerChest,
             .quadriceps, .adductors,
             .frontDeltoids, .sideDeltoids,
             .biceps, .forearmFlexors, .brachioradialis,
             .rectusAbdominis, .obliques:
            .front
        }
    }
}

struct MuscleImpactPairMap: View {
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?
    var supporting: [DetailedMuscleGroup] = []

    var body: some View {
        GeometryReader { proxy in
            let spacing = max(3, proxy.size.width * 0.08)
            let mapWidth = max(1, (proxy.size.width - spacing) / 2)

            HStack(spacing: spacing) {
                MuscleImpactMap(
                    primary: primary,
                    secondary: secondary,
                    supporting: supporting,
                    orientation: .front
                )
                .frame(width: mapWidth, height: proxy.size.height)

                MuscleImpactMap(
                    primary: primary,
                    secondary: secondary,
                    supporting: supporting,
                    orientation: .back
                )
                .frame(width: mapWidth, height: proxy.size.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
    }
}

struct FocusedMuscleImpactMap: View {
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?
    var supporting: [DetailedMuscleGroup] = []

    private var focus: MuscleMapFocus {
        primary.compactMapFocus
    }

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let baseHeight = diameter * 1.22
            let baseWidth = baseHeight * 0.64

            ZStack {
                Circle()
                    .fill(Color.coachSurfaceElevated)

                MuscleImpactMap(
                    primary: primary,
                    secondary: secondary,
                    supporting: supporting,
                    orientation: primary.preferredMapOrientation
                )
                .frame(width: baseWidth, height: baseHeight)
                .scaleEffect(focus.scale, anchor: .center)
                .offset(x: diameter * focus.offsetX, y: diameter * focus.offsetY)
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.coachBorder, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
    }
}

struct ExerciseMuscleTargetBadge: View {
    var exerciseName: String
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?
    var supporting: [DetailedMuscleGroup] = []

    @State private var isShowingExpandedMap = false

    private var targetImage: UIImage? {
        guard let assetName = ExerciseMuscleTargetLibrary.assetName(
            for: exerciseName,
            primary: primary
        ) else {
            return nil
        }

        return UIImage(named: assetName)
    }

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)

            ZStack {
                Circle()
                    .fill(Color.coachSurfaceElevated)

                if let targetImage {
                    Image(uiImage: targetImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: diameter, height: diameter)
                } else {
                    MuscleImpactPairMap(
                        primary: primary,
                        secondary: secondary,
                        supporting: supporting
                    )
                    .padding(diameter * 0.14)
                }
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.coachBorder, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                isShowingExpandedMap = true
            }
        }
        .accessibilityLabel("Open muscle diagram for \(exerciseName)")
        .accessibilityHint("Shows a larger front and back muscle map")
        .accessibilityAddTraits(.isButton)
        .sheet(isPresented: $isShowingExpandedMap) {
            ExerciseMuscleTargetSheet(
                exerciseName: exerciseName,
                primary: primary,
                secondary: secondary,
                supporting: supporting,
                targetImage: targetImage
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct ExerciseMuscleTargetSheet: View {
    @Environment(\.dismiss) private var dismiss

    var exerciseName: String
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?
    var supporting: [DetailedMuscleGroup]
    var targetImage: UIImage?

    private var uniqueSupportingMuscles: [DetailedMuscleGroup] {
        supporting.reduce(into: [DetailedMuscleGroup]()) { muscles, muscle in
            let isPrimary = muscle == primary
            let isSecondary = secondary.map { $0 == muscle } ?? false

            if !isPrimary && !isSecondary && !muscles.contains(muscle) {
                muscles.append(muscle)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exerciseName)
                                .font(.title2.weight(.bold))
                                .lineLimit(2)

                            Text("Target muscles")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.coachSecondaryText)
                        }

                        expandedMap

                        VStack(alignment: .leading, spacing: 10) {
                            MuscleTargetLegendRow(title: "Primary", muscle: primary, opacity: 1.0)

                            if let secondary {
                                MuscleTargetLegendRow(title: "Secondary", muscle: secondary, opacity: 0.64)
                            }

                            ForEach(uniqueSupportingMuscles) { muscle in
                                MuscleTargetLegendRow(title: "Supporting", muscle: muscle, opacity: 0.34)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Muscle Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var expandedMap: some View {
        Group {
            if let targetImage {
                GeneratedMuscleTargetExpandedCard(image: targetImage)
            } else {
                VStack(spacing: 12) {
                    LargeMuscleMapPanel(
                        title: "Front",
                        primary: primary,
                        secondary: secondary,
                        supporting: supporting,
                        orientation: .front
                    )

                    LargeMuscleMapPanel(
                        title: "Back",
                        primary: primary,
                        secondary: secondary,
                        supporting: supporting,
                        orientation: .back
                    )
                }
            }
        }
    }
}

private struct GeneratedMuscleTargetExpandedCard: View {
    var image: UIImage

    var body: some View {
        CoachCard(padding: 14) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(minHeight: 430)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct LargeMuscleMapPanel: View {
    var title: String
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?
    var supporting: [DetailedMuscleGroup]
    var orientation: MuscleMapOrientation

    var body: some View {
        CoachCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: "figure.stand")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.coachAccent)

                MuscleImpactMap(
                    primary: primary,
                    secondary: secondary,
                    supporting: supporting,
                    orientation: orientation
                )
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 430)
            }
        }
    }
}

private struct MuscleTargetLegendRow: View {
    var title: String
    var muscle: DetailedMuscleGroup
    var opacity: Double

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.coachAccent.opacity(opacity))
                .frame(width: 12, height: 12)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.coachSecondaryText)
                .frame(width: 86, alignment: .leading)

            Text(muscle.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.coachSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.coachBorder, lineWidth: 1)
        }
    }
}

struct MuscleGroupGlyph: View {
    var group: MuscleGroup

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                MiniBodyBase()
                    .stroke(Color.coachSecondaryText, lineWidth: max(1, size * 0.065))
                    .opacity(0.78)

                glyphHighlight
            }
            .frame(width: size, height: size)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var glyphHighlight: some View {
        switch group {
        case .chest:
            ChestGlyphHighlight()
                .fill(Color.coachAccent)
        case .back:
            BackGlyphHighlight()
                .fill(Color.coachAccent)
        case .legs:
            LegsGlyphHighlight()
                .fill(Color.coachAccent)
        case .glutes:
            GlutesGlyphHighlight()
                .fill(Color.coachAccent)
        case .shoulders:
            ShouldersGlyphHighlight()
                .fill(Color.coachAccent)
        case .biceps:
            BicepsGlyphHighlight()
                .fill(Color.coachAccent)
        case .triceps:
            TricepsGlyphHighlight()
                .fill(Color.coachAccent)
        case .core:
            CoreGlyphHighlight()
                .fill(Color.coachAccent)
        }
    }
}

private struct MiniBodyBase: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY

        path.addEllipse(in: CGRect(x: x + w * 0.40, y: y + h * 0.06, width: w * 0.20, height: h * 0.18))
        path.addRoundedRect(in: CGRect(x: x + w * 0.32, y: y + h * 0.27, width: w * 0.36, height: h * 0.34), cornerSize: CGSize(width: w * 0.10, height: h * 0.10))

        path.move(to: CGPoint(x: x + w * 0.32, y: y + h * 0.34))
        path.addLine(to: CGPoint(x: x + w * 0.16, y: y + h * 0.58))
        path.move(to: CGPoint(x: x + w * 0.68, y: y + h * 0.34))
        path.addLine(to: CGPoint(x: x + w * 0.84, y: y + h * 0.58))

        path.move(to: CGPoint(x: x + w * 0.42, y: y + h * 0.60))
        path.addLine(to: CGPoint(x: x + w * 0.34, y: y + h * 0.92))
        path.move(to: CGPoint(x: x + w * 0.58, y: y + h * 0.60))
        path.addLine(to: CGPoint(x: x + w * 0.66, y: y + h * 0.92))

        return path
    }
}

private struct ChestGlyphHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.32, width: rect.width * 0.13, height: rect.height * 0.12), cornerSize: CGSize(width: rect.width * 0.04, height: rect.height * 0.04))
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.52, y: rect.minY + rect.height * 0.32, width: rect.width * 0.13, height: rect.height * 0.12), cornerSize: CGSize(width: rect.width * 0.04, height: rect.height * 0.04))
        return path
    }
}

private struct BackGlyphHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.32))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.56))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.54))
        path.closeSubpath()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.65, y: rect.minY + rect.height * 0.32))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.52, y: rect.minY + rect.height * 0.56))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.68, y: rect.minY + rect.height * 0.54))
        path.closeSubpath()
        return path
    }
}

private struct LegsGlyphHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.62, width: rect.width * 0.12, height: rect.height * 0.30), cornerSize: CGSize(width: rect.width * 0.05, height: rect.height * 0.05))
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.54, y: rect.minY + rect.height * 0.62, width: rect.width * 0.12, height: rect.height * 0.30), cornerSize: CGSize(width: rect.width * 0.05, height: rect.height * 0.05))
        return path
    }
}

private struct GlutesGlyphHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.52, width: rect.width * 0.15, height: rect.height * 0.14))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.51, y: rect.minY + rect.height * 0.52, width: rect.width * 0.15, height: rect.height * 0.14))
        return path
    }
}

private struct ShouldersGlyphHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.28, width: rect.width * 0.16, height: rect.height * 0.14))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.59, y: rect.minY + rect.height * 0.28, width: rect.width * 0.16, height: rect.height * 0.14))
        return path
    }
}

private struct BicepsGlyphHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.40, width: rect.width * 0.12, height: rect.height * 0.20), cornerSize: CGSize(width: rect.width * 0.05, height: rect.height * 0.05))
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.40, width: rect.width * 0.12, height: rect.height * 0.20), cornerSize: CGSize(width: rect.width * 0.05, height: rect.height * 0.05))
        return path
    }
}

private struct TricepsGlyphHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.46, width: rect.width * 0.10, height: rect.height * 0.22), cornerSize: CGSize(width: rect.width * 0.05, height: rect.height * 0.05))
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.46, width: rect.width * 0.10, height: rect.height * 0.22), cornerSize: CGSize(width: rect.width * 0.05, height: rect.height * 0.05))
        return path
    }
}

private struct CoreGlyphHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: CGRect(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.43, width: rect.width * 0.16, height: rect.height * 0.20), cornerRadius: rect.width * 0.04)
    }
}

private struct MuscleMapFocus {
    var scale: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
}

private extension DetailedMuscleGroup {
    var compactMapFocus: MuscleMapFocus {
        switch self {
        case .upperChest, .midChest, .lowerChest,
             .latissimusDorsi, .upperBack, .lowerBack,
             .frontDeltoids, .sideDeltoids, .rearDeltoids:
            MuscleMapFocus(scale: 1.58, offsetX: 0, offsetY: 0.20)
        case .biceps, .triceps,
             .forearmFlexors, .forearmExtensors, .brachioradialis:
            MuscleMapFocus(scale: 1.45, offsetX: 0, offsetY: 0.12)
        case .rectusAbdominis, .obliques:
            MuscleMapFocus(scale: 1.55, offsetX: 0, offsetY: -0.02)
        case .gluteusMaximus, .gluteusMedius, .gluteusMinimus:
            MuscleMapFocus(scale: 1.70, offsetX: 0, offsetY: -0.18)
        case .quadriceps, .hamstrings, .adductors:
            MuscleMapFocus(scale: 1.76, offsetX: 0, offsetY: -0.28)
        case .gastrocnemius, .soleus:
            MuscleMapFocus(scale: 1.88, offsetX: 0, offsetY: -0.55)
        }
    }
}

struct MuscleImpactMap: View {
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?
    var supporting: [DetailedMuscleGroup] = []
    var orientation: MuscleMapOrientation = .front

    private var highlightedMuscles: [DetailedMuscleGroup] {
        var muscles: [DetailedMuscleGroup] = []

        for muscle in supporting where muscle != primary && !(secondary.map { $0 == muscle } ?? false) && !muscles.contains(muscle) {
            muscles.append(muscle)
        }

        if let secondary, secondary != primary {
            muscles.append(secondary)
        }

        muscles.append(primary)
        return muscles
    }

    var body: some View {
        Canvas { context, size in
            drawBaseFigure(in: &context, size: size)
            drawOrientationDetails(in: &context, size: size)

            for muscle in highlightedMuscles {
                let isSecondary = secondary.map { $0 == muscle } ?? false
                let opacity = muscle == primary ? 1.0 : (isSecondary ? 0.64 : 0.34)
                drawHighlight(for: muscle, in: &context, size: size, color: Color.coachAccent.opacity(opacity))
            }

            drawFigureOutline(in: &context, size: size)
            drawFigureLandmarks(in: &context, size: size)
        }
        .aspectRatio(0.64, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func drawBaseFigure(in context: inout GraphicsContext, size: CGSize) {
        for path in basePaths(size: size) {
            context.fill(path, with: .color(Color.white.opacity(0.14)))
        }
    }

    private func drawFigureOutline(in context: inout GraphicsContext, size: CGSize) {
        for path in basePaths(size: size) {
            context.stroke(path, with: .color(Color.white.opacity(0.20)), lineWidth: 1)
        }
    }

    private func drawOrientationDetails(in context: inout GraphicsContext, size: CGSize) {
        guard orientation == .back else { return }

        context.fill(backHairPath(size: size), with: .color(Color.white.opacity(0.25)))
        context.stroke(backHairPath(size: size), with: .color(Color.white.opacity(0.18)), lineWidth: 0.7)
    }

    private func drawHighlight(
        for muscle: DetailedMuscleGroup,
        in context: inout GraphicsContext,
        size: CGSize,
        color: Color
    ) {
        guard isVisible(muscle, on: orientation) else { return }

        for path in highlightPaths(for: muscle, size: size) {
            context.fill(path, with: .color(color))
        }
    }

    private func basePaths(size: CGSize) -> [Path] {
        [
            headPath(size: size),
            neckPath(size: size),
            torsoPath(size: size),
            pelvisPath(size: size),
            leftUpperArmPath(size: size),
            rightUpperArmPath(size: size),
            leftForearmPath(size: size),
            rightForearmPath(size: size),
            leftHandPath(size: size),
            rightHandPath(size: size),
            leftThighPath(size: size),
            rightThighPath(size: size),
            leftCalfPath(size: size),
            rightCalfPath(size: size),
            leftFootPath(size: size),
            rightFootPath(size: size)
        ]
    }

    private func highlightPaths(for muscle: DetailedMuscleGroup, size: CGSize) -> [Path] {
        switch muscle {
        case .upperChest:
            return [
                leftUpperPecPath(size: size),
                rightUpperPecPath(size: size)
            ]
        case .midChest:
            return [
                leftMidPecPath(size: size),
                rightMidPecPath(size: size)
            ]
        case .lowerChest:
            return [
                leftLowerPecPath(size: size),
                rightLowerPecPath(size: size)
            ]
        case .latissimusDorsi:
            return [
                leftLatPath(size: size),
                rightLatPath(size: size)
            ]
        case .upperBack:
            return [
                leftUpperBackPath(size: size),
                rightUpperBackPath(size: size),
                upperSpinePath(size: size)
            ]
        case .lowerBack:
            return [
                leftLowerBackPath(size: size),
                rightLowerBackPath(size: size)
            ]
        case .quadriceps:
            return [
                leftQuadPath(size: size),
                rightQuadPath(size: size)
            ]
        case .hamstrings:
            return [
                leftHamstringPath(size: size),
                rightHamstringPath(size: size)
            ]
        case .adductors:
            return [
                leftAdductorPath(size: size),
                rightAdductorPath(size: size)
            ]
        case .gluteusMaximus:
            return [
                leftGluteMaxPath(size: size),
                rightGluteMaxPath(size: size)
            ]
        case .gluteusMedius:
            return [
                leftGluteMedPath(size: size),
                rightGluteMedPath(size: size)
            ]
        case .gluteusMinimus:
            return [
                ellipse(37, 88, 7, 8, size: size),
                ellipse(56, 88, 7, 8, size: size)
            ]
        case .frontDeltoids:
            return [
                leftFrontDeltPath(size: size),
                rightFrontDeltPath(size: size)
            ]
        case .sideDeltoids:
            return [
                leftSideDeltPath(size: size),
                rightSideDeltPath(size: size)
            ]
        case .rearDeltoids:
            return [
                leftRearDeltPath(size: size),
                rightRearDeltPath(size: size)
            ]
        case .biceps:
            return [
                leftBicepsPath(size: size),
                rightBicepsPath(size: size)
            ]
        case .triceps:
            return [
                leftTricepsPath(size: size),
                rightTricepsPath(size: size)
            ]
        case .forearmFlexors:
            return [
                leftForearmFlexorPath(size: size),
                rightForearmFlexorPath(size: size)
            ]
        case .forearmExtensors:
            return [
                leftForearmExtensorPath(size: size),
                rightForearmExtensorPath(size: size)
            ]
        case .brachioradialis:
            return [
                leftBrachioradialisPath(size: size),
                rightBrachioradialisPath(size: size)
            ]
        case .gastrocnemius:
            return [
                leftCalfHighlightPath(size: size),
                rightCalfHighlightPath(size: size)
            ]
        case .soleus:
            return [
                leftSoleusPath(size: size),
                rightSoleusPath(size: size)
            ]
        case .rectusAbdominis:
            return [
                rectusAbdominisPath(size: size)
            ]
        case .obliques:
            return [
                leftObliquePath(size: size),
                rightObliquePath(size: size)
            ]
        }
    }

    private func drawFigureLandmarks(in context: inout GraphicsContext, size: CGSize) {
        let stroke = GraphicsContext.Shading.color(Color.white.opacity(0.13))
        let subtleStroke = GraphicsContext.Shading.color(Color.black.opacity(0.16))

        for path in landmarkPaths(size: size) {
            context.stroke(path, with: stroke, lineWidth: 0.7)
        }

        for path in shadowSeparationPaths(size: size) {
            context.stroke(path, with: subtleStroke, lineWidth: 0.6)
        }
    }

    private func landmarkPaths(size: CGSize) -> [Path] {
        switch orientation {
        case .front:
            [
                curvedLine([(43, 30), (50, 33), (57, 30)], size: size),
                curvedLine([(36, 37), (45, 40), (50, 40), (55, 40), (64, 37)], size: size),
                curvedLine([(50, 43), (50, 58), (50, 76), (50, 91)], size: size),
                curvedLine([(41, 61), (50, 63), (59, 61)], size: size),
                curvedLine([(43, 70), (50, 71), (57, 70)], size: size),
                curvedLine([(44, 79), (50, 80), (56, 79)], size: size),
                curvedLine([(37, 79), (44, 84), (50, 86), (56, 84), (63, 79)], size: size),
                curvedLine([(38, 100), (44, 104), (48, 108)], size: size),
                curvedLine([(62, 100), (56, 104), (52, 108)], size: size),
                curvedLine([(35, 128), (40, 130), (45, 128)], size: size),
                curvedLine([(55, 128), (60, 130), (65, 128)], size: size)
            ]
        case .back:
            [
                curvedLine([(50, 29), (50, 43), (50, 62), (50, 88)], size: size),
                curvedLine([(36, 38), (43, 42), (47, 52), (45, 65)], size: size),
                curvedLine([(64, 38), (57, 42), (53, 52), (55, 65)], size: size),
                curvedLine([(34, 53), (43, 58), (49, 63)], size: size),
                curvedLine([(66, 53), (57, 58), (51, 63)], size: size),
                curvedLine([(37, 82), (43, 88), (50, 90), (57, 88), (63, 82)], size: size),
                curvedLine([(50, 91), (50, 97), (50, 105)], size: size),
                curvedLine([(35, 128), (40, 130), (45, 128)], size: size),
                curvedLine([(55, 128), (60, 130), (65, 128)], size: size)
            ]
        }
    }

    private func shadowSeparationPaths(size: CGSize) -> [Path] {
        switch orientation {
        case .front:
            [
                curvedLine([(32, 47), (31, 61), (34, 77)], size: size),
                curvedLine([(68, 47), (69, 61), (66, 77)], size: size),
                curvedLine([(24, 70), (22, 84), (19, 101)], size: size),
                curvedLine([(76, 70), (78, 84), (81, 101)], size: size)
            ]
        case .back:
            [
                curvedLine([(31, 47), (33, 62), (37, 82)], size: size),
                curvedLine([(69, 47), (67, 62), (63, 82)], size: size),
                curvedLine([(25, 70), (23, 84), (20, 101)], size: size),
                curvedLine([(75, 70), (77, 84), (80, 101)], size: size),
                curvedLine([(36, 104), (40, 118), (39, 133)], size: size),
                curvedLine([(64, 104), (60, 118), (61, 133)], size: size)
            ]
        }
    }

    private func isVisible(_ muscle: DetailedMuscleGroup, on orientation: MuscleMapOrientation) -> Bool {
        switch orientation {
        case .front:
            switch muscle {
            case .upperChest, .midChest, .lowerChest,
                 .quadriceps, .adductors,
                 .frontDeltoids, .sideDeltoids,
                 .biceps, .forearmFlexors, .brachioradialis,
                 .rectusAbdominis, .obliques:
                true
            case .latissimusDorsi, .upperBack, .lowerBack,
                 .hamstrings, .gluteusMaximus, .gluteusMedius, .gluteusMinimus,
                 .rearDeltoids, .triceps, .forearmExtensors,
                 .gastrocnemius, .soleus:
                false
            }
        case .back:
            switch muscle {
            case .latissimusDorsi, .upperBack, .lowerBack,
                 .hamstrings, .gluteusMaximus, .gluteusMedius, .gluteusMinimus,
                 .rearDeltoids, .sideDeltoids, .triceps, .forearmExtensors,
                 .gastrocnemius, .soleus:
                true
            case .upperChest, .midChest, .lowerChest,
                 .quadriceps, .adductors,
                 .frontDeltoids, .biceps, .forearmFlexors, .brachioradialis,
                 .rectusAbdominis, .obliques:
                false
            }
        }
    }

    private func headPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(50, 4, size: size))
        path.addCurve(to: point(39, 13, size: size), control1: point(43, 4, size: size), control2: point(39, 8, size: size))
        path.addCurve(to: point(41, 22, size: size), control1: point(39, 17, size: size), control2: point(40, 20, size: size))
        path.addCurve(to: point(50, 27, size: size), control1: point(43, 25, size: size), control2: point(47, 27, size: size))
        path.addCurve(to: point(59, 22, size: size), control1: point(53, 27, size: size), control2: point(57, 25, size: size))
        path.addCurve(to: point(61, 13, size: size), control1: point(60, 20, size: size), control2: point(61, 17, size: size))
        path.addCurve(to: point(50, 4, size: size), control1: point(61, 8, size: size), control2: point(57, 4, size: size))
        path.closeSubpath()
        return path
    }

    private func backHairPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(50, 4, size: size))
        path.addCurve(to: point(40, 12, size: size), control1: point(44, 4, size: size), control2: point(40, 8, size: size))
        path.addCurve(to: point(39, 22, size: size), control1: point(39, 15, size: size), control2: point(39, 19, size: size))
        path.addCurve(to: point(44, 28, size: size), control1: point(40, 25, size: size), control2: point(42, 27, size: size))
        path.addCurve(to: point(47, 21, size: size), control1: point(44, 25, size: size), control2: point(45, 23, size: size))
        path.addCurve(to: point(53, 21, size: size), control1: point(49, 19, size: size), control2: point(51, 19, size: size))
        path.addCurve(to: point(56, 28, size: size), control1: point(55, 23, size: size), control2: point(56, 25, size: size))
        path.addCurve(to: point(61, 22, size: size), control1: point(58, 27, size: size), control2: point(60, 25, size: size))
        path.addCurve(to: point(60, 12, size: size), control1: point(61, 19, size: size), control2: point(61, 15, size: size))
        path.addCurve(to: point(50, 4, size: size), control1: point(60, 8, size: size), control2: point(56, 4, size: size))
        path.closeSubpath()
        return path
    }

    private func neckPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(44, 24, size: size))
        path.addCurve(to: point(56, 24, size: size), control1: point(47, 27, size: size), control2: point(53, 27, size: size))
        path.addLine(to: point(58, 35, size: size))
        path.addCurve(to: point(42, 35, size: size), control1: point(54, 37, size: size), control2: point(46, 37, size: size))
        path.closeSubpath()
        return path
    }

    private func torsoPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(50, 31, size: size))
        path.addCurve(to: point(31, 39, size: size), control1: point(43, 30, size: size), control2: point(35, 33, size: size))
        path.addCurve(to: point(29, 54, size: size), control1: point(27, 43, size: size), control2: point(27, 49, size: size))
        path.addCurve(to: point(35, 76, size: size), control1: point(30, 62, size: size), control2: point(32, 70, size: size))
        path.addCurve(to: point(40, 89, size: size), control1: point(37, 81, size: size), control2: point(39, 86, size: size))
        path.addCurve(to: point(50, 92, size: size), control1: point(43, 91, size: size), control2: point(47, 92, size: size))
        path.addCurve(to: point(60, 89, size: size), control1: point(53, 92, size: size), control2: point(57, 91, size: size))
        path.addCurve(to: point(65, 76, size: size), control1: point(61, 86, size: size), control2: point(63, 81, size: size))
        path.addCurve(to: point(71, 54, size: size), control1: point(68, 70, size: size), control2: point(70, 62, size: size))
        path.addCurve(to: point(69, 39, size: size), control1: point(73, 49, size: size), control2: point(73, 43, size: size))
        path.addCurve(to: point(50, 31, size: size), control1: point(65, 33, size: size), control2: point(57, 30, size: size))
        path.closeSubpath()
        return path
    }

    private func pelvisPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(39, 88, size: size))
        path.addCurve(to: point(50, 91, size: size), control1: point(42, 91, size: size), control2: point(46, 92, size: size))
        path.addCurve(to: point(61, 88, size: size), control1: point(54, 92, size: size), control2: point(58, 91, size: size))
        path.addCurve(to: point(66, 101, size: size), control1: point(64, 92, size: size), control2: point(67, 96, size: size))
        path.addCurve(to: point(54, 107, size: size), control1: point(63, 105, size: size), control2: point(58, 107, size: size))
        path.addCurve(to: point(50, 103, size: size), control1: point(53, 105, size: size), control2: point(52, 103, size: size))
        path.addCurve(to: point(46, 107, size: size), control1: point(48, 103, size: size), control2: point(47, 105, size: size))
        path.addCurve(to: point(34, 101, size: size), control1: point(42, 107, size: size), control2: point(37, 105, size: size))
        path.addCurve(to: point(39, 88, size: size), control1: point(33, 96, size: size), control2: point(36, 92, size: size))
        path.closeSubpath()
        return path
    }

    private func leftUpperArmPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(31, 38, size: size))
        path.addCurve(to: point(23, 51, size: size), control1: point(26, 40, size: size), control2: point(23, 45, size: size))
        path.addCurve(to: point(22, 71, size: size), control1: point(22, 58, size: size), control2: point(21, 65, size: size))
        path.addCurve(to: point(30, 75, size: size), control1: point(24, 76, size: size), control2: point(28, 77, size: size))
        path.addCurve(to: point(37, 54, size: size), control1: point(34, 68, size: size), control2: point(36, 61, size: size))
        path.addCurve(to: point(38, 43, size: size), control1: point(37, 49, size: size), control2: point(38, 46, size: size))
        path.addCurve(to: point(31, 38, size: size), control1: point(36, 40, size: size), control2: point(34, 38, size: size))
        path.closeSubpath()
        return path
    }

    private func rightUpperArmPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(69, 38, size: size))
        path.addCurve(to: point(77, 51, size: size), control1: point(74, 40, size: size), control2: point(77, 45, size: size))
        path.addCurve(to: point(78, 71, size: size), control1: point(78, 58, size: size), control2: point(79, 65, size: size))
        path.addCurve(to: point(70, 75, size: size), control1: point(76, 76, size: size), control2: point(72, 77, size: size))
        path.addCurve(to: point(63, 54, size: size), control1: point(66, 68, size: size), control2: point(64, 61, size: size))
        path.addCurve(to: point(62, 43, size: size), control1: point(63, 49, size: size), control2: point(62, 46, size: size))
        path.addCurve(to: point(69, 38, size: size), control1: point(64, 40, size: size), control2: point(66, 38, size: size))
        path.closeSubpath()
        return path
    }

    private func leftForearmPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(23, 72, size: size))
        path.addCurve(to: point(18, 92, size: size), control1: point(20, 78, size: size), control2: point(18, 85, size: size))
        path.addCurve(to: point(17, 107, size: size), control1: point(17, 98, size: size), control2: point(16, 103, size: size))
        path.addCurve(to: point(24, 110, size: size), control1: point(19, 111, size: size), control2: point(22, 112, size: size))
        path.addCurve(to: point(30, 76, size: size), control1: point(28, 101, size: size), control2: point(31, 88, size: size))
        path.closeSubpath()
        return path
    }

    private func rightForearmPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(77, 72, size: size))
        path.addCurve(to: point(82, 92, size: size), control1: point(80, 78, size: size), control2: point(82, 85, size: size))
        path.addCurve(to: point(83, 107, size: size), control1: point(83, 98, size: size), control2: point(84, 103, size: size))
        path.addCurve(to: point(76, 110, size: size), control1: point(81, 111, size: size), control2: point(78, 112, size: size))
        path.addCurve(to: point(70, 76, size: size), control1: point(72, 101, size: size), control2: point(69, 88, size: size))
        path.closeSubpath()
        return path
    }

    private func leftHandPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(17, 106, size: size))
        path.addCurve(to: point(13, 113, size: size), control1: point(14, 108, size: size), control2: point(13, 111, size: size))
        path.addCurve(to: point(18, 119, size: size), control1: point(13, 117, size: size), control2: point(15, 119, size: size))
        path.addCurve(to: point(24, 113, size: size), control1: point(21, 119, size: size), control2: point(24, 117, size: size))
        path.addCurve(to: point(22, 106, size: size), control1: point(24, 110, size: size), control2: point(23, 107, size: size))
        path.closeSubpath()
        return path
    }

    private func rightHandPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(83, 106, size: size))
        path.addCurve(to: point(87, 113, size: size), control1: point(86, 108, size: size), control2: point(87, 111, size: size))
        path.addCurve(to: point(82, 119, size: size), control1: point(87, 117, size: size), control2: point(85, 119, size: size))
        path.addCurve(to: point(76, 113, size: size), control1: point(79, 119, size: size), control2: point(76, 117, size: size))
        path.addCurve(to: point(78, 106, size: size), control1: point(76, 110, size: size), control2: point(77, 107, size: size))
        path.closeSubpath()
        return path
    }

    private func leftThighPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(37, 101, size: size))
        path.addCurve(to: point(33, 124, size: size), control1: point(34, 108, size: size), control2: point(32, 116, size: size))
        path.addCurve(to: point(36, 134, size: size), control1: point(33, 128, size: size), control2: point(34, 132, size: size))
        path.addCurve(to: point(45, 134, size: size), control1: point(39, 136, size: size), control2: point(43, 136, size: size))
        path.addCurve(to: point(49, 104, size: size), control1: point(47, 124, size: size), control2: point(49, 113, size: size))
        path.addCurve(to: point(45, 100, size: size), control1: point(48, 101, size: size), control2: point(47, 100, size: size))
        path.closeSubpath()
        return path
    }

    private func rightThighPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(63, 101, size: size))
        path.addCurve(to: point(67, 124, size: size), control1: point(66, 108, size: size), control2: point(68, 116, size: size))
        path.addCurve(to: point(64, 134, size: size), control1: point(67, 128, size: size), control2: point(66, 132, size: size))
        path.addCurve(to: point(55, 134, size: size), control1: point(61, 136, size: size), control2: point(57, 136, size: size))
        path.addCurve(to: point(51, 104, size: size), control1: point(53, 124, size: size), control2: point(51, 113, size: size))
        path.addCurve(to: point(55, 100, size: size), control1: point(52, 101, size: size), control2: point(53, 100, size: size))
        path.closeSubpath()
        return path
    }

    private func leftCalfPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(36, 131, size: size))
        path.addCurve(to: point(34, 146, size: size), control1: point(33, 136, size: size), control2: point(33, 142, size: size))
        path.addCurve(to: point(36, 151, size: size), control1: point(34, 149, size: size), control2: point(35, 151, size: size))
        path.addLine(to: point(44, 151, size: size))
        path.addCurve(to: point(46, 146, size: size), control1: point(45, 151, size: size), control2: point(46, 149, size: size))
        path.addCurve(to: point(44, 131, size: size), control1: point(47, 142, size: size), control2: point(47, 136, size: size))
        path.addCurve(to: point(36, 131, size: size), control1: point(42, 129, size: size), control2: point(38, 129, size: size))
        path.closeSubpath()
        return path
    }

    private func rightCalfPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(56, 131, size: size))
        path.addCurve(to: point(54, 146, size: size), control1: point(53, 136, size: size), control2: point(53, 142, size: size))
        path.addCurve(to: point(56, 151, size: size), control1: point(54, 149, size: size), control2: point(55, 151, size: size))
        path.addLine(to: point(64, 151, size: size))
        path.addCurve(to: point(66, 146, size: size), control1: point(65, 151, size: size), control2: point(66, 149, size: size))
        path.addCurve(to: point(64, 131, size: size), control1: point(67, 142, size: size), control2: point(67, 136, size: size))
        path.addCurve(to: point(56, 131, size: size), control1: point(62, 129, size: size), control2: point(58, 129, size: size))
        path.closeSubpath()
        return path
    }

    private func leftFootPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(35, 149, size: size))
        path.addCurve(to: point(44, 149, size: size), control1: point(38, 151, size: size), control2: point(41, 151, size: size))
        path.addCurve(to: point(48, 154, size: size), control1: point(47, 150, size: size), control2: point(49, 152, size: size))
        path.addLine(to: point(34, 154, size: size))
        path.addCurve(to: point(35, 149, size: size), control1: point(33, 152, size: size), control2: point(34, 150, size: size))
        path.closeSubpath()
        return path
    }

    private func rightFootPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(56, 149, size: size))
        path.addCurve(to: point(65, 149, size: size), control1: point(59, 151, size: size), control2: point(62, 151, size: size))
        path.addCurve(to: point(66, 154, size: size), control1: point(66, 150, size: size), control2: point(67, 152, size: size))
        path.addLine(to: point(52, 154, size: size))
        path.addCurve(to: point(56, 149, size: size), control1: point(51, 152, size: size), control2: point(53, 150, size: size))
        path.closeSubpath()
        return path
    }

    private func leftUpperPecPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(36, 41, size: size))
        path.addCurve(to: point(49, 42, size: size), control1: point(40, 39, size: size), control2: point(45, 40, size: size))
        path.addLine(to: point(48, 49, size: size))
        path.addCurve(to: point(35, 49, size: size), control1: point(43, 50, size: size), control2: point(38, 49, size: size))
        path.closeSubpath()
        return path
    }

    private func rightUpperPecPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(64, 41, size: size))
        path.addCurve(to: point(51, 42, size: size), control1: point(60, 39, size: size), control2: point(55, 40, size: size))
        path.addLine(to: point(52, 49, size: size))
        path.addCurve(to: point(65, 49, size: size), control1: point(57, 50, size: size), control2: point(62, 49, size: size))
        path.closeSubpath()
        return path
    }

    private func leftMidPecPath(size: CGSize) -> Path {
        polygon([(35, 49), (48, 49), (48, 57), (36, 58), (34, 53)], size: size)
    }

    private func rightMidPecPath(size: CGSize) -> Path {
        polygon([(65, 49), (52, 49), (52, 57), (64, 58), (66, 53)], size: size)
    }

    private func leftLowerPecPath(size: CGSize) -> Path {
        polygon([(36, 57), (48, 57), (47, 63), (39, 64), (35, 61)], size: size)
    }

    private func rightLowerPecPath(size: CGSize) -> Path {
        polygon([(64, 57), (52, 57), (53, 63), (61, 64), (65, 61)], size: size)
    }

    private func leftPecPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(34, 41, size: size))
        path.addCurve(to: point(49, 43, size: size), control1: point(38, 38, size: size), control2: point(45, 39, size: size))
        path.addLine(to: point(48, 58, size: size))
        path.addCurve(to: point(35, 58, size: size), control1: point(42, 59, size: size), control2: point(37, 56, size: size))
        path.closeSubpath()
        return path
    }

    private func rightPecPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(66, 41, size: size))
        path.addCurve(to: point(51, 43, size: size), control1: point(62, 38, size: size), control2: point(55, 39, size: size))
        path.addLine(to: point(52, 58, size: size))
        path.addCurve(to: point(65, 58, size: size), control1: point(58, 59, size: size), control2: point(63, 56, size: size))
        path.closeSubpath()
        return path
    }

    private func rectusAbdominisPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(44, 60, size: size))
        path.addCurve(to: point(56, 60, size: size), control1: point(48, 59, size: size), control2: point(52, 59, size: size))
        path.addCurve(to: point(57, 84, size: size), control1: point(57, 68, size: size), control2: point(58, 78, size: size))
        path.addCurve(to: point(50, 88, size: size), control1: point(55, 87, size: size), control2: point(53, 88, size: size))
        path.addCurve(to: point(43, 84, size: size), control1: point(47, 88, size: size), control2: point(45, 87, size: size))
        path.addCurve(to: point(44, 60, size: size), control1: point(42, 78, size: size), control2: point(43, 68, size: size))
        path.closeSubpath()
        return path
    }

    private func leftObliquePath(size: CGSize) -> Path {
        polygon([(37, 59), (44, 62), (43, 84), (39, 88), (34, 75), (33, 66)], size: size)
    }

    private func rightObliquePath(size: CGSize) -> Path {
        polygon([(63, 59), (56, 62), (57, 84), (61, 88), (66, 75), (67, 66)], size: size)
    }

    private func corePath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(42, 58, size: size))
        path.addLine(to: point(58, 58, size: size))
        path.addCurve(to: point(60, 85, size: size), control1: point(60, 67, size: size), control2: point(60, 77, size: size))
        path.addCurve(to: point(40, 85, size: size), control1: point(54, 89, size: size), control2: point(46, 89, size: size))
        path.addCurve(to: point(42, 58, size: size), control1: point(40, 77, size: size), control2: point(40, 67, size: size))
        path.closeSubpath()
        return path
    }

    private func leftFrontDeltPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(31, 37, size: size))
        path.addCurve(to: point(39, 43, size: size), control1: point(35, 37, size: size), control2: point(38, 39, size: size))
        path.addCurve(to: point(34, 53, size: size), control1: point(38, 48, size: size), control2: point(36, 51, size: size))
        path.addCurve(to: point(25, 50, size: size), control1: point(29, 54, size: size), control2: point(26, 53, size: size))
        path.addCurve(to: point(31, 37, size: size), control1: point(24, 45, size: size), control2: point(27, 40, size: size))
        path.closeSubpath()
        return path
    }

    private func rightFrontDeltPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(69, 37, size: size))
        path.addCurve(to: point(61, 43, size: size), control1: point(65, 37, size: size), control2: point(62, 39, size: size))
        path.addCurve(to: point(66, 53, size: size), control1: point(62, 48, size: size), control2: point(64, 51, size: size))
        path.addCurve(to: point(75, 50, size: size), control1: point(71, 54, size: size), control2: point(74, 53, size: size))
        path.addCurve(to: point(69, 37, size: size), control1: point(76, 45, size: size), control2: point(73, 40, size: size))
        path.closeSubpath()
        return path
    }

    private func leftSideDeltPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(30, 36, size: size))
        path.addCurve(to: point(22, 48, size: size), control1: point(25, 38, size: size), control2: point(22, 42, size: size))
        path.addCurve(to: point(27, 58, size: size), control1: point(21, 54, size: size), control2: point(24, 58, size: size))
        path.addCurve(to: point(35, 43, size: size), control1: point(33, 56, size: size), control2: point(35, 49, size: size))
        path.addCurve(to: point(30, 36, size: size), control1: point(34, 39, size: size), control2: point(32, 37, size: size))
        path.closeSubpath()
        return path
    }

    private func rightSideDeltPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(70, 36, size: size))
        path.addCurve(to: point(78, 48, size: size), control1: point(75, 38, size: size), control2: point(78, 42, size: size))
        path.addCurve(to: point(73, 58, size: size), control1: point(79, 54, size: size), control2: point(76, 58, size: size))
        path.addCurve(to: point(65, 43, size: size), control1: point(67, 56, size: size), control2: point(65, 49, size: size))
        path.addCurve(to: point(70, 36, size: size), control1: point(66, 39, size: size), control2: point(68, 37, size: size))
        path.closeSubpath()
        return path
    }

    private func leftRearDeltPath(size: CGSize) -> Path {
        polygon([(30, 38), (38, 41), (35, 50), (28, 52), (24, 48)], size: size)
    }

    private func rightRearDeltPath(size: CGSize) -> Path {
        polygon([(70, 38), (62, 41), (65, 50), (72, 52), (76, 48)], size: size)
    }

    private func leftDeltPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(30, 36, size: size))
        path.addCurve(to: point(20, 51, size: size), control1: point(24, 38, size: size), control2: point(20, 43, size: size))
        path.addCurve(to: point(29, 57, size: size), control1: point(21, 56, size: size), control2: point(26, 58, size: size))
        path.addCurve(to: point(38, 43, size: size), control1: point(34, 54, size: size), control2: point(37, 49, size: size))
        path.addCurve(to: point(30, 36, size: size), control1: point(36, 38, size: size), control2: point(33, 36, size: size))
        path.closeSubpath()
        return path
    }

    private func rightDeltPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(70, 36, size: size))
        path.addCurve(to: point(80, 51, size: size), control1: point(76, 38, size: size), control2: point(80, 43, size: size))
        path.addCurve(to: point(71, 57, size: size), control1: point(79, 56, size: size), control2: point(74, 58, size: size))
        path.addCurve(to: point(62, 43, size: size), control1: point(66, 54, size: size), control2: point(63, 49, size: size))
        path.addCurve(to: point(70, 36, size: size), control1: point(64, 38, size: size), control2: point(67, 36, size: size))
        path.closeSubpath()
        return path
    }

    private func leftBicepsPath(size: CGSize) -> Path {
        polygon([(24, 50), (31, 47), (31, 66), (24, 70), (22, 59)], size: size)
    }

    private func rightBicepsPath(size: CGSize) -> Path {
        polygon([(76, 50), (69, 47), (69, 66), (76, 70), (78, 59)], size: size)
    }

    private func leftTricepsPath(size: CGSize) -> Path {
        polygon([(29, 58), (32, 63), (29, 75), (23, 73), (22, 64)], size: size)
    }

    private func rightTricepsPath(size: CGSize) -> Path {
        polygon([(71, 58), (68, 63), (71, 75), (77, 73), (78, 64)], size: size)
    }

    private func leftUpperArmHighlightPath(size: CGSize) -> Path {
        polygon([(22, 50), (30, 47), (31, 71), (22, 72)], size: size)
    }

    private func rightUpperArmHighlightPath(size: CGSize) -> Path {
        polygon([(78, 50), (70, 47), (69, 71), (78, 72)], size: size)
    }

    private func leftForearmHighlightPath(size: CGSize) -> Path {
        polygon([(20, 76), (28, 78), (24, 104), (16, 104)], size: size)
    }

    private func rightForearmHighlightPath(size: CGSize) -> Path {
        polygon([(80, 76), (72, 78), (76, 104), (84, 104)], size: size)
    }

    private func leftQuadPath(size: CGSize) -> Path {
        polygon([(37, 103), (48, 104), (45, 132), (36, 131), (34, 119)], size: size)
    }

    private func rightQuadPath(size: CGSize) -> Path {
        polygon([(63, 103), (52, 104), (55, 132), (64, 131), (66, 119)], size: size)
    }

    private func leftCalfHighlightPath(size: CGSize) -> Path {
        polygon([(36, 133), (44, 133), (45, 147), (42, 150), (35, 147)], size: size)
    }

    private func rightCalfHighlightPath(size: CGSize) -> Path {
        polygon([(56, 133), (64, 133), (65, 147), (58, 150), (55, 147)], size: size)
    }

    private func leftLatPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(34, 43, size: size))
        path.addCurve(to: point(47, 43, size: size), control1: point(38, 41, size: size), control2: point(43, 42, size: size))
        path.addCurve(to: point(45, 76, size: size), control1: point(47, 55, size: size), control2: point(46, 66, size: size))
        path.addCurve(to: point(37, 85, size: size), control1: point(43, 80, size: size), control2: point(41, 83, size: size))
        path.addCurve(to: point(31, 59, size: size), control1: point(34, 76, size: size), control2: point(31, 68, size: size))
        path.addCurve(to: point(34, 43, size: size), control1: point(30, 52, size: size), control2: point(31, 47, size: size))
        path.closeSubpath()
        return path
    }

    private func rightLatPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(66, 43, size: size))
        path.addCurve(to: point(53, 43, size: size), control1: point(62, 41, size: size), control2: point(57, 42, size: size))
        path.addCurve(to: point(55, 76, size: size), control1: point(53, 55, size: size), control2: point(54, 66, size: size))
        path.addCurve(to: point(63, 85, size: size), control1: point(57, 80, size: size), control2: point(59, 83, size: size))
        path.addCurve(to: point(69, 59, size: size), control1: point(66, 76, size: size), control2: point(69, 68, size: size))
        path.addCurve(to: point(66, 43, size: size), control1: point(70, 52, size: size), control2: point(69, 47, size: size))
        path.closeSubpath()
        return path
    }

    private func leftUpperBackPath(size: CGSize) -> Path {
        polygon([(35, 37), (49, 37), (48, 49), (38, 52), (30, 46)], size: size)
    }

    private func rightUpperBackPath(size: CGSize) -> Path {
        polygon([(65, 37), (51, 37), (52, 49), (62, 52), (70, 46)], size: size)
    }

    private func upperSpinePath(size: CGSize) -> Path {
        roundedRect(45, 31, 10, 13, radius: 4, size: size)
    }

    private func leftLowerBackPath(size: CGSize) -> Path {
        polygon([(41, 67), (49, 70), (47, 88), (40, 90), (36, 79)], size: size)
    }

    private func rightLowerBackPath(size: CGSize) -> Path {
        polygon([(59, 67), (51, 70), (53, 88), (60, 90), (64, 79)], size: size)
    }

    private func leftHamstringPath(size: CGSize) -> Path {
        polygon([(36, 105), (42, 102), (42, 132), (35, 131), (33, 118)], size: size)
    }

    private func rightHamstringPath(size: CGSize) -> Path {
        polygon([(64, 105), (58, 102), (58, 132), (65, 131), (67, 118)], size: size)
    }

    private func leftAdductorPath(size: CGSize) -> Path {
        polygon([(45, 103), (50, 103), (47, 131), (43, 131), (42, 114)], size: size)
    }

    private func rightAdductorPath(size: CGSize) -> Path {
        polygon([(55, 103), (50, 103), (53, 131), (57, 131), (58, 114)], size: size)
    }

    private func leftGluteMaxPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(37, 89, size: size))
        path.addCurve(to: point(49, 91, size: size), control1: point(40, 88, size: size), control2: point(45, 89, size: size))
        path.addCurve(to: point(48, 104, size: size), control1: point(49, 96, size: size), control2: point(49, 101, size: size))
        path.addCurve(to: point(38, 104, size: size), control1: point(44, 106, size: size), control2: point(40, 106, size: size))
        path.addCurve(to: point(34, 97, size: size), control1: point(35, 102, size: size), control2: point(34, 100, size: size))
        path.addCurve(to: point(37, 89, size: size), control1: point(34, 94, size: size), control2: point(35, 91, size: size))
        path.closeSubpath()
        return path
    }

    private func rightGluteMaxPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(63, 89, size: size))
        path.addCurve(to: point(51, 91, size: size), control1: point(60, 88, size: size), control2: point(55, 89, size: size))
        path.addCurve(to: point(52, 104, size: size), control1: point(51, 96, size: size), control2: point(51, 101, size: size))
        path.addCurve(to: point(62, 104, size: size), control1: point(56, 106, size: size), control2: point(60, 106, size: size))
        path.addCurve(to: point(66, 97, size: size), control1: point(65, 102, size: size), control2: point(66, 100, size: size))
        path.addCurve(to: point(63, 89, size: size), control1: point(66, 94, size: size), control2: point(65, 91, size: size))
        path.closeSubpath()
        return path
    }

    private func leftGluteMedPath(size: CGSize) -> Path {
        polygon([(34, 86), (42, 89), (38, 99), (32, 99), (31, 93)], size: size)
    }

    private func rightGluteMedPath(size: CGSize) -> Path {
        polygon([(66, 86), (58, 89), (62, 99), (68, 99), (69, 93)], size: size)
    }

    private func leftForearmFlexorPath(size: CGSize) -> Path {
        polygon([(22, 76), (28, 78), (24, 106), (17, 106), (18, 93)], size: size)
    }

    private func rightForearmFlexorPath(size: CGSize) -> Path {
        polygon([(78, 76), (72, 78), (76, 106), (83, 106), (82, 93)], size: size)
    }

    private func leftForearmExtensorPath(size: CGSize) -> Path {
        polygon([(18, 78), (23, 76), (21, 106), (16, 106), (15, 94)], size: size)
    }

    private func rightForearmExtensorPath(size: CGSize) -> Path {
        polygon([(82, 78), (77, 76), (79, 106), (84, 106), (85, 94)], size: size)
    }

    private func leftBrachioradialisPath(size: CGSize) -> Path {
        polygon([(25, 75), (30, 79), (26, 102), (21, 105), (21, 91)], size: size)
    }

    private func rightBrachioradialisPath(size: CGSize) -> Path {
        polygon([(75, 75), (70, 79), (74, 102), (79, 105), (79, 91)], size: size)
    }

    private func leftSoleusPath(size: CGSize) -> Path {
        polygon([(37, 141), (44, 141), (45, 150), (36, 150), (34, 147)], size: size)
    }

    private func rightSoleusPath(size: CGSize) -> Path {
        polygon([(56, 141), (63, 141), (66, 147), (64, 150), (55, 150)], size: size)
    }

    private func ellipse(
        _ x: CGFloat,
        _ y: CGFloat,
        _ width: CGFloat,
        _ height: CGFloat,
        size: CGSize
    ) -> Path {
        Path(ellipseIn: rect(x, y, width, height, size: size))
    }

    private func roundedRect(
        _ x: CGFloat,
        _ y: CGFloat,
        _ width: CGFloat,
        _ height: CGFloat,
        radius: CGFloat,
        size: CGSize
    ) -> Path {
        Path(roundedRect: rect(x, y, width, height, size: size), cornerRadius: scaled(radius, size: size))
    }

    private func polygon(_ points: [(CGFloat, CGFloat)], size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        path.move(to: point(first.0, first.1, size: size))

        for point in points.dropFirst() {
            path.addLine(to: self.point(point.0, point.1, size: size))
        }

        path.closeSubpath()
        return path
    }

    private func curvedLine(_ points: [(CGFloat, CGFloat)], size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        path.move(to: point(first.0, first.1, size: size))

        if points.count == 2 {
            let second = points[1]
            path.addLine(to: point(second.0, second.1, size: size))
            return path
        }

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = (
                (previous.0 + current.0) / 2,
                (previous.1 + current.1) / 2
            )

            path.addQuadCurve(
                to: point(midpoint.0, midpoint.1, size: size),
                control: point(previous.0, previous.1, size: size)
            )
        }

        if let last = points.last {
            path.addLine(to: point(last.0, last.1, size: size))
        }

        return path
    }

    private func rect(
        _ x: CGFloat,
        _ y: CGFloat,
        _ width: CGFloat,
        _ height: CGFloat,
        size: CGSize
    ) -> CGRect {
        CGRect(
            x: x / 100 * size.width,
            y: y / 154 * size.height,
            width: width / 100 * size.width,
            height: height / 154 * size.height
        )
    }

    private func point(_ x: CGFloat, _ y: CGFloat, size: CGSize) -> CGPoint {
        CGPoint(x: x / 100 * size.width, y: y / 154 * size.height)
    }

    private func scaled(_ value: CGFloat, size: CGSize) -> CGFloat {
        value / 100 * min(size.width, size.height)
    }
}

struct MuscleChipRow: View {
    var groups: [MuscleGroup]

    var body: some View {
        HStack(spacing: 6) {
            if let primary = groups.first {
                Text(primary.rawValue)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.black.opacity(0.88))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.coachAccent)
                    .clipShape(Capsule())
            }

            if groups.count > 1 {
                Menu {
                    ForEach(groups.dropFirst()) { group in
                        Text(group.rawValue)
                    }
                } label: {
                    compactMoreChip(count: groups.count - 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(groups.count - 1) more muscle groups")
            }
        }
    }

    private func compactMoreChip(count: Int) -> some View {
        Text("+\(count)")
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(Color.coachAccent)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.coachAccent.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct ExerciseMuscleChipRow: View {
    var groups: [MuscleGroup]
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?
    var supporting: [DetailedMuscleGroup] = []

    private var visibleLabel: String {
        targetLabels.first ?? primary.rawValue
    }

    private var hiddenLabels: [String] {
        Array(targetLabels.dropFirst())
    }

    private var targetLabels: [String] {
        var labels: [String] = []

        func append(_ label: String) {
            guard !labels.contains(label) else { return }
            labels.append(label)
        }

        append(primary.rawValue)

        if let secondary {
            append(secondary.rawValue)
        }

        supporting.forEach { append($0.rawValue) }
        groups.forEach { append($0.rawValue) }

        return labels
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(visibleLabel)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(Color.black.opacity(0.90))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.coachAccent)
                .clipShape(Capsule())

            if !hiddenLabels.isEmpty {
                Menu {
                    ForEach(hiddenLabels, id: \.self) { label in
                        Text(label)
                    }
                } label: {
                    compactMoreChip(count: hiddenLabels.count)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(hiddenLabels.count) more muscle targets")
            }
        }
        .lineLimit(1)
    }

    private func compactMoreChip(count: Int) -> some View {
        Text("+\(count)")
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(Color.coachAccent)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.coachAccent.opacity(0.12))
            .overlay {
                Capsule()
                    .stroke(Color.coachAccent.opacity(0.24), lineWidth: 1)
            }
            .clipShape(Capsule())
    }
}

struct DetailedMuscleTagRow: View {
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?

    var body: some View {
        HStack(spacing: 6) {
            detailedChip(label: "Primary", muscle: primary, isPrimary: true)

            if let secondary {
                Menu {
                    Text(secondary.rawValue)
                } label: {
                    compactMoreChip(count: 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show additional muscle")
            }
        }
    }

    private func compactMoreChip(count: Int) -> some View {
        Text("+\(count)")
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(Color.coachAccent)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.coachAccent.opacity(0.12))
            .overlay {
                Capsule()
                    .stroke(Color.coachAccent.opacity(0.24), lineWidth: 1)
            }
            .clipShape(Capsule())
    }

    private func detailedChip(
        label: String,
        muscle: DetailedMuscleGroup,
        isPrimary: Bool
    ) -> some View {
        Text(muscle.rawValue)
        .font(.caption2.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .foregroundStyle(isPrimary ? Color.black.opacity(0.90) : Color.coachAccent)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(isPrimary ? AnyShapeStyle(Color.coachAccent) : AnyShapeStyle(Color.coachAccent.opacity(0.12)))
        .overlay {
            Capsule()
                .stroke(isPrimary ? Color.clear : Color.coachAccent.opacity(0.24), lineWidth: 1)
        }
        .clipShape(Capsule())
        .accessibilityLabel("\(label): \(muscle.rawValue)")
    }
}
