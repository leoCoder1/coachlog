import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var didSeed = false
    @State private var didValidateAppleCredential = false
    @State private var healthKitManager = HealthKitManager()
    @State private var selectedTab: CoachTab = .coach
    @AppStorage(CoachAuthKeys.isSignedIn) private var isSignedIn = false
    @AppStorage(CoachAuthKeys.appleUserID) private var appleUserID = ""
    @AppStorage(HealthKitRecoverySync.autoImportEnabledKey) private var healthKitAutoImportEnabled = false
    @AppStorage(HealthKitRecoverySync.lastAutoImportDateKey) private var lastHealthKitAutoImportTime = 0.0

    var body: some View {
        Group {
            if isSignedIn {
                mainAppView
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                SignInView()
                    .transition(.opacity)
            }
        }
        .animation(CoachMotion.screen, value: isSignedIn)
        .task(id: isSignedIn) {
            guard isSignedIn else {
                didSeed = false
                didValidateAppleCredential = false
                return
            }

            await validateAppleCredentialIfNeeded()
            guard isSignedIn else { return }

            if !didSeed {
                didSeed = true
                DataSeeder.seedExercisesIfNeeded(in: modelContext)
            }

            await autoImportHealthKitRecoveryIfNeeded()

            if healthKitAutoImportEnabled {
                HealthKitRecoverySync.scheduleBackgroundRefresh()
            }
        }
    }

    private var mainAppView: some View {
        ZStack(alignment: .bottom) {
            CoachScreenBackground()

            selectedScreen
                .id(selectedTab)
                .transition(CoachMotion.screenTransition)

            CoachTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 18)
                .padding(.bottom, 10)
        }
        .animation(CoachMotion.screen, value: selectedTab)
        .tint(Color.coachAccent)
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
    }

    private func validateAppleCredentialIfNeeded() async {
        guard !didValidateAppleCredential, !appleUserID.isEmpty else {
            return
        }

        didValidateAppleCredential = true
        let state = await CoachAuthSession.credentialState(for: appleUserID)

        if state == .revoked || state == .notFound {
            CoachAuthSession.signOut()
        }
    }

    private func autoImportHealthKitRecoveryIfNeeded() async {
        guard healthKitAutoImportEnabled, healthKitManager.isHealthDataAvailable else {
            return
        }

        let lastImportDate = lastHealthKitAutoImportTime > 0
            ? Date(timeIntervalSince1970: lastHealthKitAutoImportTime)
            : nil

        guard HealthKitRecoverySync.shouldAutoImport(lastImportDate: lastImportDate) else {
            return
        }

        let result = await healthKitManager.importRecoverySnapshot()
        guard let snapshot = result.snapshot else {
            return
        }

        HealthKitRecoverySync.save(snapshot, in: modelContext)
        lastHealthKitAutoImportTime = Date().timeIntervalSince1970
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch selectedTab {
        case .coach:
            TodayCoachView()
        case .freshness:
            MuscleFreshnessDashboardView()
        case .library:
            ExerciseLibraryView()
        case .progress:
            ProgressScreen()
        case .settings:
            SettingsView()
        }
    }
}

private enum CoachTab: String, CaseIterable, Identifiable {
    case coach = "Coach"
    case freshness = "Freshness"
    case library = "Library"
    case progress = "Progress"
    case settings = "Settings"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .coach: "sparkles"
        case .freshness: "figure.strengthtraining.traditional"
        case .library: "list.bullet.rectangle"
        case .progress: "chart.xyaxis.line"
        case .settings: "gearshape"
        }
    }
}

private struct CoachTabBar: View {
    @Binding var selectedTab: CoachTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(CoachTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .symbolEffect(.bounce, value: selectedTab == tab)

                        Text(tab.rawValue)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.coachAccent : Color.coachSecondaryText)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color.coachAccent.opacity(0.14))
                                .transition(.scale(scale: 0.82).combined(with: .opacity))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue)
            }
        }
        .padding(6)
        .background {
            Capsule()
                .fill(Color.coachSurface.opacity(0.94))
                .shadow(color: .black.opacity(0.36), radius: 20, x: 0, y: 12)
        }
        .overlay {
            Capsule()
                .stroke(Color.coachBorder, lineWidth: 1)
        }
    }
}
