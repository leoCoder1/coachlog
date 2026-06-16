import SwiftData
import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedGroup: MuscleGroup?
    @State private var selectedKind: ExerciseKind?
    @State private var isShowingAddExercise = false

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(searchText)
                || exercise.primaryDetailedMuscle.rawValue.localizedCaseInsensitiveContains(searchText)
                || (exercise.secondaryDetailedMuscle?.rawValue.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesGroup = selectedGroup == nil || exercise.primaryMuscleGroup == selectedGroup
            let matchesKind = selectedKind == nil || exercise.kind == selectedKind

            return matchesSearch && matchesGroup && matchesKind
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        searchCard
                        filters
                        libraryList
                    }
                    .padding()
                    .padding(.bottom, CoachLayout.bottomScrollPadding)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coachBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $isShowingAddExercise) {
                AddCustomExerciseView()
            }
        }
    }

    private var header: some View {
        CoachCard {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.coachAccent)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise Library")
                        .font(.title3.weight(.bold))

                    Text("\(exercises.count) movements · \(exercises.filter(\.isCustom).count) custom")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                }

                Spacer()

                Button {
                    isShowingAddExercise = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(CoachSecondaryButtonStyle())
                .accessibilityLabel("Add custom exercise")
            }
        }
    }

    private var searchCard: some View {
        CoachCard(padding: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.coachSecondaryText)

                TextField("Search exercise or muscle", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.coachSecondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            horizontalFilters(
                title: "Type",
                allTitle: "All",
                values: ExerciseKind.allCases,
                selection: $selectedKind,
                label: \.rawValue,
                icon: \.iconName
            )

            horizontalFilters(
                title: "Muscle",
                allTitle: "All muscles",
                values: MuscleGroup.dashboardGroups,
                selection: $selectedGroup,
                label: \.rawValue,
                icon: \.iconName
            )
        }
    }

    private var libraryList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Movements")
                    .font(.headline)

                Spacer()

                Text("\(filteredExercises.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
            }

            if filteredExercises.isEmpty {
                EmptyStateView(
                    iconName: "magnifyingglass",
                    title: "No movement found",
                    message: "Adjust the filters or add a custom exercise for your gym."
                )
            } else {
                ForEach(filteredExercises) { exercise in
                    ExerciseLibraryRow(exercise: exercise)
                        .transition(CoachMotion.cardTransition)
                }
            }
        }
        .animation(CoachMotion.content, value: filteredExercises.map(\.id))
    }

    private func horizontalFilters<Value: Identifiable & Hashable>(
        title: String,
        allTitle: String,
        values: [Value],
        selection: Binding<Value?>,
        label: KeyPath<Value, String>,
        icon: KeyPath<Value, String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.coachSecondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterButton(title: allTitle, iconName: "line.3.horizontal.decrease.circle", isSelected: selection.wrappedValue == nil) {
                        selection.wrappedValue = nil
                    }

                    ForEach(values) { value in
                        filterButton(title: value[keyPath: label], iconName: value[keyPath: icon], isSelected: selection.wrappedValue == value) {
                            selection.wrappedValue = value
                        }
                    }
                }
            }
        }
    }

    private func filterButton(
        title: String,
        iconName: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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
}

struct ExerciseLibraryRow: View {
    var exercise: Exercise

    private var previewExercise: PlannedExercise {
        PlannedExercise(
            name: exercise.name,
            muscleGroup: exercise.primaryMuscleGroup,
            secondaryMuscleGroups: exercise.secondaryMuscleGroups,
            primaryDetailedMuscle: exercise.primaryDetailedMuscle,
            secondaryDetailedMuscle: exercise.secondaryDetailedMuscle,
            detailedMuscles: exercise.detailedMuscles,
            equipment: exercise.equipment,
            station: exercise.station,
            targetSets: 3,
            targetRepsLower: 8,
            targetRepsUpper: 12,
            coachingNote: ""
        )
    }

    var body: some View {
        CoachCard {
            HStack(spacing: 12) {
                ExerciseIllustrationThumbnail(exercise: previewExercise, size: 62)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        if exercise.isCustom {
                            Text("Custom")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.coachAccent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.coachAccent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(exercise.kind.rawValue) · \(exercise.station.rawValue)")
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)
                        .lineLimit(1)

                    MuscleChipRow(groups: [exercise.primaryMuscleGroup] + exercise.secondaryMuscleGroups)
                    DetailedMuscleTagRow(primary: exercise.primaryDetailedMuscle, secondary: exercise.secondaryDetailedMuscle)
                }

                Spacer(minLength: 4)

                MuscleImpactMap(
                    primary: exercise.primaryDetailedMuscle,
                    secondary: exercise.secondaryDetailedMuscle,
                    supporting: exercise.detailedMuscles
                )
                .frame(width: 44, height: 66)
            }
        }
    }
}

private struct AddCustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var kind: ExerciseKind = .strength
    @State private var primaryGroup: MuscleGroup = .chest
    @State private var secondaryGroup: MuscleGroup = .triceps
    @State private var equipment: Equipment = .dumbbell
    @State private var station: GymStation = .dumbbellRack
    @State private var primaryDetailed: DetailedMuscleGroup = .midChest
    @State private var secondaryDetailed: DetailedMuscleGroup = .triceps
    @State private var isKneeFriendly = true
    @State private var isShoulderFriendly = true

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        detailsCard
                        muscleCard
                        equipmentCard
                        safetyCard
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Add Movement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: primaryGroup) { _, newValue in
            primaryDetailed = DetailedMuscleGroup.defaults(for: newValue)[0]
            secondaryDetailed = defaultSecondaryDetailed(primary: newValue, secondary: secondaryGroup)
        }
        .onChange(of: secondaryGroup) { _, newValue in
            secondaryDetailed = defaultSecondaryDetailed(primary: primaryGroup, secondary: newValue)
        }
    }

    private var detailsCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Details")
                    .font(.headline)

                TextField("Exercise or stretch name", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.coachSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Picker("Type", selection: $kind) {
                    ForEach(ExerciseKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var muscleCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Muscles")
                    .font(.headline)

                Picker("Primary group", selection: $primaryGroup) {
                    ForEach(MuscleGroup.dashboardGroups) { group in
                        Text(group.rawValue).tag(group)
                    }
                }

                Picker("Secondary group", selection: $secondaryGroup) {
                    ForEach(MuscleGroup.dashboardGroups) { group in
                        Text(group.rawValue).tag(group)
                    }
                }

                Picker("Primary muscle", selection: $primaryDetailed) {
                    ForEach(DetailedMuscleGroup.allCases) { muscle in
                        Text(muscle.rawValue).tag(muscle)
                    }
                }

                Picker("Secondary muscle", selection: $secondaryDetailed) {
                    ForEach(DetailedMuscleGroup.allCases) { muscle in
                        Text(muscle.rawValue).tag(muscle)
                    }
                }

                DetailedMuscleTagRow(primary: primaryDetailed, secondary: secondaryDetailed)
            }
        }
    }

    private var equipmentCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Equipment")
                    .font(.headline)

                Picker("Equipment", selection: $equipment) {
                    ForEach(Equipment.allCases) { equipment in
                        Text(equipment.rawValue).tag(equipment)
                    }
                }

                Picker("Station", selection: $station) {
                    ForEach(GymStation.allCases) { station in
                        Text(station.rawValue).tag(station)
                    }
                }
            }
        }
    }

    private var safetyCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Swap Safety")
                    .font(.headline)

                Toggle("Knee-friendly", isOn: $isKneeFriendly)
                Toggle("Shoulder-friendly", isOn: $isShoulderFriendly)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let secondaryGroups = primaryGroup == secondaryGroup ? [] : [secondaryGroup]
        let exercise = Exercise(
            name: trimmedName,
            primaryMuscleGroup: primaryGroup,
            secondaryMuscleGroups: secondaryGroups,
            equipment: equipment,
            station: station,
            primaryDetailedMuscle: primaryDetailed,
            secondaryDetailedMuscle: secondaryDetailed == primaryDetailed ? nil : secondaryDetailed,
            kind: kind,
            isCustom: true,
            isKneeFriendly: isKneeFriendly,
            isShoulderFriendly: isShoulderFriendly
        )

        modelContext.insert(exercise)
        try? modelContext.save()
        dismiss()
    }

    private func defaultSecondaryDetailed(primary: MuscleGroup, secondary: MuscleGroup) -> DetailedMuscleGroup {
        let candidates = DetailedMuscleGroup.defaults(for: secondary)
        return candidates.first { $0.parentGroup != primary || $0 != primaryDetailed } ?? candidates[0]
    }
}
