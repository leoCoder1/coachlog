import SwiftData
import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var viewModel: WorkoutSessionViewModel
    @State private var saveError: String?

    let context: WorkoutContext

    init(plan: WorkoutPlan, context: WorkoutContext) {
        self.context = context
        _viewModel = State(initialValue: WorkoutSessionViewModel(plan: plan))
    }

    var body: some View {
        ZStack {
            CoachScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sessionHeader

                    ForEach(viewModel.plan.exercises) { exercise in
                        ExerciseLoggingCard(viewModel: viewModel, exercise: exercise)
                    }

                    Button {
                        finishWorkout()
                    } label: {
                        Label("Finish Workout", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(CoachPrimaryButtonStyle())
                    .disabled(!viewModel.hasLoggedSets)
                }
                .padding()
                .padding(.bottom, CoachLayout.bottomScrollPadding)
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.coachBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            viewModel.prepareFromHistory(sessions: sessions, context: context)
        }
        .alert("Workout could not be saved", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var sessionHeader: some View {
        CoachCard {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(Color.coachAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(context.availableMinutes.displayName) plan")
                        .font(.headline)

                    Text("\(context.energyLevel.displayName) energy · \(context.goal.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                }

                Spacer()

                Text(viewModel.elapsedTimeText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
            }
        }
    }

    private func finishWorkout() {
        let session = viewModel.makeWorkoutSession(context: context)
        modelContext.insert(session)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

private struct ExerciseLoggingCard: View {
    let viewModel: WorkoutSessionViewModel
    let exercise: PlannedExercise

    var body: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)

                        Text("\(exercise.targetSets) sets · \(exercise.targetRepRange) reps · \(exercise.muscleGroup.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                    }

                    Spacer()

                    Image(systemName: exercise.muscleGroup.iconName)
                        .foregroundStyle(Color.coachAccent)
                }

                HStack(spacing: 12) {
                    WheelDoublePickerButton(
                        title: "Weight",
                        unit: "lb",
                        values: viewModel.weightOptions,
                        value: Binding(
                            get: { viewModel.input(for: exercise.id).weight },
                            set: { viewModel.updateWeight($0, for: exercise.id) }
                        )
                    )

                    WheelIntPickerButton(
                        title: "Reps",
                        unit: "reps",
                        values: viewModel.repOptions,
                        value: Binding(
                            get: { viewModel.input(for: exercise.id).reps },
                            set: { viewModel.updateReps($0, for: exercise.id) }
                        )
                    )
                }

                if let suggestion = viewModel.loadSuggestion(for: exercise.id) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "arrow.up.forward.circle")
                            .foregroundStyle(Color.coachAccent)

                        Text(suggestion.message)
                            .font(.caption)
                            .foregroundStyle(Color.coachSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        if suggestion.suggestedWeight != viewModel.input(for: exercise.id).weight {
                            Button {
                                viewModel.useSuggestedWeight(for: exercise.id)
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(CoachSecondaryButtonStyle())
                            .controlSize(.small)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("RIR")
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)

                    Picker(
                        "RIR",
                        selection: Binding(
                            get: { viewModel.input(for: exercise.id).rir },
                            set: { viewModel.updateRIR($0, for: exercise.id) }
                        )
                    ) {
                        Text("0 Max").tag(0)
                        Text("1-2 Hard").tag(2)
                        Text("3+ Easy").tag(3)
                    }
                    .pickerStyle(.segmented)
                }

                Button {
                    viewModel.addSet(for: exercise.id)
                } label: {
                    Label("Add Set", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(CoachSecondaryButtonStyle())

                let sets = viewModel.sets(for: exercise.id)
                if !sets.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                            HStack {
                                Text("Set \(index + 1)")
                                    .font(.subheadline.weight(.semibold))

                                Spacer()

                                Text("\(set.weight.formatted(.number.precision(.fractionLength(0...1)))) lb · \(set.reps) reps · RIR \(set.rir)")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.coachSecondaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}
