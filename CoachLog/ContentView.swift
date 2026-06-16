import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var didSeed = false
    @State private var selectedTab: CoachTab = .coach

    var body: some View {
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
        .task {
            guard !didSeed else { return }
            didSeed = true
            DataSeeder.seedExercisesIfNeeded(in: modelContext)
        }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch selectedTab {
        case .coach:
            TodayCoachView()
        case .freshness:
            MuscleFreshnessDashboardView()
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
    case progress = "Progress"
    case settings = "Settings"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .coach: "sparkles"
        case .freshness: "figure.strengthtraining.traditional"
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
