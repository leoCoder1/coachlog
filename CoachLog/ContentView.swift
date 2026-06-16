import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var didSeed = false

    var body: some View {
        TabView {
            TodayCoachView()
                .tabItem {
                    Label("Coach", systemImage: "sparkles")
                }

            MuscleFreshnessDashboardView()
                .tabItem {
                    Label("Freshness", systemImage: "figure.strengthtraining.traditional")
                }

            ProgressScreen()
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Color.coachAccent)
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
        .toolbarBackground(Color.coachBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .task {
            guard !didSeed else { return }
            didSeed = true
            DataSeeder.seedExercisesIfNeeded(in: modelContext)
        }
    }
}
