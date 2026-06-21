import SwiftData
import SwiftUI

struct SportsPrepView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SportPreferenceKeys.defaultSport) private var defaultSportRaw = CoachSport.cricket.rawValue

    @State private var selectedSport = CoachSport.currentDefault
    @State private var selectedProgram: SportsProgram = .mobility
    @State private var selectedPhase: SportsPrepPhase = .preGame
    @State private var selectedDepth: SportsRoutineDepth = .minimum
    @State private var selectedRole: CricketRole = .allRounder
    @State private var logMessage: String?
    @State private var saveError: String?
    @State private var loggedMovementCounts: [String: Int] = [:]

    private var selectedDefaultSport: CoachSport {
        CoachSport(rawValue: defaultSportRaw) ?? .cricket
    }

    private var plan: SportsTrainingPlan? {
        SportsTrainingLibrary.plan(
            sport: selectedSport,
            program: selectedProgram,
            phase: selectedPhase,
            depth: selectedDepth,
            role: selectedRole
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        selectors

                        if let plan {
                            summary(plan)
                            logControls(plan)
                            routine(plan)
                            researchCard
                        } else {
                            unavailableSportCard
                        }
                    }
                    .padding()
                    .padding(.bottom, CoachLayout.bottomScrollPadding)
                }
            }
            .navigationTitle("Sports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coachBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .animation(CoachMotion.content, value: selectedSport)
            .animation(CoachMotion.content, value: selectedProgram)
            .animation(CoachMotion.content, value: selectedPhase)
            .animation(CoachMotion.content, value: selectedDepth)
            .animation(CoachMotion.content, value: selectedRole)
            .alert("Routine could not be logged", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
            .onAppear {
                selectedSport = selectedDefaultSport
            }
            .onChange(of: defaultSportRaw) { _, _ in
                selectedSport = selectedDefaultSport
            }
        }
    }

    private var selectors: some View {
        CoachCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    SportsCompactMenu(
                        title: "Sport",
                        value: selectedSport.displayName,
                        iconName: selectedSport.iconName
                    ) {
                        ForEach(CoachSport.allCases) { sport in
                            Button {
                                selectedSport = sport
                            } label: {
                                Label(sport.displayName, systemImage: selectedSport == sport ? "checkmark" : sport.iconName)
                            }
                        }
                    }

                    if selectedSport == .cricket {
                        SportsCompactMenu(
                            title: "Role",
                            value: selectedRole.displayName,
                            iconName: "figure.cricket"
                        ) {
                            ForEach(CricketRole.allCases) { role in
                                Button {
                                    selectedRole = role
                                } label: {
                                    Label(role.displayName, systemImage: selectedRole == role ? "checkmark" : "person.fill")
                                }
                            }
                        }
                    }
                }

                selectorSection("Program") {
                    Picker("Program", selection: $selectedProgram) {
                        ForEach(SportsProgram.allCases) { program in
                            Text(program.displayName).tag(program)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.coachAccent)
                }

                if selectedProgram == .mobility {
                    selectorSection("Timing") {
                        Picker("Timing", selection: $selectedPhase) {
                            ForEach(SportsPrepPhase.allCases) { phase in
                                Text(phase.displayName).tag(phase)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Color.coachAccent)
                    }
                }

                selectorSection("Routine") {
                    Picker("Routine", selection: $selectedDepth) {
                        ForEach(SportsRoutineDepth.allCases) { depth in
                            Text(depth.displayName).tag(depth)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.coachAccent)
                }

            }
        }
    }

    private func summary(_ plan: SportsTrainingPlan) -> some View {
        CoachCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Label(plan.title, systemImage: planIconName(plan))
                        .font(.headline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 6) {
                        SportsSummaryBadge(value: plan.formattedTotalTime, iconName: "timer", tint: tintColor(for: plan))
                        SportsSummaryBadge(
                            value: selectedProgram == .mobility ? "10 min" : plan.availableMinutes.displayName,
                            iconName: "stopwatch",
                            tint: tintColor(for: plan)
                        )
                    }
                }

                Text(plan.intent)
                    .font(.subheadline)
                    .foregroundStyle(Color.coachSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                FlowTagRow(values: plan.focusAreas, tint: tintColor(for: plan))
            }
        }
    }

    @ViewBuilder
    private func logControls(_ plan: SportsTrainingPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if plan.program == .mobility {
                Button {
                    logMobilityRoutine(plan)
                } label: {
                    Label("Log Routine", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(CoachPrimaryButtonStyle())
            } else {
                NavigationLink {
                    WorkoutSessionView(
                        plan: plan.workoutPlan,
                        context: workoutContext(for: plan)
                    )
                } label: {
                    Label("Start Strength Session", systemImage: "dumbbell")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(CoachPrimaryButtonStyle())
            }

            if let logMessage {
                Text(logMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachAccent)
                    .transition(CoachMotion.cardTransition)
            }
        }
    }

    private func routine(_ plan: SportsTrainingPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Routine")
                    .font(.headline)

                Spacer()

                Text("\(plan.itemCount) moves")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
            }

            ForEach(plan.blocks) { block in
                CoachCard {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(block.title)
                                .font(.headline)

                            Text(block.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(Color.coachSecondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()
                            .overlay(Color.coachBorder)

                        VStack(spacing: 14) {
                            ForEach(block.items) { item in
                                SportsRoutineMovementRow(
                                    item: item,
                                    tint: tintColor(for: plan),
                                    loggedCount: loggedMovementCounts[item.id, default: 0]
                                ) { draft in
                                    logMovement(item, draft: draft, plan: plan)
                                }

                                if item.id != block.items.last?.id {
                                    Divider()
                                        .overlay(Color.coachBorder)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var unavailableSportCard: some View {
        EmptyStateView(
            iconName: selectedSport.iconName,
            title: "\(selectedSport.displayName) coming soon",
            message: "The Sports tab is ready for multiple sport libraries. Cricket prep and strength routines are available now."
        )
    }

    private var researchCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Research basis", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(SportsTrainingLibrary.researchNotes) { note in
                        HStack(alignment: .top, spacing: 9) {
                            Image(systemName: note.iconName)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.coachAccent)
                                .frame(width: 18)

                            Text(note.text)
                                .font(.footnote)
                                .foregroundStyle(Color.coachSecondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Divider()
                    .overlay(Color.coachBorder)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(SportsTrainingLibrary.sources) { source in
                        Link(destination: source.url) {
                            Label(source.title, systemImage: "link")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.coachAccent)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
        }
    }

    private func selectorSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.coachSecondaryText)
                .frame(width: 56, alignment: .leading)

            content()
        }
    }

    private func logMobilityRoutine(_ plan: SportsTrainingPlan) {
        let completedExercises = plan.allItems.map { item in
            let seconds = item.durationSeconds ?? item.exercise.targetRepsLower
            let completedSet = WorkoutSet(
                weight: 0,
                reps: seconds,
                rir: 3,
                timestamp: Date()
            )

            return CompletedExercise(
                exerciseName: item.exercise.name,
                muscleGroup: item.exercise.muscleGroup,
                sets: [completedSet]
            )
        }

        let session = WorkoutSession(
            duration: TimeInterval(max(60, plan.totalSeconds)),
            energyLevel: .normal,
            painFlag: .none,
            availableMinutes: plan.availableMinutes,
            goal: plan.workoutGoal,
            completedExercises: completedExercises
        )

        modelContext.insert(session)

        do {
            try modelContext.save()
            logMessage = "\(plan.title) logged. Coach and Freshness now include these muscles."
            for item in plan.allItems {
                loggedMovementCounts[item.id, default: 0] += 1
            }
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func logMovement(
        _ item: SportsRoutineItem,
        draft: SportsMovementLogDraft,
        plan: SportsTrainingPlan
    ) -> Bool {
        let completedSet = WorkoutSet(
            weight: draft.weight,
            reps: draft.reps,
            rir: draft.rir,
            timestamp: Date()
        )

        let completedExercise = CompletedExercise(
            exerciseName: item.exercise.name,
            muscleGroup: item.exercise.muscleGroup,
            sets: [completedSet]
        )

        let session = WorkoutSession(
            duration: TimeInterval(max(30, draft.durationSeconds ?? item.durationSeconds ?? 60)),
            energyLevel: .normal,
            painFlag: .none,
            availableMinutes: plan.availableMinutes,
            goal: plan.workoutGoal,
            completedExercises: [completedExercise]
        )

        modelContext.insert(session)

        do {
            try modelContext.save()
            loggedMovementCounts[item.id, default: 0] += 1
            logMessage = "\(item.exercise.name) logged. Freshness now includes this movement."
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    private func workoutContext(for plan: SportsTrainingPlan) -> WorkoutContext {
        WorkoutContext(
            availableMinutes: plan.availableMinutes,
            energyLevel: .normal,
            painFlag: .none,
            goal: plan.workoutGoal,
            recovery: nil
        )
    }

    private func tintColor(for plan: SportsTrainingPlan) -> Color {
        switch plan.program {
        case .strength:
            Color.coachWarm
        case .mobility:
            plan.phase == .postGame ? Color.coachWarm : Color.coachAccent
        }
    }

    private func planIconName(_ plan: SportsTrainingPlan) -> String {
        switch plan.program {
        case .strength:
            "dumbbell"
        case .mobility:
            plan.phase?.iconName ?? "figure.flexibility"
        }
    }
}

private struct SportsCompactMenu<Content: View>: View {
    var title: String
    var value: String
    var iconName: String
    private let content: Content

    init(
        title: String,
        value: String,
        iconName: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.value = value
        self.iconName = iconName
        self.content = content()
    }

    var body: some View {
        Menu {
            content
        } label: {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.coachAccent)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.coachSecondaryText)

                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.coachTertiaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(Color.coachSurfaceElevated)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.coachBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SportsSummaryBadge: View {
    var value: String
    var iconName: String
    var tint: Color

    var body: some View {
        Label(value, systemImage: iconName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.20), lineWidth: 1)
            }
            .clipShape(Capsule())
    }
}

private struct SportsMovementLogDraft {
    var weight: Double
    var reps: Int
    var rir: Int
    var durationSeconds: Int?
}

private struct SportsRoutineMovementRow: View {
    var item: SportsRoutineItem
    var tint: Color
    var loggedCount: Int
    var onLog: (SportsMovementLogDraft) -> Bool

    @AppStorage(UnitPreferenceKeys.weightUnit) private var weightUnitRaw = WeightUnitPreference.pounds.rawValue
    @State private var weight: Double
    @State private var reps: Int
    @State private var durationSeconds: Int
    @State private var rir: Int

    init(
        item: SportsRoutineItem,
        tint: Color,
        loggedCount: Int,
        onLog: @escaping (SportsMovementLogDraft) -> Bool
    ) {
        self.item = item
        self.tint = tint
        self.loggedCount = loggedCount
        self.onLog = onLog
        _weight = State(initialValue: 0)
        _reps = State(initialValue: item.exercise.targetRepsLower)
        _durationSeconds = State(initialValue: item.durationSeconds ?? 60)
        _rir = State(initialValue: item.exercise.kind == .stretch ? 3 : 2)
    }

    private var weightUnit: WeightUnitPreference {
        WeightUnitPreference(rawValue: weightUnitRaw) ?? .pounds
    }

    private var logsDuration: Bool {
        item.durationSeconds != nil || item.exercise.kind == .stretch
    }

    private var showsWeight: Bool {
        item.exercise.kind == .strength
        && item.exercise.equipment != .bodyweight
        && item.exercise.station != .bodyweight
        && item.exercise.station != .mat
    }

    private var durationOptions: [Int] {
        stride(from: 15, through: 600, by: 15).map { $0 }
    }

    private var repOptions: [Int] {
        Array(1...60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExerciseVisualHeader(
                exercise: item.exercise,
                subtitle: item.routineSubtitle
            )

            HStack(spacing: 8) {
                SportsBucketBadge(bucket: item.bucket, tint: tint)

                if let duration = item.formattedDuration {
                    Label(duration, systemImage: "timer")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.coachSecondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.coachSurfaceElevated)
                        .clipShape(Capsule())
                }
            }

            loggingControls
        }
    }

    @ViewBuilder
    private var loggingControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            if logsDuration {
                HStack(spacing: 10) {
                    WheelIntPickerButton(
                        title: "Duration",
                        unit: "sec",
                        values: durationOptions,
                        value: $durationSeconds
                    )
                    .layoutPriority(1)

                    CoachCountdownTimerButton(
                        durationSeconds: $durationSeconds,
                        tint: tint
                    )
                }
            } else {
                HStack(spacing: 10) {
                    if showsWeight {
                        WheelWeightPickerButton(
                            title: "Weight",
                            unit: weightUnit,
                            poundsRange: 0...400,
                            pounds: $weight
                        )
                    }

                    WheelIntPickerButton(
                        title: "Reps",
                        unit: "reps",
                        values: repOptions,
                        value: $reps
                    )
                }

                if item.exercise.kind == .strength {
                    Picker("RIR", selection: $rir) {
                        Text("0 Max").tag(0)
                        Text("1-2 Hard").tag(2)
                        Text("3+ Easy").tag(3)
                    }
                    .pickerStyle(.segmented)
                }
            }

            HStack(spacing: 10) {
                Button {
                    let draft = SportsMovementLogDraft(
                        weight: logsDuration || !showsWeight ? 0 : weight,
                        reps: logsDuration ? durationSeconds : reps,
                        rir: logsDuration ? 3 : rir,
                        durationSeconds: logsDuration ? durationSeconds : nil
                    )
                    _ = onLog(draft)
                } label: {
                    Label(logsDuration ? "Log Move" : "Log Set", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(CoachSecondaryButtonStyle())

                if loggedCount > 0 {
                    Label("\(loggedCount)", systemImage: "checkmark.circle")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(tint.opacity(0.12))
                        .overlay {
                            Capsule()
                                .stroke(tint.opacity(0.22), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                        .accessibilityLabel("\(loggedCount) logs")
                }
            }
        }
    }
}

private struct SportsBucketBadge: View {
    var bucket: SportsRoutineBucket
    var tint: Color

    var body: some View {
        Text(bucket.displayName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(bucket == .minimum ? tint : Color.coachSecondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((bucket == .minimum ? tint : Color.coachSurfaceMuted).opacity(bucket == .minimum ? 0.14 : 0.42))
            .overlay {
                Capsule()
                    .stroke(bucket == .minimum ? tint.opacity(0.20) : Color.coachBorder, lineWidth: 1)
            }
            .clipShape(Capsule())
    }
}

private struct FlowTagRow: View {
    var values: [String]
    var tint: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(tint.opacity(0.12))
                        .overlay {
                            Capsule()
                                .stroke(tint.opacity(0.20), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                }
            }
        }
    }
}
