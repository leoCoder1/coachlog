import SwiftUI
import WatchKit

struct WatchContentView: View {
    @EnvironmentObject private var store: WatchWorkoutSessionStore

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = store.snapshot {
                    activeWorkout(snapshot)
                } else {
                    waitingView
                }
            }
            .navigationTitle("AI Coach")
        }
    }

    private func activeWorkout(_ snapshot: ActiveWorkoutSnapshot) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.workoutTitle)
                        .font(.headline)
                        .lineLimit(2)

                    Text("\(snapshot.totalLoggedSetCount) sets logged")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            Section {
                ForEach(snapshot.exercises) { exercise in
                    NavigationLink(value: exercise.id) {
                        ExerciseRow(exercise: exercise)
                    }
                }
            }

            syncStatus
        }
        .navigationDestination(for: UUID.self) { exerciseID in
            WatchExerciseLoggingView(exerciseID: exerciseID)
        }
    }

    private var waitingView: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.green)

            Text("Open an active workout on iPhone")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(store.statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    @ViewBuilder
    private var syncStatus: some View {
        Section {
            HStack {
                Image(systemName: store.pendingSyncCount > 0 ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                Text(store.statusText)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(store.pendingSyncCount > 0 ? .orange : .secondary)
        }
    }
}

private struct ExerciseRow: View {
    let exercise: ActiveWorkoutExerciseSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 6) {
                Text("\(exercise.loggedSetCount)/\(exercise.targetSets) sets")
                Text("\(exercise.targetRepRange) reps")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}

private struct WatchExerciseLoggingView: View {
    @EnvironmentObject private var store: WatchWorkoutSessionStore

    let exerciseID: UUID

    @State private var weight = 0.0
    @State private var reps = 10
    @State private var isLogCoolingDown = false
    @State private var feedbackText: String?
    @State private var feedbackStyle = FeedbackStyle.neutral
    @State private var lastKnownLoggedSetCount = 0

    private var exercise: ActiveWorkoutExerciseSnapshot? {
        store.snapshot?.exercises.first { $0.id == exerciseID }
    }

    private var weightValues: [Double] {
        stride(from: 0.0, through: 400.0, by: 2.5).map { $0 }
    }

    private var repValues: [Int] {
        Array(1...40)
    }

    var body: some View {
        Group {
            if let exercise {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        exerciseSummary(exercise)

                        if let feedbackText {
                            FeedbackBanner(text: feedbackText, style: feedbackStyle)
                        }

                        if exercise.showsWeight {
                            CompactValueStepper(
                                value: weightLabel(weight),
                                decrement: { adjustWeight(by: -2.5) },
                                increment: { adjustWeight(by: 2.5) }
                            )
                        }

                        CompactValueStepper(
                            title: "Reps",
                            value: "\(reps)",
                            decrement: { adjustReps(by: -1) },
                            increment: { adjustReps(by: 1) }
                        )

                        HStack(spacing: 8) {
                            Button {
                                logSet(exercise)
                            } label: {
                                Label(logButtonTitle(for: exercise), systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isLogCoolingDown)

                            Button {
                                store.undoLastSet(exercise: exercise)
                                showFeedback("Last set removed", style: .neutral)
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.headline)
                                    .frame(width: 42, height: 44)
                            }
                            .buttonStyle(.bordered)
                            .disabled(exercise.loggedSetCount == 0)
                        }

                        if store.pendingSyncCount > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(store.statusText)
                            }
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .navigationTitle(exercise.name)
                .onAppear {
                    resetInputs(from: exercise)
                    lastKnownLoggedSetCount = exercise.loggedSetCount
                }
                .onChange(of: store.snapshot) { _, _ in
                    guard let updatedExercise = self.exercise else { return }
                    resetInputs(from: updatedExercise)
                    handleSnapshotUpdate(updatedExercise)
                }
            } else {
                Text("Exercise unavailable")
                    .font(.headline)
            }
        }
    }

    private func exerciseSummary(_ exercise: ActiveWorkoutExerciseSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text("\(exercise.loggedSetCount)/\(exercise.targetSets) sets")
                Text("•")
                Text("\(exercise.targetRepRange) reps")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            ProgressView(value: progress(for: exercise))
                .tint(.green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func logSet(_ exercise: ActiveWorkoutExerciseSnapshot) {
        guard !isLogCoolingDown else { return }

        isLogCoolingDown = true
        store.logSet(
            exercise: exercise,
            weight: weight,
            reps: reps,
            rir: 2
        )
        play(.start)
        showFeedback("Sent. Nice work.", style: .success)

        Task {
            try? await Task.sleep(for: .seconds(1.0))
            await MainActor.run {
                isLogCoolingDown = false
                if store.pendingSyncCount > 0 {
                    showFeedback("Queued for iPhone", style: .pending)
                }
            }
        }
    }

    private func handleSnapshotUpdate(_ exercise: ActiveWorkoutExerciseSnapshot) {
        guard exercise.loggedSetCount != lastKnownLoggedSetCount else { return }

        if exercise.loggedSetCount > lastKnownLoggedSetCount {
            play(.success)
            showFeedback("Set \(exercise.loggedSetCount) saved", style: .success)
        }
        lastKnownLoggedSetCount = exercise.loggedSetCount
    }

    private func showFeedback(_ text: String, style: FeedbackStyle) {
        feedbackText = text
        feedbackStyle = style

        Task {
            try? await Task.sleep(for: .seconds(2.0))
            await MainActor.run {
                if feedbackText == text {
                    feedbackText = nil
                }
            }
        }
    }

    private func resetInputs(from exercise: ActiveWorkoutExerciseSnapshot) {
        weight = nearestWeightOption(to: exercise.latestWeight)
        reps = exercise.latestReps
    }

    private func adjustWeight(by step: Double) {
        weight = min(400, max(0, nearestWeightOption(to: weight + step)))
    }

    private func adjustReps(by step: Int) {
        reps = min(repValues.last ?? 40, max(repValues.first ?? 1, reps + step))
    }

    private func logButtonTitle(for exercise: ActiveWorkoutExerciseSnapshot) -> String {
        isLogCoolingDown ? "Logged" : "Log Set"
    }

    private func progress(for exercise: ActiveWorkoutExerciseSnapshot) -> Double {
        guard exercise.targetSets > 0 else { return 0 }
        return min(1, Double(exercise.loggedSetCount) / Double(exercise.targetSets))
    }

    private func nearestWeightOption(to value: Double) -> Double {
        min(400, max(0, (value / 2.5).rounded() * 2.5))
    }

    private func weightLabel(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...1)))) lb"
    }

    private func play(_ notification: WKHapticType) {
        WKInterfaceDevice.current().play(notification)
    }
}

private enum FeedbackStyle {
    case success
    case pending
    case neutral

    var foreground: Color {
        switch self {
        case .success: .green
        case .pending: .orange
        case .neutral: .secondary
        }
    }

    var symbolName: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .pending: "arrow.triangle.2.circlepath"
        case .neutral: "arrow.uturn.backward"
        }
    }
}

private struct CompactValueStepper: View {
    let title: String?
    let value: String
    let decrement: () -> Void
    let increment: () -> Void

    init(
        title: String? = nil,
        value: String,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void
    ) {
        self.title = title
        self.value = value
        self.decrement = decrement
        self.increment = increment
    }

    var body: some View {
        HStack(spacing: 8) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .leading)
            }

            Button(action: decrement) {
                Image(systemName: "minus")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .background(.thinMaterial, in: Circle())

            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            Button(action: increment) {
                Image(systemName: "plus")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .background(.thinMaterial, in: Circle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct FeedbackBanner: View {
    let text: String
    let style: FeedbackStyle

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: style.symbolName)
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(style.foreground)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(style.foreground.opacity(0.16), in: Capsule())
    }
}
