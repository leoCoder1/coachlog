import SwiftData
import SwiftUI

enum ExerciseLibrarySection: String, CaseIterable, Identifiable {
    case workouts = "Workouts"
    case movements = "Movements"

    var id: String { rawValue }
}

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \WorkoutTemplate.updatedAt, order: .reverse) private var workoutTemplates: [WorkoutTemplate]

    @Binding private var selectedSection: ExerciseLibrarySection
    @State private var searchText = ""
    @State private var selectedGroup: MuscleGroup?
    @State private var selectedKind: ExerciseKind?
    @State private var isShowingAddExercise = false
    @State private var isShowingWeeklyPlanBuilder = false
    @State private var weeklyPlanBuilderTemplates: [WorkoutTemplate] = []
    @State private var workoutBuilderRoute: WorkoutBuilderRoute?
    @State private var sharingTemplate: WorkoutTemplate?

    init(selectedSection: Binding<ExerciseLibrarySection> = .constant(.workouts)) {
        _selectedSection = selectedSection
    }

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(searchText)
                || exercise.primaryDetailedMuscle.rawValue.localizedCaseInsensitiveContains(searchText)
                || (exercise.secondaryDetailedMuscle?.rawValue.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesGroup = selectedGroup == nil
                || exercise.primaryMuscleGroup == selectedGroup
                || exercise.secondaryMuscleGroups.contains { $0 == selectedGroup }
            let matchesKind = selectedKind == nil || exercise.kind == selectedKind

            return matchesSearch && matchesGroup && matchesKind
        }
    }

    private var workoutContext: WorkoutContext {
        WorkoutContext(
            availableMinutes: .forty,
            energyLevel: .normal,
            painFlag: .none,
            goal: .generalFitness,
            recovery: nil
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionPicker

                        switch selectedSection {
                        case .workouts:
                            workoutsLibrary
                        case .movements:
                            searchCard
                            filters
                            libraryList
                        }
                    }
                    .padding()
                    .padding(.bottom, CoachLayout.bottomScrollPadding)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coachBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        handleAddButton()
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline.weight(.semibold))
                    }
                    .accessibilityLabel(selectedSection == .workouts ? "Create saved workout" : "Add custom exercise")
                }
            }
            .sheet(isPresented: $isShowingAddExercise) {
                QuickCustomExerciseSheet(source: .library) { _ in }
            }
            .sheet(isPresented: $isShowingWeeklyPlanBuilder) {
                WeeklyWorkoutPlanBuilderView(existingScheduledTemplates: weeklyPlanBuilderTemplates)
            }
            .sheet(item: $workoutBuilderRoute) { route in
                SavedWorkoutBuilderView(
                    template: route.template,
                    defaultWeekday: route.defaultWeekday
                )
            }
            .sheet(item: $sharingTemplate) { template in
                WorkoutShareSheet(template: template)
            }
        }
    }

    private var sectionPicker: some View {
        Picker("Library section", selection: $selectedSection) {
            ForEach(ExerciseLibrarySection.allCases) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color.coachAccent)
    }

    private var workoutsLibrary: some View {
        SavedWorkoutsLibrarySection(
            templates: workoutTemplates,
            context: workoutContext,
            onCreate: { defaultWeekday in
                workoutBuilderRoute = WorkoutBuilderRoute(template: nil, defaultWeekday: defaultWeekday)
            },
            onBuildOrModifyWeeklyPlan: { scheduledTemplates in
                weeklyPlanBuilderTemplates = scheduledTemplates
                isShowingWeeklyPlanBuilder = true
            },
            onDeleteWeeklyPlan: deleteWeeklyPlan,
            onEdit: { template in
                workoutBuilderRoute = WorkoutBuilderRoute(template: template, defaultWeekday: nil)
            },
            onShare: { template in
                sharingTemplate = template
            },
            onDelete: deleteTemplate
        )
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                kindFilterButton(title: "All", iconName: "line.3.horizontal.decrease.circle", isSelected: selectedKind == nil) {
                    selectedKind = nil
                }

                ForEach(ExerciseKind.allCases) { kind in
                    kindFilterButton(title: kind.rawValue, iconName: kind.iconName, isSelected: selectedKind == kind) {
                        selectedKind = kind
                    }
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                alignment: .leading,
                spacing: 8
            ) {
                muscleFilterButton(title: "All", group: nil, isSelected: selectedGroup == nil) {
                    selectedGroup = nil
                }

                ForEach(MuscleGroup.dashboardGroups) { group in
                    muscleFilterButton(title: group.rawValue, group: group, isSelected: selectedGroup == group) {
                        selectedGroup = group
                    }
                }
            }
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

    private func kindFilterButton(
        title: String,
        iconName: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: iconName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black.opacity(0.88) : Color.coachSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? AnyShapeStyle(CoachGradient.accent) : AnyShapeStyle(Color.coachSurfaceElevated))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func muscleFilterButton(
        title: String,
        group: MuscleGroup?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let group {
                    MuscleGroupGlyph(group: group)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.caption.weight(.semibold))
                }

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .foregroundStyle(isSelected ? Color.black.opacity(0.88) : Color.coachSecondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isSelected ? AnyShapeStyle(CoachGradient.accent) : AnyShapeStyle(Color.coachSurfaceElevated))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func handleAddButton() {
        switch selectedSection {
        case .workouts:
            workoutBuilderRoute = WorkoutBuilderRoute(template: nil, defaultWeekday: nil)
        case .movements:
            isShowingAddExercise = true
        }
    }

    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
    }

    private func deleteWeeklyPlan(_ templates: [WorkoutTemplate]) {
        for template in templates {
            modelContext.delete(template)
        }

        try? modelContext.save()
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
            kind: exercise.kind,
            targetSets: 3,
            targetRepsLower: 8,
            targetRepsUpper: 12,
            coachingNote: ""
        )
    }

    var body: some View {
        CoachCard(padding: 12) {
            HStack(alignment: .top, spacing: 10) {
                ExerciseIllustrationThumbnail(exercise: previewExercise, size: 78)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .truncationMode(.tail)
                            .layoutPriority(1)

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

                    ExerciseMuscleChipRow(
                        groups: [exercise.primaryMuscleGroup] + exercise.secondaryMuscleGroups,
                        primary: exercise.primaryDetailedMuscle,
                        secondary: exercise.secondaryDetailedMuscle,
                        supporting: exercise.detailedMuscles
                    )
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
