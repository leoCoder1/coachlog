import SwiftUI
import UIKit

struct ExerciseVisualHeader: View {
    var exercise: PlannedExercise
    var subtitle: String
    var note: String?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ExerciseIllustrationThumbnail(exercise: exercise, size: 74)

            VStack(alignment: .leading, spacing: 7) {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.coachSecondaryText)
                    .lineLimit(2)

                MuscleChipRow(groups: exercise.affectedMuscleGroups)
                DetailedMuscleTagRow(
                    primary: exercise.primaryDetailedMuscle,
                    secondary: exercise.secondaryDetailedMuscle
                )

                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 4)

            MuscleImpactPairMap(
                primary: exercise.primaryDetailedMuscle,
                secondary: exercise.secondaryDetailedMuscle,
                supporting: exercise.detailedMuscles
            )
            .frame(width: 78, height: 76)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), primary muscle: \(exercise.primaryDetailedMuscle.rawValue), secondary muscle: \(exercise.secondaryDetailedMuscle?.rawValue ?? "none")")
    }
}

struct ExerciseIllustrationThumbnail: View {
    var exercise: PlannedExercise
    var size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.coachSurfaceElevated)

            if let image = UIImage(named: exercise.illustrationAssetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                fallbackPreview
            }
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.coachBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

            Image(systemName: exercise.muscleGroup.iconName)
                .font(.system(size: size * 0.26, weight: .semibold))
                .foregroundStyle(Color.coachAccent)
                .offset(x: size * 0.20, y: -size * 0.10)

            Capsule()
                .fill(Color.coachAccent.opacity(0.28))
                .frame(width: size * 0.46, height: 3)
                .offset(x: size * 0.16, y: size * 0.24)
        }
        .padding(8)
    }
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
                Text("+\(groups.count - 1)")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.coachAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.coachAccent.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }
}

struct DetailedMuscleTagRow: View {
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                detailedChip(label: "Primary", muscle: primary, isPrimary: true)
                    .fixedSize(horizontal: true, vertical: false)

                if let secondary {
                    detailedChip(label: "Secondary", muscle: secondary, isPrimary: false)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                detailedChip(label: "Primary", muscle: primary, isPrimary: true)

                if let secondary {
                    detailedChip(label: "Secondary", muscle: secondary, isPrimary: false)
                }
            }
        }
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
