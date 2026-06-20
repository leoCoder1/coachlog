import AudioToolbox
import SwiftUI
import UIKit

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

enum CoachMotion {
    static let screen = Animation.smooth(duration: 0.32)
    static let content = Animation.snappy(duration: 0.28)

    static var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
    }

    static var cardTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        )
    }
}

enum CoachGradient {
    static let accent = LinearGradient(
        colors: [
            Color.freshness(.ready),
            Color.coachAccent,
            Color(red: 0.180, green: 0.520, blue: 0.980)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentSoft = LinearGradient(
        colors: [
            Color.coachAccent.opacity(0.28),
            Color.freshness(.ready).opacity(0.12),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let chartFill = LinearGradient(
        colors: [
            Color.freshness(.ready),
            Color.coachAccent,
            Color(red: 0.220, green: 0.720, blue: 0.980)
        ],
        startPoint: .bottom,
        endPoint: .top
    )

    static let chartArea = LinearGradient(
        colors: [
            Color.coachAccent.opacity(0.30),
            Color.freshness(.ready).opacity(0.12),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let surfaceSheen = LinearGradient(
        colors: [
            Color.white.opacity(0.045),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warm = LinearGradient(
        colors: [
            Color.coachWarm,
            Color(red: 1.000, green: 0.430, blue: 0.260)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func feedback(isPositive: Bool) -> LinearGradient {
        LinearGradient(
            colors: isPositive
                ? [Color.freshness(.ready).opacity(0.24), Color.coachAccent.opacity(0.12)]
                : [Color.coachWarm.opacity(0.24), Color(red: 1.000, green: 0.330, blue: 0.310).opacity(0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
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
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.coachSurface)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(CoachGradient.surfaceSheen)
            }
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
                Group {
                    if isEnabled {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(CoachGradient.accent)
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.coachSurfaceMuted)
                    }
                }
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

struct CoachCountdownTimerButton: View {
    var title: String = "Timer"
    @Binding var durationSeconds: Int
    var tint: Color = .coachAccent
    var width: CGFloat? = 132

    @State private var remainingSeconds: Int
    @State private var isRunning = false
    @State private var didComplete = false
    @State private var isFlashing = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        title: String = "Timer",
        durationSeconds: Binding<Int>,
        tint: Color = .coachAccent,
        width: CGFloat? = 132
    ) {
        self.title = title
        _durationSeconds = durationSeconds
        self.tint = tint
        self.width = width
        _remainingSeconds = State(initialValue: durationSeconds.wrappedValue)
    }

    private var actionTitle: String {
        if didComplete {
            return "Done"
        }

        return isRunning ? "Stop" : "Start"
    }

    private var actionIcon: String {
        if didComplete {
            return "checkmark.circle.fill"
        }

        return isRunning ? "pause.fill" : "play.fill"
    }

    private var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }

        return "\(seconds)s"
    }

    var body: some View {
        Button {
            toggleTimer()
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(didComplete ? "Time done" : title)
                        .font(.caption)
                        .foregroundStyle(didComplete ? tint : Color.coachSecondaryText)

                    Text(formattedRemaining)
                        .font(.headline.monospacedDigit().weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 2)

                VStack(spacing: 4) {
                    Image(systemName: actionIcon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.black.opacity(0.86))
                        .frame(width: 26, height: 26)
                        .background(didComplete ? AnyShapeStyle(tint) : AnyShapeStyle(CoachGradient.accent))
                        .clipShape(Circle())

                    Text(actionTitle)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .frame(width: width)
            .frame(minHeight: 64)
            .background(timerBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(timerBorderColor, lineWidth: didComplete ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) \(formattedRemaining), \(didComplete ? "time done" : actionTitle)")
        .onReceive(timer) { _ in
            tick()
        }
        .onChange(of: durationSeconds) { _, newDuration in
            updateDuration(newDuration)
        }
        .onDisappear {
            isRunning = false
        }
    }

    private var timerBackground: some ShapeStyle {
        if didComplete || isFlashing {
            return AnyShapeStyle(tint.opacity(isFlashing ? 0.34 : 0.22))
        }

        return AnyShapeStyle(Color.coachSurfaceElevated)
    }

    private var timerBorderColor: Color {
        if didComplete || isFlashing {
            return tint.opacity(0.70)
        }

        return isRunning ? tint.opacity(0.45) : Color.coachBorder
    }

    private func toggleTimer() {
        if isRunning {
            isRunning = false
            return
        }

        if remainingSeconds == 0 {
            remainingSeconds = durationSeconds
        }

        didComplete = false
        isFlashing = false
        isRunning = true
    }

    private func tick() {
        guard isRunning else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }

        if remainingSeconds == 0 {
            completeTimer()
        }
    }

    private func updateDuration(_ newDuration: Int) {
        let clampedDuration = max(1, newDuration)

        if isRunning {
            remainingSeconds = min(remainingSeconds, clampedDuration)
        } else {
            remainingSeconds = clampedDuration
        }

        didComplete = false
        isFlashing = false
    }

    private func completeTimer() {
        isRunning = false
        didComplete = true

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1005)

        withAnimation(.easeInOut(duration: 0.16).repeatCount(6, autoreverses: true)) {
            isFlashing = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            await MainActor.run {
                isFlashing = false
            }
        }
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
                        .fill(CoachGradient.accentSoft)
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
