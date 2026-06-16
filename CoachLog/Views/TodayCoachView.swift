import SwiftData
import SwiftUI

struct TodayCoachView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \RecoverySnapshot.date, order: .reverse) private var recoverySnapshots: [RecoverySnapshot]
    @State private var viewModel = TodayCoachViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        selectors
                        recoveryCard
                        generateButton
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
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: exercise.muscleGroup.iconName)
                                .foregroundStyle(Color.coachAccent)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)

                                Text("\(exercise.targetSets) sets · \(exercise.targetRepRange) reps · \(exercise.equipment.rawValue)")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.coachSecondaryText)

                                Text(exercise.coachingNote)
                                    .font(.caption)
                                    .foregroundStyle(Color.coachSecondaryText)
                            }

                            Spacer()
                        }
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
