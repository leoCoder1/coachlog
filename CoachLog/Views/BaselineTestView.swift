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
    @AppStorage(UnitPreferenceKeys.weightUnit) private var weightUnitRaw = WeightUnitPreference.pounds.rawValue

    private let progressionEngine = ProgressionEngine()

    private var weightUnit: WeightUnitPreference {
        WeightUnitPreference(rawValue: weightUnitRaw) ?? .pounds
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
                    Text("Latest: \(weightUnit.formattedWeight(latestTest.weight)) x \(latestTest.reps) · e1RM \(weightUnit.formattedWeight(latestTest.estimatedOneRepMax))")
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
                    WheelWeightPickerButton(
                        title: "Weight",
                        unit: weightUnit,
                        poundsRange: 0...400,
                        pounds: $weight
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

                    Text(weightUnit.formattedWeight(estimatedOneRepMax))
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

                                Text("\(weightUnit.formattedWeight(test.weight)) x \(test.reps)")
                                    .font(.caption)
                                    .foregroundStyle(Color.coachSecondaryText)
                            }

                            Spacer()

                            Text(weightUnit.formattedWeight(test.estimatedOneRepMax))
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
