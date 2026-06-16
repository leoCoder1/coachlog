import SwiftData
import SwiftUI

struct TodayCoachView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \RecoverySnapshot.date, order: .reverse) private var recoverySnapshots: [RecoverySnapshot]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var bodyMeasurements: [BodyMeasurement]
    @State private var viewModel = TodayCoachViewModel()
    @State private var isShowingMeasurementCheckIn = false
    private let freshnessEngine = MuscleFreshnessEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        selectors
                        recoveryCard
                        bodyCheckInCard
                        generateButton
                        weeklyLoadCard
                        generatedPlanCard
                    }
                    .padding()
                    .padding(.bottom, CoachLayout.bottomScrollPadding)
                }
            }
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coachBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .animation(CoachMotion.content, value: sessions.count)
            .animation(CoachMotion.content, value: recoverySnapshots.count)
            .animation(CoachMotion.content, value: bodyMeasurements.count)
            .animation(CoachMotion.content, value: viewModel.generatedPlan?.id)
            .sheet(isPresented: $isShowingMeasurementCheckIn) {
                BodyMeasurementCheckInView(latestMeasurement: bodyMeasurements.first)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ready to train?")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .lineLimit(2)

            Text("Log less. Progress more.")
                .font(.title3)
                .foregroundStyle(Color.coachSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var selectors: some View {
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
    }

    private var recoveryCard: some View {
        CoachCard {
            HStack(spacing: 14) {
                Image(systemName: "heart.text.square")
                    .font(.title2)
                    .foregroundStyle(Color.coachAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery")
                        .font(.headline)

                    if let latest = recoverySnapshots.first {
                        Text("\(latest.sleepHours.formatted(.number.precision(.fractionLength(1)))) hr sleep · \(latest.readinessScore) readiness")
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                    } else {
                        Text("No recovery snapshot yet")
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                    }
                }

                Spacer()
            }
        }
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

    private var generateButton: some View {
        Button {
            Task {
                await viewModel.generateWorkout(
                    sessions: sessions,
                    latestRecovery: recoverySnapshots.first
                )
            }
        } label: {
            Label(
                viewModel.isGenerating ? "Generating" : "Generate Today's Workout",
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

                    Text(viewModel.explanation)
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)

                    Divider()
                        .overlay(Color.coachBorder)

                    ForEach(plan.exercises) { exercise in
                        ExerciseVisualHeader(
                            exercise: exercise,
                            subtitle: "\(exercise.targetSets) sets · \(exercise.targetRepRange) reps · \(exercise.station.rawValue)",
                            note: exercise.coachingNote
                        )
                    }

                    NavigationLink {
                        WorkoutSessionView(plan: plan, context: context)
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
