import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecoverySnapshot.date, order: .reverse) private var recoverySnapshots: [RecoverySnapshot]
    @State private var healthKitManager = HealthKitManager()
    @State private var measurementWeight: Double = 180
    @State private var measurementWaist: Double = 34
    @State private var measurementChest: Double = 40
    @State private var measurementArm: Double = 14
    @State private var measurementThigh: Double = 22

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        healthKitSection
                        recoverySection
                        measurementsSection
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
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Body Measurements")
                    .font(.headline)

                measurementStepper("Weight", value: $measurementWeight, range: 80...400, unit: "lb")
                measurementStepper("Waist", value: $measurementWaist, range: 20...80, unit: "in")
                measurementStepper("Chest", value: $measurementChest, range: 20...80, unit: "in")
                measurementStepper("Arm", value: $measurementArm, range: 8...30, unit: "in")
                measurementStepper("Thigh", value: $measurementThigh, range: 12...40, unit: "in")

                HStack {
                    Button {
                        Task {
                            if let weight = await healthKitManager.latestBodyWeight() {
                                measurementWeight = weight
                            }
                        }
                    } label: {
                        Label("Use Health Weight", systemImage: "scalemass")
                    }
                    .buttonStyle(CoachSecondaryButtonStyle())

                    Button {
                        saveMeasurement()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .buttonStyle(CoachPrimaryButtonStyle())
                }
            }
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

    private func measurementStepper(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String
    ) -> some View {
        Stepper(
            value: value,
            in: range,
            step: title == "Weight" ? 0.5 : 0.25
        ) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue.formatted(.number.precision(.fractionLength(1)))) \(unit)")
                    .foregroundStyle(Color.coachSecondaryText)
            }
        }
    }

    private func saveMeasurement() {
        let measurement = BodyMeasurement(
            weight: measurementWeight,
            waist: measurementWaist,
            chest: measurementChest,
            arm: measurementArm,
            thigh: measurementThigh
        )
        modelContext.insert(measurement)
        try? modelContext.save()
    }
}
