import SwiftData
import SwiftUI

struct BaselineTestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StrengthBaselineTest.date, order: .reverse) private var baselineTests: [StrengthBaselineTest]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    let exerciseName: String

    @State private var weight: Double = 0
    @State private var reps: Int = 8
    @State private var didPrepare = false

    private let progressionEngine = ProgressionEngine()

    private var weightOptions: [Double] {
        stride(from: 0.0, through: 400.0, by: 2.5).map { $0 }
    }

    private var repOptions: [Int] {
        Array(1...30)
    }

    private var testsForExercise: [StrengthBaselineTest] {
        baselineTests
            .filter { $0.exerciseName == exerciseName }
            .sorted { $0.date > $1.date }
    }

    private var latestTest: StrengthBaselineTest? {
        testsForExercise.first
    }

    private var estimatedOneRepMax: Double {
        weight * (1 + Double(reps) / 30)
    }

    var body: some View {
        ZStack {
            CoachScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    entryCard
                    historyCard
                }
                .padding()
                .padding(.bottom, CoachLayout.bottomScrollPadding)
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.coachBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            prepareIfNeeded()
        }
    }

    private var header: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Strength Baseline")
                    .font(.headline)

                if let latestTest {
                    Text("Latest: \(latestTest.weight.formattedWeight) lb x \(latestTest.reps) · e1RM \(latestTest.estimatedOneRepMax.formattedWeight) lb")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)

                    Text(latestTest.retestDueDate <= .now ? "Retest ready" : "Retest \(latestTest.retestDueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(latestTest.retestDueDate <= .now ? Color.coachAccent : .secondary)
                } else {
                    Text("Best clean set")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                }
            }
        }
    }

    private var entryCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    WheelDoublePickerButton(
                        title: "Weight",
                        unit: "lb",
                        values: weightOptions,
                        value: $weight
                    )

                    WheelIntPickerButton(
                        title: "Reps",
                        unit: "reps",
                        values: repOptions,
                        value: $reps
                    )
                }

                HStack {
                    Label("Estimated 1RM", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text("\(estimatedOneRepMax.formattedWeight) lb")
                        .font(.headline)
                        .foregroundStyle(Color.coachAccent)
                }

                Button {
                    saveBaseline()
                } label: {
                    Label("Save Baseline", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(CoachPrimaryButtonStyle())
                .disabled(weight <= 0 || reps <= 0)
            }
        }
    }

    @ViewBuilder
    private var historyCard: some View {
        if !testsForExercise.isEmpty {
            CoachCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("History")
                        .font(.headline)

                    ForEach(testsForExercise.prefix(5)) { test in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(test.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.weight(.semibold))

                                Text("\(test.weight.formattedWeight) lb x \(test.reps)")
                                    .font(.caption)
                                    .foregroundStyle(Color.coachSecondaryText)
                            }

                            Spacer()

                            Text("\(test.estimatedOneRepMax.formattedWeight) lb")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.coachAccent)
                        }
                    }
                }
            }
        }
    }

    private func prepareIfNeeded() {
        guard !didPrepare else { return }
        didPrepare = true

        if let latestTest {
            weight = nearestWeightOption(to: latestTest.weight)
            reps = latestTest.reps
            return
        }

        if let lastWeight = progressionEngine.lastWeight(for: exerciseName, in: sessions) {
            weight = nearestWeightOption(to: lastWeight)
        }
    }

    private func saveBaseline() {
        let baseline = StrengthBaselineTest(
            exerciseName: exerciseName,
            weight: weight,
            reps: reps
        )
        modelContext.insert(baseline)
        try? modelContext.save()
        dismiss()
    }

    private func nearestWeightOption(to value: Double) -> Double {
        let clamped = min(400, max(0, value))
        return (clamped / 2.5).rounded() * 2.5
    }
}

private extension Double {
    var formattedWeight: String {
        formatted(.number.precision(.fractionLength(0...1)))
    }
}
