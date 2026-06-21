import SwiftUI

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
    @State private var rir = 2

    private var exercise: ActiveWorkoutExerciseSnapshot? {
        store.snapshot?.exercises.first { $0.id == exerciseID }
    }

    private var weightValues: [Double] {
        stride(from: 0.0, through: 400.0, by: 2.5).map { $0 }
    }

    private var repValues: [Int] {
        Array(1...40)
    }

    private var rirValues: [Int] {
        Array(0...3)
    }

    var body: some View {
        Group {
            if let exercise {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(exercise.loggedSetCount)/\(exercise.targetSets) sets")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text("\(exercise.targetRepRange) target reps")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if exercise.showsWeight {
                        Picker("Weight", selection: $weight) {
                            ForEach(weightValues, id: \.self) { value in
                                Text(weightLabel(value)).tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                    }

                    Picker("Reps", selection: $reps) {
                        ForEach(repValues, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)

                    Picker("RIR", selection: $rir) {
                        ForEach(rirValues, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)

                    Button {
                        store.logSet(
                            exercise: exercise,
                            weight: weight,
                            reps: reps,
                            rir: rir
                        )
                    } label: {
                        Label("Log Set", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        store.undoLastSet(exercise: exercise)
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(exercise.loggedSetCount == 0)

                    if store.pendingSyncCount > 0 {
                        Text(store.statusText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
                .navigationTitle(exercise.name)
                .onAppear {
                    resetInputs(from: exercise)
                }
                .onChange(of: store.snapshot) { _, _ in
                    guard let updatedExercise = self.exercise else { return }
                    resetInputs(from: updatedExercise)
                }
            } else {
                Text("Exercise unavailable")
                    .font(.headline)
            }
        }
    }

    private func resetInputs(from exercise: ActiveWorkoutExerciseSnapshot) {
        weight = nearestWeightOption(to: exercise.latestWeight)
        reps = exercise.latestReps
        rir = exercise.latestRIR
    }

    private func nearestWeightOption(to value: Double) -> Double {
        min(400, max(0, (value / 2.5).rounded() * 2.5))
    }

    private func weightLabel(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...1)))) lb"
    }
}
