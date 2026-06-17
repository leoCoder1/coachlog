import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecoverySnapshot.date, order: .reverse) private var recoverySnapshots: [RecoverySnapshot]
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var bodyMeasurements: [BodyMeasurement]
    @State private var healthKitManager = HealthKitManager()
    #if DEBUG
    @State private var demoDataStatus: String?
    #endif
    @State private var isShowingMeasurementCheckIn = false
    @State private var isShowingDeleteDataConfirmation = false
    @State private var accountErrorMessage: String?
    @AppStorage(CoachAuthKeys.isSignedIn) private var isSignedIn = false
    @AppStorage(CoachAuthKeys.displayName) private var accountDisplayName = ""
    @AppStorage(CoachAuthKeys.email) private var accountEmail = ""
    @AppStorage(UnitPreferenceKeys.weightUnit) private var weightUnitRaw = WeightUnitPreference.pounds.rawValue
    @AppStorage(UnitPreferenceKeys.lengthUnit) private var lengthUnitRaw = LengthUnitPreference.inches.rawValue
    @AppStorage(HealthKitRecoverySync.autoImportEnabledKey) private var healthKitAutoImportEnabled = false
    @AppStorage(HealthKitRecoverySync.lastAutoImportDateKey) private var lastHealthKitAutoImportTime = 0.0

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        accountSection
                        unitsSection
                        healthKitSection
                        recoverySection
                        measurementsSection
                        #if DEBUG
                        sampleHistorySection
                        #endif
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
            .alert("Delete account data?", isPresented: $isShowingDeleteDataConfirmation) {
                Button("Delete Data", role: .destructive) {
                    deleteAccountData()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes workouts, measurements, recovery snapshots, saved workouts, custom exercises, settings, and the local Apple sign-in record from this device.")
            }
        }
    }

    private var accountSection: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Account", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.headline)

                    Spacer()

                    Text(isSignedIn ? "Apple ID" : "Signed out")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSignedIn ? Color.coachAccent : Color.coachSecondaryText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(accountTitle)
                        .font(.subheadline.weight(.semibold))

                    Text(accountSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if isSignedIn {
                    VStack(spacing: 10) {
                        Button {
                            CoachAuthSession.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(CoachSecondaryButtonStyle())

                        Button(role: .destructive) {
                            isShowingDeleteDataConfirmation = true
                        } label: {
                            Label("Delete Account Data", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(Color(red: 1.000, green: 0.330, blue: 0.310))
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 1.000, green: 0.330, blue: 0.310).opacity(0.10))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(red: 1.000, green: 0.330, blue: 0.310).opacity(0.24), lineWidth: 1)
                        }
                    }

                    if let accountErrorMessage {
                        Text(accountErrorMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.coachWarm)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
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

                Toggle(isOn: $healthKitAutoImportEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Daily auto-import")
                            .font(.subheadline.weight(.semibold))

                        Text(lastHealthKitImportText)
                            .font(.caption)
                            .foregroundStyle(Color.coachSecondaryText)
                    }
                }
                .tint(Color.coachAccent)
                .onChange(of: healthKitAutoImportEnabled) { _, isEnabled in
                    if isEnabled {
                        HealthKitRecoverySync.scheduleBackgroundRefresh()
                    }
                }

                HStack {
                    Button {
                        Task {
                            let authorized = await healthKitManager.requestAuthorization()
                            if authorized {
                                healthKitAutoImportEnabled = true
                                await importHealthKitRecovery()
                                HealthKitRecoverySync.scheduleBackgroundRefresh()
                            }
                        }
                    } label: {
                        Label("Authorize", systemImage: "checkmark.shield")
                    }
                    .buttonStyle(CoachSecondaryButtonStyle())

                    Button {
                        Task {
                            await importHealthKitRecovery(enableDailyImportOnSuccess: true)
                        }
                    } label: {
                        Label("Sync now", systemImage: "arrow.triangle.2.circlepath")
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

                    HStack(spacing: 8) {
                        Text(snapshot.source ?? "Saved")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.coachAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.coachAccent.opacity(0.12), in: Capsule())

                        if let importNote = snapshot.importNote {
                            Text(importNote)
                                .font(.caption)
                                .foregroundStyle(Color.coachSecondaryText)
                                .lineLimit(2)
                        }
                    }

                    HStack {
                        recoveryMetric(
                            "Sleep",
                            snapshot.displaysMetric(.sleep)
                                ? "\(snapshot.sleepHours.formatted(.number.precision(.fractionLength(1)))) hr"
                                : "--",
                            isAvailable: snapshot.displaysMetric(.sleep)
                        )
                        recoveryMetric(
                            "RHR",
                            snapshot.displaysMetric(.restingHeartRate) ? "\(Int(snapshot.restingHeartRate))" : "--",
                            isAvailable: snapshot.displaysMetric(.restingHeartRate)
                        )
                        recoveryMetric(
                            "HRV",
                            snapshot.displaysMetric(.hrv) ? "\(Int(snapshot.hrv))" : "--",
                            isAvailable: snapshot.displaysMetric(.hrv)
                        )
                        recoveryMetric(
                            "Readiness",
                            snapshot.displaysReadiness ? "\(snapshot.readinessScore)" : "--",
                            isAvailable: snapshot.displaysReadiness
                        )
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

    #if DEBUG
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
    #endif

    private var accountTitle: String {
        if !accountDisplayName.isEmpty {
            return accountDisplayName
        }

        return isSignedIn ? "Apple account connected" : "No account connected"
    }

    private var accountSubtitle: String {
        if !accountEmail.isEmpty {
            return accountEmail
        }

        return isSignedIn
            ? "Your workout data currently stays on this device."
            : "Sign in with Apple to use CoachLog."
    }

    private var lastHealthKitImportText: String {
        guard lastHealthKitAutoImportTime > 0 else {
            return "Syncs once per day after HealthKit is connected."
        }

        let date = Date(timeIntervalSince1970: lastHealthKitAutoImportTime)
        return "Last sync \(date.formatted(date: .abbreviated, time: .shortened))"
    }

    private func importHealthKitRecovery(enableDailyImportOnSuccess: Bool = false) async {
        let result = await healthKitManager.importRecoverySnapshot()

        if let snapshot = result.snapshot {
            HealthKitRecoverySync.save(snapshot, in: modelContext)
            if enableDailyImportOnSuccess {
                healthKitAutoImportEnabled = true
                HealthKitRecoverySync.scheduleBackgroundRefresh()
            }
            lastHealthKitAutoImportTime = Date().timeIntervalSince1970
        }
    }

    private func deleteAccountData() {
        do {
            try LocalAccountDataStore.deleteAllUserData(in: modelContext)
            LocalAccountDataStore.clearAccountScopedPreferences()
            healthKitAutoImportEnabled = false
            lastHealthKitAutoImportTime = 0
            weightUnitRaw = WeightUnitPreference.pounds.rawValue
            lengthUnitRaw = LengthUnitPreference.inches.rawValue
            accountErrorMessage = nil
        } catch {
            accountErrorMessage = "Could not delete local account data. Please try again."
        }
    }

    private func recoveryMetric(_ title: String, _ value: String, isAvailable: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isAvailable ? Color.white : Color.coachSecondaryText)

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
