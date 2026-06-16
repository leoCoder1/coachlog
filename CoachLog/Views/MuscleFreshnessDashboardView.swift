import SwiftData
import SwiftUI

struct MuscleFreshnessDashboardView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var selectedPain: PainFlag = .none
    private let engine = MuscleFreshnessEngine()

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CoachCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Pain Flag")
                                    .font(.headline)

                                Picker("Pain", selection: $selectedPain) {
                                    ForEach(PainFlag.allCases) { pain in
                                        Text(pain.displayName).tag(pain)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        LazyVGrid(columns: columns, spacing: 12) {
                            let results = engine.statuses(from: sessions, pain: selectedPain)

                            ForEach(MuscleGroup.dashboardGroups) { group in
                                if let result = results[group] {
                                    FreshnessTile(result: result)
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, CoachLayout.bottomScrollPadding)
                }
            }
            .navigationTitle("Freshness")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coachBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .animation(CoachMotion.content, value: selectedPain)
            .animation(CoachMotion.content, value: sessions.count)
        }
    }
}

private struct FreshnessTile: View {
    var result: MuscleFreshnessResult

    var body: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: result.group.iconName)
                        .foregroundStyle(Color.freshness(result.status))

                    Spacer()

                    StatusBadge(status: result.status)
                }

                Text(result.group.rawValue)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(daysText)
                    .font(.subheadline)
                    .foregroundStyle(Color.coachSecondaryText)

                Text(result.note)
                    .font(.caption)
                    .foregroundStyle(Color.coachSecondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: 136, alignment: .top)
        }
    }

    private var daysText: String {
        if let days = result.daysSinceTraining {
            return days == 0 ? "Trained today" : "\(days) day\(days == 1 ? "" : "s") ago"
        }

        return "No recent log"
    }
}
