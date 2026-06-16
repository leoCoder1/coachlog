import SwiftData
import SwiftUI

struct SavedWorkoutTemplateSection: View {
    var templates: [WorkoutTemplate]
    var context: WorkoutContext
    var onCreate: () -> Void
    var onEdit: (WorkoutTemplate) -> Void
    var onDelete: (WorkoutTemplate) -> Void

    var body: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.coachAccent)
                        .frame(width: 34)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Workouts")
                            .font(.headline)

                        Text(templates.isEmpty ? "Saved sets for days you already have a plan" : "\(templates.count) saved")
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                    }

                    Spacer()

                    Button(action: onCreate) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(CoachSecondaryButtonStyle())
                    .accessibilityLabel("Create saved workout")
                }

                if templates.isEmpty {
                    Button(action: onCreate) {
                        Label("Create Workout", systemImage: "plus.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(CoachSecondaryButtonStyle())
                } else {
                    VStack(spacing: 10) {
                        ForEach(templates) { template in
                            SavedWorkoutTemplateRow(
                                template: template,
                                context: context,
                                onEdit: { onEdit(template) },
                                onDelete: { onDelete(template) }
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct SavedWorkoutTemplateRow: View {
    var template: WorkoutTemplate
    var context: WorkoutContext
    var onEdit: () -> Void
    var onDelete: () -> Void

    private var sessionContext: WorkoutContext {
        WorkoutContext(
            availableMinutes: template.availableMinutes,
            energyLevel: context.energyLevel,
            painFlag: context.painFlag,
            goal: template.goal,
            recovery: context.recovery
        )
    }

    private var previewExercises: [WorkoutTemplateExercise] {
        Array(template.orderedExercises.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CoachGradient.accentSoft)
                        .frame(width: 42, height: 42)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.headline)
                        .foregroundStyle(Color.coachAccent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(template.name)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("\(template.exerciseCountText) · \(template.estimatedMinutes) min · \(template.goal.displayName)")
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 6)

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.bold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(CoachSecondaryButtonStyle())
                .accessibilityLabel("Edit \(template.name)")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption.weight(.bold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(CoachSecondaryButtonStyle())
                .accessibilityLabel("Delete \(template.name)")
            }

            if !previewExercises.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(previewExercises) { exercise in
                            Text(exercise.exerciseName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.coachSecondaryText)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(Color.coachSurface)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            NavigationLink {
                WorkoutSessionView(plan: template.makeWorkoutPlan(), context: sessionContext)
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(CoachPrimaryButtonStyle())
        }
        .padding(12)
        .background(Color.coachSurfaceElevated.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.coachBorder, lineWidth: 1)
        }
    }
}

struct SavedWorkoutBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let template: WorkoutTemplate?

    @State private var name: String
    @State private var goal: FitnessGoal
    @State private var drafts: [WorkoutTemplateExerciseDraft]
    @State private var isShowingExercisePicker = false
    @State private var saveError: String?

    init(template: WorkoutTemplate? = nil) {
        self.template = template
        _name = State(initialValue: template?.name ?? "")
        _goal = State(initialValue: template?.goal ?? .generalFitness)
        _drafts = State(initialValue: template?.orderedExercises.map(WorkoutTemplateExerciseDraft.init(templateExercise:)) ?? [])
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !drafts.isEmpty
    }

    private var selectedExerciseIDs: Set<UUID> {
        Set(drafts.compactMap(\.sourceExerciseID))
    }

    private var selectedExerciseNames: Set<String> {
        Set(drafts.map(\.exerciseName))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        detailsCard
                        movementsSection
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(template == nil ? "Create Workout" : "Edit Workout")
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
            .sheet(isPresented: $isShowingExercisePicker) {
                SavedWorkoutExercisePickerSheet(
                    selectedExerciseIDs: selectedExerciseIDs,
                    selectedExerciseNames: selectedExerciseNames
                ) { exercise in
                    drafts.append(WorkoutTemplateExerciseDraft(exercise: exercise, orderIndex: drafts.count))
                    isShowingExercisePicker = false
                }
            }
            .alert("Workout could not be saved", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var detailsCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Details")
                    .font(.headline)

                TextField("Workout name", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.coachSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Picker("Goal", selection: $goal) {
                    ForEach(FitnessGoal.allCases) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                }
            }
        }
    }

    private var movementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Movements")
                    .font(.headline)

                Spacer()

                Button {
                    isShowingExercisePicker = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
                .buttonStyle(CoachSecondaryButtonStyle())
            }

            if drafts.isEmpty {
                EmptyStateView(
                    iconName: "list.bullet.rectangle",
                    title: "No movements yet",
                    message: "Add exercises or stretches from the library."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                        SavedWorkoutDraftRow(
                            draft: Binding(
                                get: { drafts[index] },
                                set: { drafts[index] = $0 }
                            ),
                            canMoveUp: index > 0,
                            canMoveDown: index < drafts.count - 1,
                            onMoveUp: { moveDraft(from: index, to: index - 1) },
                            onMoveDown: { moveDraft(from: index, to: index + 1) },
                            onDelete: { removeDraft(id: draft.id) }
                        )
                    }
                }
            }
        }
    }

    private func moveDraft(from sourceIndex: Int, to destinationIndex: Int) {
        guard drafts.indices.contains(sourceIndex), drafts.indices.contains(destinationIndex) else { return }
        let draft = drafts.remove(at: sourceIndex)
        drafts.insert(draft, at: destinationIndex)
        refreshOrder()
    }

    private func removeDraft(id: UUID) {
        drafts.removeAll { $0.id == id }
        refreshOrder()
    }

    private func refreshOrder() {
        for index in drafts.indices {
            drafts[index].orderIndex = index
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !drafts.isEmpty else { return }

        let templateExercises = drafts.enumerated().map { index, draft in
            draft.makeTemplateExercise(orderIndex: index)
        }

        if let template {
            let oldExercises = template.templateExercises
            template.templateExercises = []
            for exercise in oldExercises {
                modelContext.delete(exercise)
            }

            template.name = trimmedName
            template.goal = goal
            template.updatedAt = .now
            template.templateExercises = templateExercises
        } else {
            let template = WorkoutTemplate(
                name: trimmedName,
                goal: goal,
                templateExercises: templateExercises
            )
            modelContext.insert(template)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

private struct SavedWorkoutDraftRow: View {
    @Binding var draft: WorkoutTemplateExerciseDraft
    var canMoveUp: Bool
    var canMoveDown: Bool
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var onDelete: () -> Void

    private let setOptions = Array(1...8)
    private let repRanges = [
        RepRange(lower: 5, upper: 5),
        RepRange(lower: 6, upper: 8),
        RepRange(lower: 8, upper: 10),
        RepRange(lower: 8, upper: 12),
        RepRange(lower: 10, upper: 12),
        RepRange(lower: 12, upper: 15),
        RepRange(lower: 15, upper: 20),
        RepRange(lower: 20, upper: 30),
        RepRange(lower: 30, upper: 45)
    ]

    var body: some View {
        CoachCard(padding: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Text("\(draft.orderIndex + 1)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.black.opacity(0.9))
                        .frame(width: 28, height: 28)
                        .background(CoachGradient.accent)
                        .clipShape(Circle())

                    ExerciseVisualHeader(
                        exercise: draft.plannedExercise,
                        subtitle: "\(draft.station.rawValue) · \(draft.kind.rawValue)",
                        note: nil
                    )

                    VStack(spacing: 6) {
                        Button(action: onMoveUp) {
                            Image(systemName: "chevron.up")
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(CoachSecondaryButtonStyle())
                        .disabled(!canMoveUp)

                        Button(action: onMoveDown) {
                            Image(systemName: "chevron.down")
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(CoachSecondaryButtonStyle())
                        .disabled(!canMoveDown)
                    }
                }

                HStack(spacing: 10) {
                    targetMenu(
                        title: "\(draft.targetSets) sets",
                        iconName: "list.number"
                    ) {
                        ForEach(setOptions, id: \.self) { sets in
                            Button("\(sets) \(sets == 1 ? "set" : "sets")") {
                                draft.targetSets = sets
                            }
                        }
                    }

                    targetMenu(
                        title: "\(draft.targetRepsLower)-\(draft.targetRepsUpper) reps",
                        iconName: "repeat"
                    ) {
                        ForEach(repRanges) { range in
                            Button(range.title) {
                                draft.targetRepsLower = range.lower
                                draft.targetRepsUpper = range.upper
                            }
                        }
                    }

                    Spacer()

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption.weight(.bold))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(CoachSecondaryButtonStyle())
                    .accessibilityLabel("Remove \(draft.exerciseName)")
                }
            }
        }
    }

    private func targetMenu<Content: View>(
        title: String,
        iconName: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            Label(title, systemImage: iconName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.coachAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.coachSurfaceElevated)
                .clipShape(Capsule())
        }
    }
}

private struct SavedWorkoutExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    var selectedExerciseIDs: Set<UUID>
    var selectedExerciseNames: Set<String>
    var onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var selectedKind: ExerciseKind?
    @State private var selectedGroup: MuscleGroup?

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(searchText)
                || exercise.primaryDetailedMuscle.rawValue.localizedCaseInsensitiveContains(searchText)
                || (exercise.secondaryDetailedMuscle?.rawValue.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesKind = selectedKind == nil || exercise.kind == selectedKind
            let matchesGroup = selectedGroup == nil || exercise.primaryMuscleGroup == selectedGroup

            return matchesSearch && matchesKind && matchesGroup
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        searchCard
                        filters
                        exerciseList
                    }
                    .padding()
                    .padding(.bottom, 24)
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

    private var searchCard: some View {
        CoachCard(padding: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.coachSecondaryText)

                TextField("Search library", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Type", selection: $selectedKind) {
                Text("All").tag(ExerciseKind?.none)

                ForEach(ExerciseKind.allCases) { kind in
                    Text(kind.rawValue).tag(Optional(kind))
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterButton(title: "All muscles", iconName: "line.3.horizontal.decrease.circle", group: nil)

                    ForEach(MuscleGroup.dashboardGroups) { group in
                        filterButton(title: group.rawValue, iconName: group.iconName, group: group)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var exerciseList: some View {
        if filteredExercises.isEmpty {
            EmptyStateView(
                iconName: "magnifyingglass",
                title: "No movement found",
                message: "Adjust the filters or add a custom exercise from the Library tab."
            )
        } else {
            VStack(spacing: 12) {
                ForEach(filteredExercises) { exercise in
                    let isSelected = selectedExerciseIDs.contains(exercise.id) || selectedExerciseNames.contains(exercise.name)

                    Button {
                        guard !isSelected else { return }
                        onSelect(exercise)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            ExerciseLibraryRow(exercise: exercise)
                                .opacity(isSelected ? 0.48 : 1)

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.coachAccent)
                                    .padding(12)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSelected)
                }
            }
        }
    }

    private func filterButton(title: String, iconName: String, group: MuscleGroup?) -> some View {
        let isSelected = selectedGroup == group

        return Button {
            selectedGroup = group
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
}

private struct WorkoutTemplateExerciseDraft: Identifiable, Hashable {
    var id: UUID
    var sourceExerciseID: UUID?
    var orderIndex: Int
    var exerciseName: String
    var primaryMuscleGroup: MuscleGroup
    var secondaryMuscleGroups: [MuscleGroup]
    var equipment: Equipment
    var station: GymStation
    var primaryDetailedMuscle: DetailedMuscleGroup
    var secondaryDetailedMuscle: DetailedMuscleGroup?
    var kind: ExerciseKind
    var targetSets: Int
    var targetRepsLower: Int
    var targetRepsUpper: Int
    var coachingNote: String

    init(exercise: Exercise, orderIndex: Int) {
        self.id = UUID()
        self.sourceExerciseID = exercise.id
        self.orderIndex = orderIndex
        self.exerciseName = exercise.name
        self.primaryMuscleGroup = exercise.primaryMuscleGroup
        self.secondaryMuscleGroups = exercise.secondaryMuscleGroups
        self.equipment = exercise.equipment
        self.station = exercise.station
        self.primaryDetailedMuscle = exercise.primaryDetailedMuscle
        self.secondaryDetailedMuscle = exercise.secondaryDetailedMuscle
        self.kind = exercise.kind
        self.targetSets = exercise.kind == .stretch ? 2 : 3
        self.targetRepsLower = exercise.kind == .stretch ? 20 : 8
        self.targetRepsUpper = exercise.kind == .stretch ? 30 : 12
        self.coachingNote = "From your saved workout."
    }

    init(templateExercise: WorkoutTemplateExercise) {
        self.id = templateExercise.id
        self.sourceExerciseID = templateExercise.sourceExerciseID
        self.orderIndex = templateExercise.orderIndex
        self.exerciseName = templateExercise.exerciseName
        self.primaryMuscleGroup = templateExercise.primaryMuscleGroup
        self.secondaryMuscleGroups = templateExercise.secondaryMuscleGroups
        self.equipment = templateExercise.equipment
        self.station = templateExercise.station
        self.primaryDetailedMuscle = templateExercise.primaryDetailedMuscle
        self.secondaryDetailedMuscle = templateExercise.secondaryDetailedMuscle
        self.kind = templateExercise.kind
        self.targetSets = templateExercise.targetSets
        self.targetRepsLower = templateExercise.targetRepsLower
        self.targetRepsUpper = templateExercise.targetRepsUpper
        self.coachingNote = templateExercise.coachingNote
    }

    var plannedExercise: PlannedExercise {
        PlannedExercise(
            name: exerciseName,
            muscleGroup: primaryMuscleGroup,
            secondaryMuscleGroups: secondaryMuscleGroups,
            primaryDetailedMuscle: primaryDetailedMuscle,
            secondaryDetailedMuscle: secondaryDetailedMuscle,
            detailedMuscles: detailedMuscles,
            equipment: equipment,
            station: station,
            targetSets: targetSets,
            targetRepsLower: targetRepsLower,
            targetRepsUpper: targetRepsUpper,
            coachingNote: coachingNote
        )
    }

    private var detailedMuscles: [DetailedMuscleGroup] {
        var muscles = [primaryDetailedMuscle]

        if let secondaryDetailedMuscle, secondaryDetailedMuscle != primaryDetailedMuscle {
            muscles.append(secondaryDetailedMuscle)
        }

        return muscles
    }

    func makeTemplateExercise(orderIndex: Int) -> WorkoutTemplateExercise {
        WorkoutTemplateExercise(
            sourceExerciseID: sourceExerciseID,
            orderIndex: orderIndex,
            exerciseName: exerciseName,
            primaryMuscleGroup: primaryMuscleGroup,
            secondaryMuscleGroups: secondaryMuscleGroups,
            equipment: equipment,
            station: station,
            primaryDetailedMuscle: primaryDetailedMuscle,
            secondaryDetailedMuscle: secondaryDetailedMuscle,
            kind: kind,
            targetSets: targetSets,
            targetRepsLower: targetRepsLower,
            targetRepsUpper: targetRepsUpper,
            coachingNote: coachingNote
        )
    }
}

private struct RepRange: Identifiable, Hashable {
    var lower: Int
    var upper: Int

    var id: String { "\(lower)-\(upper)" }
    var title: String { lower == upper ? "\(lower) reps" : "\(lower)-\(upper) reps" }
}
