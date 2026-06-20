import SwiftData
import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var viewModel: WorkoutSessionViewModel
    @State private var saveError: String?
    @State private var isShowingMovementPicker = false

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
                        ExerciseLoggingCard(
                            viewModel: viewModel,
                            exercise: exercise,
                            sessions: sessions,
                            context: context
                        )
                    }

                    Button {
                        isShowingMovementPicker = true
                    } label: {
                        Label("Add Movement", systemImage: "plus.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(CoachSecondaryButtonStyle())

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
        .animation(CoachMotion.content, value: viewModel.hasLoggedSets)
        .task {
            viewModel.prepareFromHistory(sessions: sessions, context: context)
        }
        .sheet(isPresented: $isShowingMovementPicker) {
            SessionMovementPickerSheet { exercise in
                viewModel.addExercise(exercise, sessions: sessions, context: context)
                isShowingMovementPicker = false
            }
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

private struct SessionMovementPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    var onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var selectedKind: ExerciseKind?
    @State private var isShowingCustomExercise = false

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(searchText)
                || exercise.primaryDetailedMuscle.rawValue.localizedCaseInsensitiveContains(searchText)
            let matchesKind = selectedKind == nil || exercise.kind == selectedKind
            return matchesSearch && matchesKind
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CoachCard(padding: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(Color.coachSecondaryText)

                                TextField("Search library", text: $searchText)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                            }
                        }

                        Picker("Type", selection: $selectedKind) {
                            Text("All").tag(ExerciseKind?.none)

                            ForEach(ExerciseKind.allCases) { kind in
                                Text(kind.rawValue).tag(Optional(kind))
                            }
                        }
                        .pickerStyle(.segmented)

                        customExerciseButton

                        if filteredExercises.isEmpty {
                            EmptyStateView(
                                iconName: "list.bullet.rectangle",
                                title: "No movements",
                                message: "Create a custom movement or adjust the search."
                            )
                        } else {
                            ForEach(filteredExercises) { exercise in
                                Button {
                                    onSelect(exercise)
                                } label: {
                                    ExerciseLibraryRow(exercise: exercise)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .sheet(isPresented: $isShowingCustomExercise) {
                QuickCustomExerciseSheet(source: .workoutSession) { exercise in
                    onSelect(exercise)
                    dismiss()
                }
            }
            .navigationTitle("Add Movement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    private var customExerciseButton: some View {
        Button {
            isShowingCustomExercise = true
        } label: {
            Label("Create custom movement", systemImage: "plus.circle")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(CoachSecondaryButtonStyle())
    }
}

private struct ExerciseLoggingCard: View {
    let viewModel: WorkoutSessionViewModel
    let exercise: PlannedExercise
    let sessions: [WorkoutSession]
    let context: WorkoutContext

    @State private var isShowingSubstitutions = false
    @AppStorage(UnitPreferenceKeys.weightUnit) private var weightUnitRaw = WeightUnitPreference.pounds.rawValue

    private var weightUnit: WeightUnitPreference {
        WeightUnitPreference(rawValue: weightUnitRaw) ?? .pounds
    }

    private var showsWeight: Bool {
        exercise.kind == .strength
        && exercise.equipment != .bodyweight
        && exercise.station != .bodyweight
        && exercise.station != .mat
    }

    private var logsDuration: Bool {
        exercise.kind == .stretch
    }

    private var durationOptions: [Int] {
        [15, 20, 30, 45, 60, 75, 90, 120]
    }

    private var exerciseSubtitle: String {
        if logsDuration {
            return "\(exercise.targetSets) \(exercise.targetSets == 1 ? "hold" : "holds") · \(exercise.targetRepRange) sec · \(exercise.station.rawValue)"
        }

        return "\(exercise.targetSets) sets · \(exercise.targetRepRange) reps · \(exercise.station.rawValue)"
    }

    var body: some View {
        let loggedSets = viewModel.sets(for: exercise.id)

        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                ExerciseVisualHeader(
                    exercise: exercise,
                    subtitle: exerciseSubtitle,
                    note: logsDuration ? exercise.coachingNote : nil
                )

                HStack(spacing: 10) {
                    Label(exercise.equipment.rawValue, systemImage: exercise.station.iconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.coachSecondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    Button {
                        isShowingSubstitutions = true
                    } label: {
                        Label("Busy? Swap", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(CoachSecondaryButtonStyle())
                    .disabled(!loggedSets.isEmpty)
                    .accessibilityHint(loggedSets.isEmpty ? "Choose another exercise for this muscle group" : "Finish or skip this exercise before swapping")
                }

                HStack(spacing: 12) {
                    if logsDuration {
                        WheelIntPickerButton(
                            title: "Duration",
                            unit: "sec",
                            values: durationOptions,
                            value: Binding(
                                get: { viewModel.input(for: exercise.id).reps },
                                set: { viewModel.updateReps($0, for: exercise.id) }
                            )
                        )

                        CoachCountdownTimerButton(
                            title: "Hold Timer",
                            durationSeconds: Binding(
                                get: { viewModel.input(for: exercise.id).reps },
                                set: { viewModel.updateReps($0, for: exercise.id) }
                            ),
                            tint: Color.coachAccent
                        )
                    } else if showsWeight {
                        WheelWeightPickerButton(
                            title: "Weight",
                            unit: weightUnit,
                            poundsRange: 0...400,
                            pounds: Binding(
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
                    } else {
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
                }

                if showsWeight, let suggestion = viewModel.loadSuggestion(for: exercise.id) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "arrow.up.forward.circle")
                            .foregroundStyle(Color.coachAccent)

                        Text(suggestion.displayMessage(weightUnit: weightUnit))
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

                if !logsDuration {
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
                }

                Button {
                    viewModel.addSet(for: exercise.id)
                } label: {
                    Label(logsDuration ? "Log Hold" : "Add Set", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(CoachSecondaryButtonStyle())

                if !loggedSets.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(loggedSets.enumerated()), id: \.element.id) { index, set in
                            HStack {
                                Text("Set \(index + 1)")
                                    .font(.subheadline.weight(.semibold))

                                Spacer()

                                Text(loggedSetSummary(set))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.coachSecondaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .transition(CoachMotion.cardTransition)
                        }
                    }
                    .padding(.top, 4)
                    .animation(CoachMotion.content, value: loggedSets)
                }
            }
        }
        .sheet(isPresented: $isShowingSubstitutions) {
            ExerciseSubstitutionSheet(
                originalExercise: exercise,
                options: viewModel.substitutionOptions(for: exercise, pain: context.painFlag)
            ) { replacement in
                viewModel.replaceExercise(
                    exercise,
                    with: replacement,
                    sessions: sessions,
                    context: context
                )
                isShowingSubstitutions = false
            }
        }
    }

    private func loggedSetSummary(_ set: LoggedSetDraft) -> String {
        if logsDuration {
            return "\(set.reps) sec hold"
        }

        if showsWeight {
            return "\(weightUnit.formattedWeight(set.weight)) · \(set.reps) reps · RIR \(set.rir)"
        }

        return "\(set.reps) reps · RIR \(set.rir)"
    }
}

private struct ExerciseSubstitutionSheet: View {
    @Environment(\.dismiss) private var dismiss

    var originalExercise: PlannedExercise
    var options: [ExerciseSubstitution]
    var onSelect: (PlannedExercise) -> Void

    @State private var selectedStation: GymStation?

    private var filteredOptions: [ExerciseSubstitution] {
        guard let selectedStation else { return options }
        return options.filter { $0.exercise.station == selectedStation }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        currentStationCard
                        stationLibrary
                        substitutionOptions
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Swap Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    private var currentStationCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Current Station", systemImage: originalExercise.station.iconName)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    Text(originalExercise.name)
                        .font(.title3.weight(.bold))

                    Text("\(originalExercise.station.rawValue) · \(originalExercise.muscleImpactText)")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                }

                Text("Pick a substitute when a machine is taken. The list keeps the same primary muscle focus and respects today’s pain flag.")
                    .font(.caption)
                    .foregroundStyle(Color.coachSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var stationLibrary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Machine Library")
                    .font(.headline)

                Spacer()

                Text(selectedStation?.rawValue ?? "All")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    stationFilterButton(title: "All", iconName: "line.3.horizontal.decrease.circle", station: nil)

                    ForEach(GymStation.allCases) { station in
                        stationFilterButton(title: station.rawValue, iconName: station.iconName, station: station)
                    }
                }
            }
        }
    }

    private func stationFilterButton(
        title: String,
        iconName: String,
        station: GymStation?
    ) -> some View {
        let isSelected = selectedStation == station

        return Button {
            selectedStation = station
        } label: {
            Label(title, systemImage: iconName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black.opacity(0.88) : Color.coachSecondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? AnyShapeStyle(CoachGradient.accent) : AnyShapeStyle(Color.coachSurfaceElevated))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var substitutionOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Substitutes")
                .font(.headline)

            if filteredOptions.isEmpty {
                EmptyStateView(
                    iconName: "arrow.triangle.2.circlepath",
                    title: "No safe swaps found",
                    message: selectedStation == nil
                        ? "Try changing today's pain flag or use a custom movement for this session."
                        : "No safe \(selectedStation?.rawValue ?? "station") swaps match this muscle group today."
                )
            } else {
                ForEach(filteredOptions) { option in
                    Button {
                        onSelect(option.exercise)
                    } label: {
                        CoachCard {
                            HStack(spacing: 12) {
                                ExerciseIllustrationThumbnail(exercise: option.exercise, size: 58)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(option.exercise.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text(option.reason)
                                        .font(.caption)
                                        .foregroundStyle(Color.coachSecondaryText)

                                    ExerciseMuscleChipRow(
                                        groups: option.exercise.affectedMuscleGroups,
                                        primary: option.exercise.primaryDetailedMuscle,
                                        secondary: option.exercise.secondaryDetailedMuscle,
                                        supporting: option.exercise.detailedMuscles
                                    )
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.coachTertiaryText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
