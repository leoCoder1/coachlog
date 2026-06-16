import SwiftUI

extension Color {
    static let coachBackground = Color(red: 0.035, green: 0.038, blue: 0.040)
    static let coachSurface = Color(red: 0.095, green: 0.100, blue: 0.105)
    static let coachSurfaceElevated = Color(red: 0.135, green: 0.142, blue: 0.150)
    static let coachSurfaceMuted = Color(red: 0.170, green: 0.178, blue: 0.188)
    static let coachAccent = Color(red: 0.080, green: 0.690, blue: 0.720)
    static let coachAccentSoft = Color(red: 0.075, green: 0.420, blue: 0.450)
    static let coachSecondaryText = Color.white.opacity(0.64)
    static let coachTertiaryText = Color.white.opacity(0.42)
    static let coachBorder = Color.white.opacity(0.085)
    static let coachWarm = Color(red: 0.960, green: 0.640, blue: 0.220)

    static func freshness(_ status: FreshnessStatus) -> Color {
        switch status {
        case .ready: Color(red: 0.300, green: 0.840, blue: 0.520)
        case .recovering: .coachWarm
        case .due: .coachAccent
        case .caution: Color(red: 1.000, green: 0.330, blue: 0.310)
        }
    }
}

enum CoachLayout {
    static let bottomScrollPadding: CGFloat = 128
}

struct CoachScreenBackground: View {
    var body: some View {
        Color.coachBackground
            .ignoresSafeArea()
    }
}

struct CoachCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.coachSurface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.coachBorder, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 10)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CoachPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.black.opacity(isEnabled ? 0.92 : 0.45))
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isEnabled ? Color.coachAccent : Color.coachSurfaceMuted)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.18 : 0.05), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}

struct CoachSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? Color.coachAccent : Color.coachTertiaryText)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.coachSurfaceElevated)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isEnabled ? Color.coachAccent.opacity(0.24) : Color.coachBorder, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var iconName: String

    var body: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.coachAccent.opacity(0.16))
                        .frame(width: 34, height: 34)

                    Image(systemName: iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.coachAccent)
                }

                Text(value)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Color.coachSecondaryText)
                    .lineLimit(2)
            }
        }
    }
}

struct StatusBadge: View {
    var status: FreshnessStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.freshness(status))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.freshness(status).opacity(0.16))
            .overlay {
                Capsule()
                    .stroke(Color.freshness(status).opacity(0.22), lineWidth: 1)
            }
            .clipShape(Capsule())
    }
}

struct EmptyStateView: View {
    var iconName: String
    var title: String
    var message: String

    var body: some View {
        CoachCard {
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.largeTitle)
                    .foregroundStyle(Color.coachTertiaryText)

                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.coachSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}
