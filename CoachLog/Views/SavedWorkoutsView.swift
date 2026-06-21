import SwiftData
import SwiftUI
import UIKit

struct TodayWorkoutPlanCard: View {
    var templates: [WorkoutTemplate]
    var context: WorkoutContext
    var today: WorkoutWeekday
    var onBuildWeeklyPlan: () -> Void
    var onManagePlan: () -> Void

    private var todaysTemplates: [WorkoutTemplate] {
        scheduledTemplates.filter { $0.scheduledWeekday == today }
    }

    private var scheduledTemplates: [WorkoutTemplate] {
        sortedTemplates.filter { $0.scheduledWeekday != nil }
    }

    private var sortedTemplates: [WorkoutTemplate] {
        templates.sortedByWorkoutSchedule
    }

    private var hasWeeklyPlan: Bool {
        !scheduledTemplates.isEmpty
    }

    private var nextScheduledTemplate: WorkoutTemplate? {
        guard hasWeeklyPlan,
              let todayIndex = WorkoutWeekday.allCases.firstIndex(of: today) else {
            return nil
        }

        for offset in 1...WorkoutWeekday.allCases.count {
            let day = WorkoutWeekday.allCases[(todayIndex + offset) % WorkoutWeekday.allCases.count]
            if let template = scheduledTemplates.first(where: { $0.scheduledWeekday == day }) {
                return template
            }
        }

        return nil
    }

    private var subtitleText: String {
        if !todaysTemplates.isEmpty {
            return "\(today.rawValue) · \(todaysTemplates.count) ready"
        }

        if hasWeeklyPlan {
            return "\(today.rawValue) · rest day"
        }

        return "No weekly plan yet"
    }

    var body: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.coachAccent)
                        .frame(width: 34)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Plan")
                            .font(.headline)

                        Text(subtitleText)
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                    }

                    Spacer()

                    if hasWeeklyPlan {
                        Button(action: onManagePlan) {
                            Label("Manage", systemImage: "slider.horizontal.3")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(CoachSecondaryButtonStyle())
                    }
                }

                if !hasWeeklyPlan {
                    WeeklyPlanSetupPrompt(onBuildWeeklyPlan: onBuildWeeklyPlan)
                } else if todaysTemplates.isEmpty {
                    NoWorkoutTodayView(
                        today: today,
                        nextTemplate: nextScheduledTemplate
                    )
                } else {
                    VStack(spacing: 10) {
                        ForEach(todaysTemplates) { template in
                            TodayWorkoutTemplateRow(
                                template: template,
                                context: context
                            )
                        }
                    }
                }
            }
        }
    }
}

struct SavedWorkoutsLibrarySection: View {
    var templates: [WorkoutTemplate]
    var context: WorkoutContext
    var onCreate: (WorkoutWeekday?) -> Void
    var onBuildOrModifyWeeklyPlan: ([WorkoutTemplate]) -> Void
    var onDeleteWeeklyPlan: ([WorkoutTemplate]) -> Void
    var onEdit: (WorkoutTemplate) -> Void
    var onShare: (WorkoutTemplate) -> Void
    var onDelete: (WorkoutTemplate) -> Void

    @State private var isConfirmingDeleteWeeklyPlan = false

    private var sortedTemplates: [WorkoutTemplate] {
        templates.sortedByWorkoutSchedule
    }

    private var scheduledTemplates: [WorkoutTemplate] {
        sortedTemplates.filter { $0.scheduledWeekday != nil }
    }

    private var hasWeeklyPlan: Bool {
        !scheduledTemplates.isEmpty
    }

    private var groupedTemplates: [WorkoutTemplateGroup] {
        var groups: [WorkoutTemplateGroup] = []

        for day in WorkoutWeekday.allCases {
            let dayTemplates = sortedTemplates.filter { $0.scheduledWeekday == day }
            guard !dayTemplates.isEmpty else { continue }

            groups.append(
                WorkoutTemplateGroup(
                    id: day.rawValue,
                    title: day.rawValue,
                    templates: dayTemplates
                )
            )
        }

        let anyDayTemplates = sortedTemplates.filter { $0.scheduledWeekday == nil }
        if !anyDayTemplates.isEmpty {
            groups.append(
                WorkoutTemplateGroup(
                    id: "any-day",
                    title: "Any Day",
                    templates: anyDayTemplates
                )
            )
        }

        return groups
    }

    private var planButtonTitle: String {
        hasWeeklyPlan ? "Edit Weekly Plan" : "Build Weekly Plan"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CoachCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.coachAccent)
                            .frame(width: 34)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Workout Library")
                                .font(.headline)

                            Text("\(templates.count) \(templates.count == 1 ? "saved workout" : "saved workouts")")
                                .font(.subheadline)
                                .foregroundStyle(Color.coachSecondaryText)
                        }

                        Spacer()

                        Button {
                            onCreate(nil)
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline)
                                .frame(width: 38, height: 38)
                        }
                        .buttonStyle(CoachSecondaryButtonStyle())
                        .accessibilityLabel("Create saved workout")
                    }

                    Button {
                        onBuildOrModifyWeeklyPlan(scheduledTemplates)
                    } label: {
                        Label(planButtonTitle, systemImage: hasWeeklyPlan ? "calendar.badge.clock" : "calendar.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(CoachPrimaryButtonStyle())

                    if hasWeeklyPlan {
                        Button(role: .destructive) {
                            isConfirmingDeleteWeeklyPlan = true
                        } label: {
                            Label("Delete Weekly Plan", systemImage: "trash")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(CoachSecondaryButtonStyle())
                    } else {
                        Button {
                            onCreate(nil)
                        } label: {
                            Label("Create Workout", systemImage: "plus.circle")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(CoachSecondaryButtonStyle())
                    }
                }
            }

            if templates.isEmpty {
                EmptyStateView(
                    iconName: "figure.strengthtraining.traditional",
                    title: "No saved workouts",
                    message: "Create a workout or build a weekly plan."
                )
            } else {
                VStack(spacing: 14) {
                    ForEach(groupedTemplates) { group in
                        WorkoutTemplateGroupSection(
                            group: group,
                            context: context,
                            onEdit: onEdit,
                            onShare: onShare,
                            onDelete: onDelete
                        )
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete weekly plan?",
            isPresented: $isConfirmingDeleteWeeklyPlan,
            titleVisibility: .visible
        ) {
            Button("Delete Weekly Plan", role: .destructive) {
                onDeleteWeeklyPlan(scheduledTemplates)
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the workouts assigned to weekdays. Any Day workouts stay in your library.")
        }
    }
}

struct WorkoutShareSheet: View {
    @Environment(\.dismiss) private var dismiss

    var template: WorkoutTemplate

    @State private var didCopy = false

    private var sharedWorkout: SharedWorkoutPayload {
        SharedWorkoutPayload(template: template)
    }

    private var shareURL: URL? {
        sharedWorkout.shareURL
    }

    private var shareURLString: String {
        shareURL?.absoluteString ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerCard
                        linkCard
                        shareActions
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Share Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private var headerCard: some View {
        CoachCard {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CoachGradient.accentSoft)
                        .frame(width: 46, height: 46)

                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(Color.coachAccent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(template.name)
                        .font(.title3.weight(.black))
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)

                    Text("\(template.scheduleLabel) · \(template.exerciseCountText) · \(template.estimatedMinutes) min")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                        .lineLimit(2)
                }
            }
        }
    }

    private var linkCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Share Link")
                        .font(.headline)

                    Spacer()

                    if didCopy {
                        Label("Copied", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.coachAccent)
                    }
                }

                Text(shareURLString.isEmpty ? "Unable to create link" : shareURLString)
                    .font(.caption.monospaced())
                    .foregroundStyle(Color.coachSecondaryText)
                    .lineLimit(5)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.coachSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var shareActions: some View {
        VStack(spacing: 10) {
            Button(action: copyLink) {
                Label(didCopy ? "Link Copied" : "Copy Link", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(CoachPrimaryButtonStyle())
            .disabled(shareURLString.isEmpty)

            if let shareURL {
                ShareLink(
                    item: shareURL,
                    subject: Text("AI Coach workout: \(template.name)"),
                    message: Text(sharedWorkout.shareMessage)
                ) {
                    Label("Share Via...", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(CoachSecondaryButtonStyle())
            }
        }
    }

    private func copyLink() {
        guard !shareURLString.isEmpty else { return }

        UIPasteboard.general.string = shareURLString
        didCopy = true
    }
}

private struct WorkoutTemplateGroup: Identifiable {
    var id: String
    var title: String
    var templates: [WorkoutTemplate]
}

private struct WorkoutTemplateGroupSection: View {
    var group: WorkoutTemplateGroup
    var context: WorkoutContext
    var onEdit: (WorkoutTemplate) -> Void
    var onShare: (WorkoutTemplate) -> Void
    var onDelete: (WorkoutTemplate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(group.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.coachSecondaryText)

            VStack(spacing: 10) {
                ForEach(group.templates) { template in
                    SavedWorkoutTemplateRow(
                        template: template,
                        context: context,
                        onEdit: { onEdit(template) },
                        onShare: { onShare(template) },
                        onDelete: { onDelete(template) }
                    )
                }
            }
        }
    }
}

private struct WeeklyPlanSetupPrompt: View {
    var onBuildWeeklyPlan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.coachSurfaceElevated)
                        .frame(width: 42, height: 42)

                    Image(systemName: "calendar.badge.plus")
                        .font(.headline)
                        .foregroundStyle(Color.coachAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Build your week")
                        .font(.headline)

                    Text("Create it once, then adjust it from Library.")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: onBuildWeeklyPlan) {
                Label("Build Weekly Plan", systemImage: "calendar.badge.plus")
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

private struct NoWorkoutTodayView: View {
    var today: WorkoutWeekday
    var nextTemplate: WorkoutTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.coachSurfaceElevated)
                        .frame(width: 42, height: 42)

                    Image(systemName: "moon.zzz.fill")
                        .font(.headline)
                        .foregroundStyle(Color.coachSecondaryText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("No \(today.shortName) workout")
                        .font(.headline)

                    if let nextTemplate {
                        Text("Next: \(nextTemplate.scheduleLabel) · \(nextTemplate.name)")
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Your weekly plan has no workout today.")
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
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

private extension Optional where Wrapped == WorkoutWeekday {
    var weekSortIndex: Int {
        guard let self else { return -1 }
        return WorkoutWeekday.allCases.firstIndex(of: self) ?? 99
    }
}

private extension Array where Element == WorkoutTemplate {
    var sortedByWorkoutSchedule: [WorkoutTemplate] {
        sorted { lhs, rhs in
            let lhsIndex = lhs.scheduledWeekday.weekSortIndex
            let rhsIndex = rhs.scheduledWeekday.weekSortIndex

            if lhsIndex == rhsIndex {
                return lhs.updatedAt > rhs.updatedAt
            }

            return lhsIndex < rhsIndex
        }
    }
}

private struct TodayWorkoutTemplateRow: View {
    var template: WorkoutTemplate
    var context: WorkoutContext

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
        Array(template.orderedExercises.prefix(3))
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
                        .minimumScaleFactor(0.65)
                }

                Spacer(minLength: 0)
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

private struct SavedWorkoutTemplateRow: View {
    var template: WorkoutTemplate
    var context: WorkoutContext
    var onEdit: () -> Void
    var onShare: () -> Void
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

                    Text("\(template.scheduleLabel) · \(template.exerciseCountText) · \(template.estimatedMinutes) min · \(template.goal.displayName)")
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }

                Spacer(minLength: 6)

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption.weight(.bold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(CoachSecondaryButtonStyle())
                .accessibilityLabel("Share \(template.name)")

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
    @State private var scheduledWeekday: WorkoutWeekday?
    @State private var drafts: [WorkoutTemplateExerciseDraft]
    @State private var isShowingExercisePicker = false
    @State private var saveError: String?

    init(template: WorkoutTemplate? = nil, defaultWeekday: WorkoutWeekday? = nil) {
        self.template = template
        _name = State(initialValue: template?.name ?? "")
        _goal = State(initialValue: template?.goal ?? .generalFitness)
        _scheduledWeekday = State(initialValue: template?.scheduledWeekday ?? defaultWeekday)
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

                OptionalWorkoutWeekdayMenu(
                    title: "Day",
                    selection: $scheduledWeekday
                )
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
            template.scheduledWeekday = scheduledWeekday
            template.updatedAt = .now
            template.templateExercises = templateExercises
        } else {
            let template = WorkoutTemplate(
                name: trimmedName,
                goal: goal,
                scheduledWeekday: scheduledWeekday,
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

struct WeeklyWorkoutPlanBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let existingScheduledTemplates: [WorkoutTemplate]
    @State private var selectedGoal: FitnessGoal = .buildMuscle
    @State private var trainingDays = 3
    @State private var selectedMinutes: AvailableMinutes = .forty
    @State private var selectedDays = Set([WorkoutWeekday.monday, .wednesday, .friday])
    @State private var saveError: String?

    init(existingScheduledTemplates: [WorkoutTemplate] = []) {
        let orderedTemplates = existingScheduledTemplates.sortedByWorkoutSchedule
        let scheduledDays = orderedTemplates.compactMap(\.scheduledWeekday)
        let uniqueDays = WorkoutWeekday.allCases.filter { scheduledDays.contains($0) }
        let clampedDayCount = min(max(uniqueDays.count, 2), 5)
        let initialDays = uniqueDays.isEmpty
            ? Set(Self.defaultDays(for: clampedDayCount))
            : Set(uniqueDays.prefix(clampedDayCount))

        self.existingScheduledTemplates = orderedTemplates
        _selectedGoal = State(initialValue: orderedTemplates.first?.goal ?? .buildMuscle)
        _trainingDays = State(initialValue: clampedDayCount)
        _selectedMinutes = State(initialValue: orderedTemplates.first?.availableMinutes ?? .forty)
        _selectedDays = State(initialValue: initialDays)
    }

    private var orderedSelectedDays: [WorkoutWeekday] {
        selectedDays.orderedByWeek
    }

    private var isModifyingExistingPlan: Bool {
        !existingScheduledTemplates.isEmpty
    }

    private var navigationTitle: String {
        isModifyingExistingPlan ? "Modify Weekly Plan" : "Build Weekly Plan"
    }

    private var canSave: Bool {
        orderedSelectedDays.count == trainingDays
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        questionsCard
                        daysCard

                        Button(action: savePlan) {
                            Label(isModifyingExistingPlan ? "Update Weekly Plan" : "Save Weekly Plan", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(CoachPrimaryButtonStyle())
                        .disabled(!canSave)
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Weekly plan could not be saved", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
            .onChange(of: trainingDays) { _, newValue in
                selectedDays = Set(Self.defaultDays(for: newValue))
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    private var questionsCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Plan")
                    .font(.headline)

                Picker("Goal", selection: $selectedGoal) {
                    ForEach(FitnessGoal.allCases) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                }

                selectorSection("Days per week") {
                    Picker("Days per week", selection: $trainingDays) {
                        ForEach(2...5, id: \.self) { dayCount in
                            Text("\(dayCount)x").tag(dayCount)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.coachAccent)
                }

                selectorSection("Session length") {
                    Picker("Session length", selection: $selectedMinutes) {
                        ForEach(AvailableMinutes.allCases) { minutes in
                            Text(minutes.displayName).tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.coachAccent)
                }
            }
        }
    }

    private var daysCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Training Days")
                        .font(.headline)

                    Spacer()

                    Text("\(orderedSelectedDays.count)/\(trainingDays)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(canSave ? Color.coachAccent : Color.coachWarm)
                }

                HStack(spacing: 6) {
                    ForEach(WorkoutWeekday.allCases) { day in
                        dayButton(day)
                    }
                }
            }
        }
    }

    private func selectorSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.coachSecondaryText)
            content()
        }
    }

    private func dayButton(_ day: WorkoutWeekday) -> some View {
        let isSelected = selectedDays.contains(day)

        return Button {
            toggle(day)
        } label: {
            Text(day.shortName)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? Color.black.opacity(0.9) : Color.coachSecondaryText)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(isSelected ? AnyShapeStyle(CoachGradient.accent) : AnyShapeStyle(Color.coachSurfaceElevated))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.white.opacity(0.18) : Color.coachBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ day: WorkoutWeekday) {
        if selectedDays.contains(day) {
            guard selectedDays.count > 1 else { return }
            selectedDays.remove(day)
            return
        }

        if selectedDays.count >= trainingDays, let lastDay = orderedSelectedDays.last {
            selectedDays.remove(lastDay)
        }

        selectedDays.insert(day)
    }

    private func savePlan() {
        guard canSave else { return }

        for template in existingScheduledTemplates {
            modelContext.delete(template)
        }

        let days = orderedSelectedDays
        for (index, day) in days.enumerated() {
            let focusName = focusTitle(for: index, total: days.count)
            let plannedExercises = plannedExercises(for: index, total: days.count, day: day)
            let templateExercises = plannedExercises.enumerated().map { exerciseIndex, exercise in
                WorkoutTemplateExercise(plannedExercise: exercise, orderIndex: exerciseIndex)
            }

            let template = WorkoutTemplate(
                name: "\(day.shortName) \(focusName)",
                goal: selectedGoal,
                scheduledWeekday: day,
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

    private func plannedExercises(
        for index: Int,
        total: Int,
        day: WorkoutWeekday
    ) -> [PlannedExercise] {
        let focusGroups = focusGroups(for: index, total: total)
        let warmUpExercises = warmUpDefinitions(for: focusGroups).map { definition in
            plannedStretch(
                from: definition,
                targetRepsLower: 30,
                targetRepsUpper: 45,
                note: "Warm-up before lifting: move continuously and stay easy."
            )
        }
        let mainDefinitions = exerciseDefinitions(
            for: focusGroups,
            count: strengthExerciseCount
        )
        let repRange = targetRepRange(for: selectedGoal)
        let targetSets = selectedMinutes == .twenty ? 2 : 3
        let mainExercises = mainDefinitions.map { definition in
            PlannedExercise(
                name: definition.name,
                muscleGroup: definition.primaryMuscleGroup,
                secondaryMuscleGroups: definition.secondaryMuscleGroups,
                primaryDetailedMuscle: definition.primaryDetailedMuscle,
                secondaryDetailedMuscle: definition.secondaryDetailedMuscle,
                detailedMuscles: definition.detailedMuscles,
                equipment: definition.equipment,
                station: definition.station,
                kind: definition.kind,
                targetSets: targetSets,
                targetRepsLower: repRange.lowerBound,
                targetRepsUpper: repRange.upperBound,
                coachingNote: "Planned for \(day.rawValue)'s \(focusTitle(for: index, total: total).lowercased()) session."
            )
        }
        let cooldownExercises = cooldownDefinitions(for: focusGroups).map { definition in
            plannedStretch(
                from: definition,
                targetRepsLower: 45,
                targetRepsUpper: 60,
                note: "Cooldown after lifting: breathe slowly and hold without forcing range."
            )
        }

        return warmUpExercises + mainExercises + cooldownExercises
    }

    private var strengthExerciseCount: Int {
        switch selectedMinutes {
        case .twenty:
            return 2
        case .forty:
            return 4
        case .sixty:
            return 6
        }
    }

    private var warmUpCount: Int {
        selectedMinutes == .sixty ? 3 : 2
    }

    private var cooldownCount: Int {
        selectedMinutes == .sixty ? 3 : 2
    }

    private func warmUpDefinitions(for focusGroups: [MuscleGroup]) -> [ExerciseDefinition] {
        var names: [String] = []

        if focusGroups.contains(.legs) || focusGroups.contains(.glutes) {
            names += ["Front and lateral leg swings", "Jog, side shuffle, back pedal"]
        }

        if focusGroups.contains(.chest) || focusGroups.contains(.shoulders) || focusGroups.contains(.triceps) {
            names += ["Arm circles to scapular hugs", "Scapular wall slides or swimmers"]
        }

        if focusGroups.contains(.back) || focusGroups.contains(.core) {
            names += ["Standing thoracic openers", "Thoracic rotations with reach"]
        }

        if focusGroups.contains(.biceps) || focusGroups.contains(.triceps) {
            names += ["Wrist rolls and finger pumps"]
        }

        names += [
            "Jog, side shuffle, back pedal",
            "Arm circles to scapular hugs",
            "Standing thoracic openers"
        ]

        return prioritizedStretchDefinitions(named: names, count: warmUpCount)
    }

    private func cooldownDefinitions(for focusGroups: [MuscleGroup]) -> [ExerciseDefinition] {
        var names = ["Slow walk with nasal breathing"]

        if focusGroups.contains(.legs) || focusGroups.contains(.glutes) {
            names += ["Figure Four Glute Stretch", "Seated Hamstring Stretch", "Calf Wall Stretch"]
        }

        if focusGroups.contains(.chest) || focusGroups.contains(.shoulders) || focusGroups.contains(.triceps) {
            names += ["Doorway Chest Stretch", "Cross-Body Shoulder Stretch"]
        }

        if focusGroups.contains(.back) || focusGroups.contains(.core) || focusGroups.contains(.biceps) {
            names += ["Child's Pose", "Overhead lat and triceps side stretch", "Open-book trunk rotation"]
        }

        names += ["Child's Pose", "Figure Four Glute Stretch", "Doorway Chest Stretch"]

        return prioritizedStretchDefinitions(named: names, count: cooldownCount)
    }

    private func prioritizedStretchDefinitions(
        named names: [String],
        count: Int
    ) -> [ExerciseDefinition] {
        var chosenDefinitions: [ExerciseDefinition] = []

        for name in names {
            guard chosenDefinitions.count < count,
                  let definition = stretchDefinition(named: name),
                  !chosenDefinitions.contains(where: { $0.name == definition.name }) else {
                continue
            }

            chosenDefinitions.append(definition)
        }

        if chosenDefinitions.count < count {
            for definition in ExerciseLibrary.definitions where definition.kind == .stretch && !chosenDefinitions.contains(where: { $0.name == definition.name }) {
                guard chosenDefinitions.count < count else { break }
                chosenDefinitions.append(definition)
            }
        }

        return chosenDefinitions
    }

    private func stretchDefinition(named name: String) -> ExerciseDefinition? {
        ExerciseLibrary.definitions.first {
            $0.kind == .stretch && $0.name == name
        }
    }

    private func plannedStretch(
        from definition: ExerciseDefinition,
        targetRepsLower: Int,
        targetRepsUpper: Int,
        note: String
    ) -> PlannedExercise {
        PlannedExercise(
            name: definition.name,
            muscleGroup: definition.primaryMuscleGroup,
            secondaryMuscleGroups: definition.secondaryMuscleGroups,
            primaryDetailedMuscle: definition.primaryDetailedMuscle,
            secondaryDetailedMuscle: definition.secondaryDetailedMuscle,
            detailedMuscles: definition.detailedMuscles,
            equipment: definition.equipment,
            station: definition.station,
            kind: .stretch,
            targetSets: 1,
            targetRepsLower: targetRepsLower,
            targetRepsUpper: targetRepsUpper,
            coachingNote: note
        )
    }

    private func exerciseDefinitions(
        for focusGroups: [MuscleGroup],
        count: Int
    ) -> [ExerciseDefinition] {
        var chosenDefinitions: [ExerciseDefinition] = []

        while chosenDefinitions.count < count {
            let startingCount = chosenDefinitions.count

            for group in focusGroups {
                guard chosenDefinitions.count < count else { break }
                guard let definition = ExerciseLibrary.definitions.first(where: {
                    $0.kind == .strength
                    && $0.primaryMuscleGroup == group
                    && !chosenDefinitions.contains($0)
                }) else {
                    continue
                }

                chosenDefinitions.append(definition)
            }

            if chosenDefinitions.count == startingCount {
                break
            }
        }

        if chosenDefinitions.count < count {
            for definition in ExerciseLibrary.definitions where definition.kind == .strength && !chosenDefinitions.contains(definition) {
                guard chosenDefinitions.count < count else { break }
                chosenDefinitions.append(definition)
            }
        }

        return Array(chosenDefinitions.prefix(count))
    }

    private func focusGroups(for index: Int, total: Int) -> [MuscleGroup] {
        switch total {
        case 2:
            return [
                [.legs, .glutes, .chest, .back, .core],
                [.back, .shoulders, .legs, .biceps, .triceps]
            ][index]
        case 3:
            return [
                [.legs, .glutes, .core],
                [.chest, .shoulders, .triceps],
                [.back, .biceps, .glutes, .core]
            ][index]
        case 4:
            return [
                [.legs, .glutes],
                [.chest, .shoulders, .triceps],
                [.back, .biceps],
                [.glutes, .legs, .core]
            ][index]
        default:
            return [
                [.chest, .shoulders, .triceps],
                [.back, .biceps],
                [.legs, .glutes],
                [.core, .shoulders, .triceps],
                [.glutes, .legs, .back]
            ][index]
        }
    }

    private func focusTitle(for index: Int, total: Int) -> String {
        switch total {
        case 2:
            return ["Full Body A", "Full Body B"][index]
        case 3:
            return ["Lower", "Push", "Pull + Core"][index]
        case 4:
            return ["Lower", "Push", "Pull", "Lower + Core"][index]
        default:
            return ["Push", "Pull", "Legs", "Core + Shoulders", "Posterior Chain"][index]
        }
    }

    private func targetRepRange(for goal: FitnessGoal) -> ClosedRange<Int> {
        switch goal {
        case .strength:
            return 5...8
        case .buildMuscle:
            return 8...12
        case .fatLoss:
            return 10...15
        case .generalFitness:
            return 8...12
        }
    }

    private static func defaultDays(for dayCount: Int) -> [WorkoutWeekday] {
        switch dayCount {
        case 2:
            return [.monday, .thursday]
        case 3:
            return [.monday, .wednesday, .friday]
        case 4:
            return [.monday, .tuesday, .thursday, .saturday]
        default:
            return [.monday, .tuesday, .wednesday, .friday, .saturday]
        }
    }
}

private extension Set where Element == WorkoutWeekday {
    var orderedByWeek: [WorkoutWeekday] {
        WorkoutWeekday.allCases.filter { contains($0) }
    }
}

private struct OptionalWorkoutWeekdayMenu: View {
    var title: String
    @Binding var selection: WorkoutWeekday?

    private var selectedTitle: String {
        selection?.rawValue ?? "Any day"
    }

    var body: some View {
        Menu {
            Button("Any day") {
                selection = nil
            }

            ForEach(WorkoutWeekday.allCases) { day in
                Button(day.rawValue) {
                    selection = day
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)

                    Text(selectedTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Color.coachSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.coachBorder, lineWidth: 1)
            }
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
                        subtitle: "\(draft.station.rawValue) · \(draft.kind.rawValue)"
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
    @State private var isShowingCustomExercise = false

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(searchText)
                || exercise.primaryDetailedMuscle.rawValue.localizedCaseInsensitiveContains(searchText)
                || (exercise.secondaryDetailedMuscle?.rawValue.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesKind = selectedKind == nil || exercise.kind == selectedKind
            let matchesGroup = selectedGroup == nil
                || exercise.primaryMuscleGroup == selectedGroup
                || exercise.secondaryMuscleGroups.contains { $0 == selectedGroup }

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
                        customExerciseButton
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
            .sheet(isPresented: $isShowingCustomExercise) {
                QuickCustomExerciseSheet(source: .savedWorkoutBuilder) { exercise in
                    guard !selectedExerciseNames.contains(exercise.name) else {
                        dismiss()
                        return
                    }

                    onSelect(exercise)
                    dismiss()
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

enum CustomExerciseTelemetrySource: String {
    case library
    case savedWorkoutBuilder
    case workoutSession
}

private enum CustomExerciseTrainingMode: String, CaseIterable, Identifiable {
    case weightTraining
    case movement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weightTraining: "Weight"
        case .movement: "Movement"
        }
    }

    var kind: ExerciseKind {
        switch self {
        case .weightTraining: .strength
        case .movement: .stretch
        }
    }

    var equipment: Equipment {
        switch self {
        case .weightTraining: .dumbbell
        case .movement: .bodyweight
        }
    }

    var station: GymStation {
        switch self {
        case .weightTraining: .dumbbellRack
        case .movement: .bodyweight
        }
    }

    var iconName: String {
        switch self {
        case .weightTraining: "dumbbell"
        case .movement: "figure.flexibility"
        }
    }
}

struct QuickCustomExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var source: CustomExerciseTelemetrySource
    var onSave: (Exercise) -> Void

    @State private var name = ""
    @State private var trainingMode: CustomExerciseTrainingMode = .weightTraining
    @State private var targetGroup: MuscleGroup?
    @State private var saveError: String?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        detailsCard
                        trackingCard
                        targetCard
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Custom Movement")
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
            .alert("Movement could not be saved", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private var detailsCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Details")
                    .font(.headline)

                TextField("Movement name", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.coachSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var trackingCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tracking")
                    .font(.headline)

                Picker("Tracking", selection: $trainingMode) {
                    ForEach(CustomExerciseTrainingMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.iconName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var targetCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Target")
                    .font(.headline)

                OptionalMuscleGroupWheelPickerButton(
                    title: "Main muscle group",
                    selection: $targetGroup
                )
            }
        }
    }

    private func save() {
        guard canSave else { return }

        let storedGroup = targetGroup ?? .core
        let primaryDetailed = DetailedMuscleGroup.defaults(for: storedGroup)[0]
        let exercise = Exercise(
            name: trimmedName,
            primaryMuscleGroup: storedGroup,
            secondaryMuscleGroups: [],
            equipment: trainingMode.equipment,
            station: trainingMode.station,
            primaryDetailedMuscle: primaryDetailed,
            secondaryDetailedMuscle: nil,
            kind: trainingMode.kind,
            isCustom: true,
            isKneeFriendly: true,
            isShoulderFriendly: true
        )

        modelContext.insert(exercise)

        do {
            try modelContext.save()
            CustomExerciseSuggestionReporter.report(
                exerciseName: trimmedName,
                trackingMode: trainingMode,
                targetGroup: targetGroup,
                storedGroup: storedGroup,
                source: source
            )
            onSave(exercise)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

private struct OptionalMuscleGroupWheelPickerButton: View {
    var title: String
    @Binding var selection: MuscleGroup?

    @State private var isPresented = false

    private var selectedTitle: String {
        selection?.rawValue ?? "Not sure"
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)

                    Text(selectedTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Color.coachSurfaceElevated)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.coachBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                Picker(title, selection: $selection) {
                    Text("Not sure").tag(MuscleGroup?.none)

                    ForEach(MuscleGroup.dashboardGroups) { group in
                        Text(group.rawValue).tag(Optional(group))
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
            }
            .presentationDetents([.height(320)])
            .presentationBackground(Color.coachSurface)
            .preferredColorScheme(.dark)
        }
    }
}

private enum CustomExerciseSuggestionReporter {
    private struct Payload: Encodable {
        var event: String = "customExerciseCreated"
        var exerciseName: String
        var trackingType: String
        var exerciseKind: String
        var targetMuscleGroup: String?
        var storedMuscleGroup: String
        var source: String
        var createdAt: Date
        var appVersion: String?
    }

    static func report(
        exerciseName: String,
        trackingMode: CustomExerciseTrainingMode,
        targetGroup: MuscleGroup?,
        storedGroup: MuscleGroup,
        source: CustomExerciseTelemetrySource,
        defaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        guard let endpointURL = endpointURL(defaults: defaults) else { return }

        let payload = Payload(
            exerciseName: exerciseName,
            trackingType: trackingMode.rawValue,
            exerciseKind: trackingMode.kind.rawValue,
            targetMuscleGroup: targetGroup?.rawValue,
            storedMuscleGroup: storedGroup.rawValue,
            source: source.rawValue,
            createdAt: .now,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        )

        Task {
            await send(payload: payload, to: endpointURL, session: session)
        }
    }

    private static func endpointURL(defaults: UserDefaults) -> URL? {
        let storedEndpoint = defaults.string(forKey: AICoachPreferenceKeys.endpointURL) ?? ""
        let endpointString = storedEndpoint.isEmpty ? AICoachPreferenceKeys.defaultEndpointURL : storedEndpoint

        guard let baseURL = URL(string: endpointString),
              baseURL.scheme?.hasPrefix("http") == true else {
            return nil
        }

        return baseURL
            .appendingPathComponent("events")
            .appendingPathComponent("custom-exercises")
    }

    private static func send(payload: Payload, to endpointURL: URL, session: URLSession) async {
        do {
            var request = URLRequest(url: endpointURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 8
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(payload)

            _ = try await session.data(for: request)
        } catch {
            return
        }
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
            kind: kind,
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
