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

            MuscleImpactMap(
                primary: exercise.primaryDetailedMuscle,
                secondary: exercise.secondaryDetailedMuscle,
                supporting: exercise.detailedMuscles
            )
            .frame(width: 52, height: 76)
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
                supporting: exercise.detailedMuscles
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

struct MuscleImpactMap: View {
    var primary: DetailedMuscleGroup
    var secondary: DetailedMuscleGroup?
    var supporting: [DetailedMuscleGroup] = []

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

            for muscle in highlightedMuscles {
                let isSecondary = secondary.map { $0 == muscle } ?? false
                let opacity = muscle == primary ? 1.0 : (isSecondary ? 0.64 : 0.34)
                drawHighlight(for: muscle, in: &context, size: size, color: Color.coachAccent.opacity(opacity))
            }

            drawFigureOutline(in: &context, size: size)
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

    private func drawHighlight(
        for muscle: DetailedMuscleGroup,
        in context: inout GraphicsContext,
        size: CGSize,
        color: Color
    ) {
        for path in highlightPaths(for: muscle, size: size) {
            context.fill(path, with: .color(color))
        }
    }

    private func basePaths(size: CGSize) -> [Path] {
        [
            ellipse(39, 4, 22, 23, size: size),
            neckPath(size: size),
            torsoPath(size: size),
            leftUpperArmPath(size: size),
            rightUpperArmPath(size: size),
            leftForearmPath(size: size),
            rightForearmPath(size: size),
            leftHandPath(size: size),
            rightHandPath(size: size),
            leftThighPath(size: size),
            rightThighPath(size: size),
            leftCalfPath(size: size),
            rightCalfPath(size: size)
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
                polygon([(33, 43), (46, 43), (45, 78), (36, 85), (30, 59)], size: size),
                polygon([(67, 43), (54, 43), (55, 78), (64, 85), (70, 59)], size: size)
            ]
        case .upperBack:
            return [
                polygon([(34, 36), (48, 36), (47, 48), (35, 52), (29, 44)], size: size),
                polygon([(66, 36), (52, 36), (53, 48), (65, 52), (71, 44)], size: size),
                roundedRect(42, 32, 16, 9, radius: 4, size: size)
            ]
        case .lowerBack:
            return [
                polygon([(41, 67), (49, 70), (47, 88), (39, 93), (36, 80)], size: size),
                polygon([(59, 67), (51, 70), (53, 88), (61, 93), (64, 80)], size: size)
            ]
        case .quadriceps:
            return [
                leftQuadPath(size: size),
                rightQuadPath(size: size)
            ]
        case .hamstrings:
            return [
                polygon([(35, 105), (40, 101), (42, 129), (35, 130)], size: size),
                polygon([(65, 105), (60, 101), (58, 129), (65, 130)], size: size)
            ]
        case .adductors:
            return [
                polygon([(46, 101), (50, 102), (47, 128), (43, 128)], size: size),
                polygon([(54, 101), (50, 102), (53, 128), (57, 128)], size: size)
            ]
        case .gluteusMaximus:
            return [
                polygon([(37, 88), (49, 91), (48, 103), (39, 104), (34, 96)], size: size),
                polygon([(63, 88), (51, 91), (52, 103), (61, 104), (66, 96)], size: size)
            ]
        case .gluteusMedius:
            return [
                polygon([(32, 83), (40, 88), (37, 99), (30, 96)], size: size),
                polygon([(68, 83), (60, 88), (63, 99), (70, 96)], size: size)
            ]
        case .gluteusMinimus:
            return [
                ellipse(36, 91, 7, 8, size: size),
                ellipse(57, 91, 7, 8, size: size)
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
                polygon([(21, 77), (27, 79), (24, 104), (17, 104)], size: size),
                polygon([(79, 77), (73, 79), (76, 104), (83, 104)], size: size)
            ]
        case .forearmExtensors:
            return [
                polygon([(18, 78), (22, 77), (20, 105), (15, 105)], size: size),
                polygon([(82, 78), (78, 77), (80, 105), (85, 105)], size: size)
            ]
        case .brachioradialis:
            return [
                polygon([(24, 76), (30, 80), (26, 101), (21, 103)], size: size),
                polygon([(76, 76), (70, 80), (74, 101), (79, 103)], size: size)
            ]
        case .gastrocnemius:
            return [
                leftCalfHighlightPath(size: size),
                rightCalfHighlightPath(size: size)
            ]
        case .soleus:
            return [
                polygon([(37, 141), (44, 141), (45, 149), (35, 149)], size: size),
                polygon([(56, 141), (63, 141), (65, 149), (55, 149)], size: size)
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

    private func neckPath(size: CGSize) -> Path {
        polygon([(44, 25), (56, 25), (58, 35), (42, 35)], size: size)
    }

    private func torsoPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(50, 30, size: size))
        path.addCurve(to: point(30, 39, size: size), control1: point(41, 30, size: size), control2: point(34, 33, size: size))
        path.addCurve(to: point(32, 79, size: size), control1: point(23, 52, size: size), control2: point(28, 68, size: size))
        path.addCurve(to: point(38, 100, size: size), control1: point(35, 88, size: size), control2: point(37, 95, size: size))
        path.addCurve(to: point(62, 100, size: size), control1: point(44, 104, size: size), control2: point(56, 104, size: size))
        path.addCurve(to: point(68, 79, size: size), control1: point(63, 95, size: size), control2: point(65, 88, size: size))
        path.addCurve(to: point(70, 39, size: size), control1: point(72, 68, size: size), control2: point(77, 52, size: size))
        path.addCurve(to: point(50, 30, size: size), control1: point(66, 33, size: size), control2: point(59, 30, size: size))
        path.closeSubpath()
        return path
    }

    private func leftUpperArmPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(29, 39, size: size))
        path.addCurve(to: point(20, 72, size: size), control1: point(23, 45, size: size), control2: point(20, 56, size: size))
        path.addCurve(to: point(29, 78, size: size), control1: point(21, 78, size: size), control2: point(26, 80, size: size))
        path.addCurve(to: point(38, 45, size: size), control1: point(34, 68, size: size), control2: point(37, 55, size: size))
        path.addCurve(to: point(29, 39, size: size), control1: point(36, 41, size: size), control2: point(33, 39, size: size))
        path.closeSubpath()
        return path
    }

    private func rightUpperArmPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(71, 39, size: size))
        path.addCurve(to: point(80, 72, size: size), control1: point(77, 45, size: size), control2: point(80, 56, size: size))
        path.addCurve(to: point(71, 78, size: size), control1: point(79, 78, size: size), control2: point(74, 80, size: size))
        path.addCurve(to: point(62, 45, size: size), control1: point(66, 68, size: size), control2: point(63, 55, size: size))
        path.addCurve(to: point(71, 39, size: size), control1: point(64, 41, size: size), control2: point(67, 39, size: size))
        path.closeSubpath()
        return path
    }

    private func leftForearmPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(21, 73, size: size))
        path.addCurve(to: point(16, 107, size: size), control1: point(17, 83, size: size), control2: point(15, 95, size: size))
        path.addCurve(to: point(23, 111, size: size), control1: point(18, 112, size: size), control2: point(21, 113, size: size))
        path.addCurve(to: point(30, 79, size: size), control1: point(28, 101, size: size), control2: point(31, 90, size: size))
        path.closeSubpath()
        return path
    }

    private func rightForearmPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(79, 73, size: size))
        path.addCurve(to: point(84, 107, size: size), control1: point(83, 83, size: size), control2: point(85, 95, size: size))
        path.addCurve(to: point(77, 111, size: size), control1: point(82, 112, size: size), control2: point(79, 113, size: size))
        path.addCurve(to: point(70, 79, size: size), control1: point(72, 101, size: size), control2: point(69, 90, size: size))
        path.closeSubpath()
        return path
    }

    private func leftHandPath(size: CGSize) -> Path {
        ellipse(14, 106, 10, 13, size: size)
    }

    private func rightHandPath(size: CGSize) -> Path {
        ellipse(76, 106, 10, 13, size: size)
    }

    private func leftThighPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(39, 98, size: size))
        path.addCurve(to: point(34, 129, size: size), control1: point(35, 107, size: size), control2: point(33, 118, size: size))
        path.addCurve(to: point(45, 131, size: size), control1: point(36, 133, size: size), control2: point(42, 134, size: size))
        path.addCurve(to: point(49, 101, size: size), control1: point(47, 121, size: size), control2: point(49, 111, size: size))
        path.closeSubpath()
        return path
    }

    private func rightThighPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(61, 98, size: size))
        path.addCurve(to: point(66, 129, size: size), control1: point(65, 107, size: size), control2: point(67, 118, size: size))
        path.addCurve(to: point(55, 131, size: size), control1: point(64, 133, size: size), control2: point(58, 134, size: size))
        path.addCurve(to: point(51, 101, size: size), control1: point(53, 121, size: size), control2: point(51, 111, size: size))
        path.closeSubpath()
        return path
    }

    private func leftCalfPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(36, 128, size: size))
        path.addCurve(to: point(35, 149, size: size), control1: point(32, 136, size: size), control2: point(33, 145, size: size))
        path.addLine(to: point(45, 149, size: size))
        path.addCurve(to: point(44, 128, size: size), control1: point(47, 144, size: size), control2: point(48, 136, size: size))
        path.closeSubpath()
        return path
    }

    private func rightCalfPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(56, 128, size: size))
        path.addCurve(to: point(55, 149, size: size), control1: point(52, 136, size: size), control2: point(53, 144, size: size))
        path.addLine(to: point(65, 149, size: size))
        path.addCurve(to: point(64, 128, size: size), control1: point(67, 145, size: size), control2: point(68, 136, size: size))
        path.closeSubpath()
        return path
    }

    private func leftUpperPecPath(size: CGSize) -> Path {
        polygon([(34, 41), (49, 41), (49, 48), (35, 49)], size: size)
    }

    private func rightUpperPecPath(size: CGSize) -> Path {
        polygon([(66, 41), (51, 41), (51, 48), (65, 49)], size: size)
    }

    private func leftMidPecPath(size: CGSize) -> Path {
        polygon([(35, 48), (49, 48), (48, 56), (35, 56)], size: size)
    }

    private func rightMidPecPath(size: CGSize) -> Path {
        polygon([(65, 48), (51, 48), (52, 56), (65, 56)], size: size)
    }

    private func leftLowerPecPath(size: CGSize) -> Path {
        polygon([(36, 56), (48, 56), (47, 62), (38, 63)], size: size)
    }

    private func rightLowerPecPath(size: CGSize) -> Path {
        polygon([(64, 56), (52, 56), (53, 62), (62, 63)], size: size)
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
        path.move(to: point(44, 59, size: size))
        path.addLine(to: point(56, 59, size: size))
        path.addCurve(to: point(57, 86, size: size), control1: point(57, 68, size: size), control2: point(57, 78, size: size))
        path.addCurve(to: point(43, 86, size: size), control1: point(53, 88, size: size), control2: point(47, 88, size: size))
        path.addCurve(to: point(44, 59, size: size), control1: point(43, 78, size: size), control2: point(43, 68, size: size))
        path.closeSubpath()
        return path
    }

    private func leftObliquePath(size: CGSize) -> Path {
        polygon([(38, 59), (44, 62), (43, 84), (38, 88), (34, 73)], size: size)
    }

    private func rightObliquePath(size: CGSize) -> Path {
        polygon([(62, 59), (56, 62), (57, 84), (62, 88), (66, 73)], size: size)
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
        polygon([(31, 38), (38, 43), (35, 51), (27, 51), (24, 45)], size: size)
    }

    private func rightFrontDeltPath(size: CGSize) -> Path {
        polygon([(69, 38), (62, 43), (65, 51), (73, 51), (76, 45)], size: size)
    }

    private func leftSideDeltPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(29, 36, size: size))
        path.addCurve(to: point(20, 51, size: size), control1: point(23, 39, size: size), control2: point(20, 44, size: size))
        path.addCurve(to: point(27, 58, size: size), control1: point(20, 56, size: size), control2: point(24, 58, size: size))
        path.addLine(to: point(32, 50, size: size))
        path.addLine(to: point(35, 40, size: size))
        path.closeSubpath()
        return path
    }

    private func rightSideDeltPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: point(71, 36, size: size))
        path.addCurve(to: point(80, 51, size: size), control1: point(77, 39, size: size), control2: point(80, 44, size: size))
        path.addCurve(to: point(73, 58, size: size), control1: point(80, 56, size: size), control2: point(76, 58, size: size))
        path.addLine(to: point(68, 50, size: size))
        path.addLine(to: point(65, 40, size: size))
        path.closeSubpath()
        return path
    }

    private func leftRearDeltPath(size: CGSize) -> Path {
        polygon([(30, 39), (36, 41), (34, 49), (28, 51), (24, 47)], size: size)
    }

    private func rightRearDeltPath(size: CGSize) -> Path {
        polygon([(70, 39), (64, 41), (66, 49), (72, 51), (76, 47)], size: size)
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
        polygon([(22, 50), (30, 47), (31, 66), (23, 69)], size: size)
    }

    private func rightBicepsPath(size: CGSize) -> Path {
        polygon([(78, 50), (70, 47), (69, 66), (77, 69)], size: size)
    }

    private func leftTricepsPath(size: CGSize) -> Path {
        polygon([(27, 59), (32, 64), (29, 78), (22, 74), (22, 65)], size: size)
    }

    private func rightTricepsPath(size: CGSize) -> Path {
        polygon([(73, 59), (68, 64), (71, 78), (78, 74), (78, 65)], size: size)
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
        polygon([(38, 101), (48, 102), (45, 130), (35, 128)], size: size)
    }

    private func rightQuadPath(size: CGSize) -> Path {
        polygon([(62, 101), (52, 102), (55, 130), (65, 128)], size: size)
    }

    private func leftCalfHighlightPath(size: CGSize) -> Path {
        polygon([(36, 131), (44, 131), (45, 147), (35, 147)], size: size)
    }

    private func rightCalfHighlightPath(size: CGSize) -> Path {
        polygon([(56, 131), (64, 131), (65, 147), (55, 147)], size: size)
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
