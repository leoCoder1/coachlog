import SwiftUI

@main
struct CoachLogWatchApp: App {
    @StateObject private var workoutStore = WatchWorkoutSessionStore()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(workoutStore)
        }
    }
}
