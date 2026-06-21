import SwiftData
import SwiftUI

struct TodayCoachView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \RecoverySnapshot.date, order: .reverse) private var recoverySnapshots: [RecoverySnapshot]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var bodyMeasurements: [BodyMeasurement]
    @Query(sort: \WorkoutTemplate.updatedAt, order: .reverse) private var workoutTemplates: [WorkoutTemplate]
    var onManageWorkouts: () -> Void = {}

    @State private var viewModel = TodayCoachViewModel()
    @State private var isShowingMeasurementCheckIn = false
    @State private var isShowingWorkoutSuggestion = false
    @State private var isShowingWeeklyPlanBuilder = false
    private let freshnessEngine = MuscleFreshnessEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        readinessCard
                        todayPlanCard
                        suggestTodayButton
                        generatedPlanCard
                        weeklyLoadCard
                        bodyCheckInCard
                    }
                    .padding()
                    .padding(.bottom, CoachLayout.bottomScrollPadding)
                }
            }
            .navigationTitle("Train")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coachBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .animation(CoachMotion.content, value: sessions.count)
            .animation(CoachMotion.content, value: recoverySnapshots.count)
            .animation(CoachMotion.content, value: bodyMeasurements.count)
            .animation(CoachMotion.content, value: workoutTemplates.map(\.id))
            .animation(CoachMotion.content, value: viewModel.generatedPlan?.id)
            .sheet(isPresented: $isShowingMeasurementCheckIn) {
                BodyMeasurementCheckInView(latestMeasurement: bodyMeasurements.first)
            }
            .sheet(isPresented: $isShowingWorkoutSuggestion) {
                TodayWorkoutSuggestionSheet(
                    viewModel: viewModel,
                    sessions: sessions,
                    recoverySnapshots: recoverySnapshots,
                    measurements: bodyMeasurements
                )
            }
            .sheet(isPresented: $isShowingWeeklyPlanBuilder) {
                WeeklyWorkoutPlanBuilderView()
            }
        }
    }

    private var todayWeekday: WorkoutWeekday {
        WorkoutWeekday.today()
    }

    private var currentWorkoutContext: WorkoutContext {
        WorkoutContext(
            availableMinutes: viewModel.selectedMinutes,
            energyLevel: viewModel.selectedEnergy,
            painFlag: viewModel.selectedPain,
            goal: viewModel.selectedGoal,
            recovery: recoverySnapshots.first.map(RecoverySnapshotSummary.init(snapshot:))
        )
    }

    private var readinessCard: some View {
        ReadinessOverviewCard(snapshot: recoverySnapshots.first)
    }

    private var weeklyLoadCard: some View {
        let loads = freshnessEngine.weeklyLoads(from: sessions)
        let loggedSetCount = freshnessEngine.weeklyLoggedSetCount(from: sessions)
        let activeLoads = MuscleGroup.dashboardGroups
            .compactMap { loads[$0] }
            .filter(\.hasWork)
            .sorted { $0.setCount > $1.setCount }

        return CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("This Week", systemImage: "calendar")
                        .font(.headline)

                    Spacer()

                    Text("\(loggedSetCount) \(loggedSetCount == 1 ? "set" : "sets")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.coachSecondaryText)
                }

                if activeLoads.isEmpty {
                    Text("No workouts logged this week")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                } else {
                    VStack(spacing: 9) {
                        ForEach(activeLoads.prefix(4)) { load in
                            WeeklyLoadRow(load: load)
                        }
                    }
                }
            }
        }
    }

    private var bodyCheckInCard: some View {
        BodyMeasurementReminderCard(measurements: bodyMeasurements) {
            isShowingMeasurementCheckIn = true
        }
    }

    private var todayPlanCard: some View {
        TodayWorkoutPlanCard(
            templates: workoutTemplates,
            context: currentWorkoutContext,
            today: todayWeekday,
            onBuildWeeklyPlan: {
                isShowingWeeklyPlanBuilder = true
            },
            onManagePlan: onManageWorkouts
        )
    }

    private var suggestTodayButton: some View {
        Button {
            isShowingWorkoutSuggestion = true
        } label: {
            Label(
                viewModel.isGenerating ? "Building Suggestion" : "Suggest Today's Workout",
                systemImage: "wand.and.stars"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(CoachPrimaryButtonStyle())
        .disabled(viewModel.isGenerating)
        .contentTransition(.opacity)
    }

    @ViewBuilder
    private var generatedPlanCard: some View {
        if let plan = viewModel.generatedPlan, let context = viewModel.generatedContext {
            CoachCard {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Today's Coaching", systemImage: "sparkles")
                        .font(.headline)

                    if let guidance = viewModel.guidance {
                        TodayGuidanceSummary(guidance: guidance)
                    } else {
                        Text(viewModel.explanation)
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                    }

                    Divider()
                        .overlay(Color.coachBorder)

                    ForEach(plan.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 8) {
                            ExerciseVisualHeader(
                                exercise: exercise,
                                subtitle: "\(exercise.targetSets) sets · \(exercise.targetRepRange) reps · \(exercise.station.rawValue)"
                            )

                            if let advice = viewModel.guidance?.advice(for: exercise.name) {
                                TodayExerciseAdvicePill(advice: advice)
                            }
                        }
                    }

                    NavigationLink {
                        WorkoutSessionView(plan: plan, context: context, guidance: viewModel.guidance)
                    } label: {
                        Label("Start Workout", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(CoachPrimaryButtonStyle())
                }
            }
            .transition(CoachMotion.cardTransition)
        }
    }

}

private struct ReadinessOverviewCard: View {
    var snapshot: RecoverySnapshot?

    private var score: Int? {
        snapshot?.readinessScore
    }

    private var statusTitle: String {
        guard let score else { return "No Snapshot" }

        switch score {
        case 75...:
            return "Ready"
        case 60..<75:
            return "Steady"
        default:
            return "Recover"
        }
    }

    private var statusColor: Color {
        guard let score else { return Color.coachAccent }

        switch score {
        case 75...:
            return Color.freshness(.ready)
        case 60..<75:
            return Color.coachWarm
        default:
            return Color.freshness(.caution)
        }
    }

    private var scoreText: String {
        score.map(String.init) ?? "--"
    }

    var body: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(Color.coachSurfaceMuted, lineWidth: 8)
                            .frame(width: 82, height: 82)

                        if let score {
                            Circle()
                                .trim(from: 0, to: CGFloat(score) / 100)
                                .stroke(statusColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 82, height: 82)
                        }

                        VStack(spacing: 0) {
                            Text(scoreText)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .lineLimit(1)

                            Text("score")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.coachSecondaryText)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Readiness")
                            .font(.headline)

                        Text(statusTitle)
                            .font(.title2.weight(.black))
                            .foregroundStyle(statusColor)

                        Text(snapshot == nil ? "No recovery snapshot yet" : "Recovery stats for today's training decision")
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    ReadinessMetricPill(
                        title: "Sleep",
                        value: sleepValue,
                        iconName: "bed.double.fill"
                    )

                    ReadinessMetricPill(
                        title: "RHR",
                        value: restingHeartRateValue,
                        iconName: "heart.fill"
                    )

                    ReadinessMetricPill(
                        title: "HRV",
                        value: hrvValue,
                        iconName: "waveform.path.ecg"
                    )
                }
            }
        }
    }

    private var sleepValue: String {
        guard let snapshot, snapshot.displaysMetric(.sleep) else { return "--" }
        return "\(snapshot.sleepHours.formatted(.number.precision(.fractionLength(1))))h"
    }

    private var restingHeartRateValue: String {
        guard let snapshot, snapshot.displaysMetric(.restingHeartRate) else { return "--" }
        return "\(snapshot.restingHeartRate.formatted(.number.precision(.fractionLength(0))))"
    }

    private var hrvValue: String {
        guard let snapshot, snapshot.displaysMetric(.hrv) else { return "--" }
        return "\(snapshot.hrv.formatted(.number.precision(.fractionLength(0))))"
    }
}

private struct ReadinessMetricPill: View {
    var title: String
    var value: String
    var iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: iconName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.coachSecondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(.headline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.coachSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.coachBorder, lineWidth: 1)
        }
    }
}

private struct TodayWorkoutSuggestionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TodayCoachViewModel
    var sessions: [WorkoutSession]
    var recoverySnapshots: [RecoverySnapshot]
    var measurements: [BodyMeasurement]

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CoachCard {
                            VStack(alignment: .leading, spacing: 18) {
                                selectorSection("Time") {
                                    Picker("Time", selection: $viewModel.selectedMinutes) {
                                        ForEach(AvailableMinutes.allCases) { minutes in
                                            Text(minutes.displayName).tag(minutes)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .tint(Color.coachAccent)
                                }

                                selectorSection("Energy") {
                                    Picker("Energy", selection: $viewModel.selectedEnergy) {
                                        ForEach(EnergyLevel.allCases) { energy in
                                            Text(energy.displayName).tag(energy)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .tint(Color.coachAccent)
                                }

                                selectorSection("Pain") {
                                    Picker("Pain", selection: $viewModel.selectedPain) {
                                        ForEach(PainFlag.allCases) { pain in
                                            Text(pain.displayName).tag(pain)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .tint(Color.coachAccent)
                                }

                                HStack {
                                    Label("Goal", systemImage: "target")
                                        .font(.headline)

                                    Spacer()

                                    Picker("Goal", selection: $viewModel.selectedGoal) {
                                        ForEach(FitnessGoal.allCases) { goal in
                                            Text(goal.displayName).tag(goal)
                                        }
                                    }
                                }
                            }
                        }
                        .onChange(of: viewModel.selectedMinutes) { _, _ in viewModel.clearGeneratedPlan() }
                        .onChange(of: viewModel.selectedEnergy) { _, _ in viewModel.clearGeneratedPlan() }
                        .onChange(of: viewModel.selectedPain) { _, _ in viewModel.clearGeneratedPlan() }
                        .onChange(of: viewModel.selectedGoal) { _, _ in viewModel.clearGeneratedPlan() }

                        Button {
                            Task {
                                await viewModel.generateWorkout(
                                    sessions: sessions,
                                    recoverySnapshots: recoverySnapshots,
                                    measurements: measurements
                                )
                                dismiss()
                            }
                        } label: {
                            Label(
                                viewModel.isGenerating ? "Thinking" : "Suggest Workout",
                                systemImage: "sparkles"
                            )
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(CoachPrimaryButtonStyle())
                        .disabled(viewModel.isGenerating)
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Suggest Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    private func selectorSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }
}

private struct TodayGuidanceSummary: View {
    var guidance: TodayCoachGuidance

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(guidance.trainingMode.displayName)
                    .font(.caption.weight(.black))
                    .foregroundStyle(modeForeground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(modeBackground, in: Capsule())

                Text(guidance.source == "premium" ? "AI Coach" : "Local Coach")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
            }

            Text(guidance.message)
                .font(.subheadline)
                .foregroundStyle(Color.coachSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var modeForeground: Color {
        switch guidance.trainingMode {
        case .push: Color.black.opacity(0.88)
        case .normal: Color.coachAccent
        case .hold: Color.coachWarm
        case .deload, .rest: Color.freshness(.caution)
        }
    }

    private var modeBackground: AnyShapeStyle {
        switch guidance.trainingMode {
        case .push:
            AnyShapeStyle(CoachGradient.accent)
        case .normal:
            AnyShapeStyle(Color.coachAccent.opacity(0.14))
        case .hold:
            AnyShapeStyle(Color.coachWarm.opacity(0.16))
        case .deload, .rest:
            AnyShapeStyle(Color.freshness(.caution).opacity(0.16))
        }
    }
}

private struct TodayExerciseAdvicePill: View {
    var advice: AICoachExerciseAdvice
    @AppStorage(UnitPreferenceKeys.weightUnit) private var weightUnitRaw = WeightUnitPreference.pounds.rawValue

    private var weightUnit: WeightUnitPreference {
        WeightUnitPreference(rawValue: weightUnitRaw) ?? .pounds
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.semibold))

            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay {
            Capsule()
                .stroke(tint.opacity(0.22), lineWidth: 1)
        }
    }

    private var title: String {
        if advice.action == .increase, let weightText = advice.suggestedWeightText(unit: weightUnit) {
            return "Try \(weightText)"
        }

        return advice.action.displayName
    }

    private var tint: Color {
        switch advice.action {
        case .increase: Color.coachAccent
        case .hold: Color.coachWarm
        case .reduce, .substitute: Color.freshness(.caution)
        }
    }

    private var iconName: String {
        switch advice.action {
        case .increase: "arrow.up.forward"
        case .hold: "pause.fill"
        case .reduce: "arrow.down.forward"
        case .substitute: "arrow.triangle.2.circlepath"
        }
    }
}

struct WorkoutBuilderRoute: Identifiable {
    let id = UUID()
    var template: WorkoutTemplate?
    var defaultWeekday: WorkoutWeekday?
}

private struct WeeklyLoadRow: View {
    var load: WeeklyMuscleLoad

    private var progress: Double {
        min(1, Double(load.setCount) / 10)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: load.group.iconName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.coachAccent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(load.group.rawValue)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(load.setText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.coachSecondaryText)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.coachSurfaceMuted)

                        Capsule()
                            .fill(loadGradient)
                            .frame(width: proxy.size.width * progress)
                    }
                }
                .frame(height: 5)
            }
        }
    }

    private var loadGradient: LinearGradient {
        switch load.setCount {
        case 0...3:
            return CoachGradient.feedback(isPositive: true)
        case 4...7:
            return CoachGradient.warm
        default:
            return CoachGradient.chartFill
        }
    }
}
