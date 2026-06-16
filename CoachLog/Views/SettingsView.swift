import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecoverySnapshot.date, order: .reverse) private var recoverySnapshots: [RecoverySnapshot]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var bodyMeasurements: [BodyMeasurement]
    @State private var healthKitManager = HealthKitManager()
    @State private var demoDataStatus: String?
    @State private var isShowingMeasurementCheckIn = false
    @AppStorage(UnitPreferenceKeys.weightUnit) private var weightUnitRaw = WeightUnitPreference.pounds.rawValue
    @AppStorage(UnitPreferenceKeys.lengthUnit) private var lengthUnitRaw = LengthUnitPreference.inches.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        unitsSection
                        healthKitSection
                        recoverySection
                        measurementsSection
                        sampleHistorySection
                        disclaimerSection
                    }
                    .padding()
                    .padding(.bottom, CoachLayout.bottomScrollPadding)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coachBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $isShowingMeasurementCheckIn) {
                BodyMeasurementCheckInView(latestMeasurement: bodyMeasurements.first)
            }
        }
    }

    private var unitsSection: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Units", systemImage: "ruler")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    unitPicker(
                        title: "Weight",
                        selection: $weightUnitRaw,
                        options: WeightUnitPreference.allCases.map { ($0.rawValue, $0.displayName, $0.unitLabel) }
                    )

                    unitPicker(
                        title: "Measurements",
                        selection: $lengthUnitRaw,
                        options: LengthUnitPreference.allCases.map { ($0.rawValue, $0.displayName, $0.unitLabel) }
                    )
                }

                Text("Existing logs stay unchanged; CoachLog only converts the values you see and enter.")
                    .font(.caption)
                    .foregroundStyle(Color.coachSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var healthKitSection: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("HealthKit", systemImage: "heart")
                        .font(.headline)

                    Spacer()

                    Text(healthKitManager.authorizationStatusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.coachSecondaryText)
                }

                Text(healthKitManager.lastImportMessage)
                    .font(.subheadline)
                    .foregroundStyle(Color.coachSecondaryText)

                HStack {
                    Button {
                        Task {
                            _ = await healthKitManager.requestAuthorization()
                        }
                    } label: {
                        Label("Authorize", systemImage: "checkmark.shield")
                    }
                    .buttonStyle(CoachSecondaryButtonStyle())

                    Button {
                        Task {
                            let snapshot = await healthKitManager.importRecoverySnapshot()
                            modelContext.insert(snapshot)
                            try? modelContext.save()
                        }
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(CoachPrimaryButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var recoverySection: some View {
        if let snapshot = recoverySnapshots.first {
            CoachCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Latest Recovery")
                        .font(.headline)

                    HStack {
                        recoveryMetric("Sleep", "\(snapshot.sleepHours.formatted(.number.precision(.fractionLength(1)))) hr")
                        recoveryMetric("RHR", "\(Int(snapshot.restingHeartRate))")
                        recoveryMetric("HRV", "\(Int(snapshot.hrv))")
                        recoveryMetric("Readiness", "\(snapshot.readinessScore)")
                    }
                }
            }
        }
    }

    private var measurementsSection: some View {
        BodyMeasurementReminderCard(measurements: bodyMeasurements) {
            isShowingMeasurementCheckIn = true
        }
    }

    private var disclaimerSection: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Safety", systemImage: "exclamationmark.triangle")
                    .font(.headline)

                Text("This app is for general fitness guidance only and is not medical advice. Stop if you feel sharp pain, dizziness, or unusual discomfort.")
                    .font(.subheadline)
                    .foregroundStyle(Color.coachSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var sampleHistorySection: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Sample History", systemImage: "chart.bar.doc.horizontal")
                        .font(.headline)

                    Spacer()
                }

                Button {
                    let didLoad = DataSeeder.seedDemoHistoryIfNeeded(in: modelContext)

                    withAnimation(CoachMotion.content) {
                        demoDataStatus = didLoad ? "Sample history loaded" : "Sample history already loaded"
                    }
                } label: {
                    Label("Load Sample History", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(CoachSecondaryButtonStyle())

                if let demoDataStatus {
                    Text(demoDataStatus)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.coachSecondaryText)
                        .transition(CoachMotion.cardTransition)
                }
            }
        }
    }

    private func recoveryMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.coachSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func unitPicker(
        title: String,
        selection: Binding<String>,
        options: [(rawValue: String, displayName: String, unitLabel: String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.coachSecondaryText)

            Picker(title, selection: selection) {
                ForEach(options, id: \.rawValue) { option in
                    Text("\(option.displayName) (\(option.unitLabel))")
                        .tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }

}
