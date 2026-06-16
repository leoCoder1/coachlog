import Charts
import SwiftData
import SwiftUI

struct ProgressScreen: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @Query(sort: \StrengthBaselineTest.date, order: .reverse) private var baselineTests: [StrengthBaselineTest]

    private var weeklyVolume: [WeeklyVolumePoint] {
        ProgressViewModel.weeklyVolumeTrend(sessions)
    }

    private var bestLifts: [BestLift] {
        ProgressViewModel.bestLifts(sessions)
    }

    private var bodyWeight: [BodyWeightPoint] {
        ProgressViewModel.bodyWeightTrend(measurements)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        metrics
                        volumeTrend
                        bestLiftsSection
                        bodyTrend
                        baselineSection
                        encouragementSection
                    }
                    .padding()
                    .padding(.bottom, CoachLayout.bottomScrollPadding)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coachBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Workouts this week",
                value: "\(ProgressViewModel.weeklyWorkoutCount(sessions))",
                iconName: "calendar"
            )

            MetricCard(
                title: "Best lifts saved",
                value: "\(bestLifts.count)",
                iconName: "trophy"
            )
        }
    }

    private var volumeTrend: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Total Volume")
                    .font(.headline)

                Chart(weeklyVolume) { point in
                    BarMark(
                        x: .value("Week", point.weekStart, unit: .weekOfYear),
                        y: .value("Volume", point.volume)
                    )
                    .foregroundStyle(Color.coachAccent.gradient)
                }
                .frame(height: 180)
                .chartYAxisLabel("lb")
            }
        }
    }

    @ViewBuilder
    private var bestLiftsSection: some View {
        if bestLifts.isEmpty {
            EmptyStateView(
                iconName: "dumbbell",
                title: "No best lifts yet",
                message: "Finish a workout to start building your lift history."
            )
        } else {
            CoachCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Best Lifts")
                        .font(.headline)

                    ForEach(bestLifts) { lift in
                        HStack {
                            Text(lift.exerciseName)
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                                Text("\(lift.weight.formatted(.number.precision(.fractionLength(0...1)))) lb")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.coachSecondaryText)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var bodyTrend: some View {
        if bodyWeight.count >= 2 {
            CoachCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Body Weight")
                        .font(.headline)

                    Chart(bodyWeight) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color.coachAccent)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color.coachAccent)
                    }
                    .frame(height: 180)
                    .chartYAxisLabel("lb")
                }
            }
        }
    }

    private var baselineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strength Baselines")
                .font(.headline)

            ForEach(StrengthBaselineLibrary.keyExerciseNames, id: \.self) { exerciseName in
                let summary = StrengthBaselineLibrary.summary(for: exerciseName, tests: baselineTests)

                NavigationLink {
                    BaselineTestView(exerciseName: exerciseName)
                } label: {
                    BaselineSummaryRow(summary: summary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var encouragementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coach Notes")
                .font(.headline)

            ForEach(ProgressViewModel.encouragementCards(sessions: sessions, measurements: measurements), id: \.self) { card in
                CoachCard {
                    Label(card, systemImage: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct BaselineSummaryRow: View {
    var summary: StrengthBaselineSummary

    var body: some View {
        CoachCard {
            HStack(spacing: 14) {
                Image(systemName: "gauge.with.dots.needle.50percent")
                    .font(.title3)
                    .foregroundStyle(Color.coachAccent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 5) {
                    Text(summary.exerciseName)
                        .font(.subheadline.weight(.semibold))

                    Text(detailText)
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    if let percentChange = summary.percentChange {
                        Text("\(percentChange >= 0 ? "+" : "")\(percentChange.formatted(.number.precision(.fractionLength(0))))%")
                            .font(.headline)
                            .foregroundStyle(percentChange >= 0 ? Color.coachAccent : .secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var detailText: String {
        guard let latest = summary.latest else {
            return "No baseline yet"
        }

        let e1RM = "\(latest.estimatedOneRepMax.formatted(.number.precision(.fractionLength(0...1)))) lb e1RM"

        if summary.isRetestDue {
            return "\(e1RM) · Retest ready"
        }

        return "\(e1RM) · Retest \(latest.retestDueDate.formatted(date: .abbreviated, time: .omitted))"
    }
}
