import SwiftData
import SwiftUI

struct SharedWorkoutImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.updatedAt, order: .reverse) private var templates: [WorkoutTemplate]
    @AppStorage(CoachAuthKeys.isSignedIn) private var isSignedIn = false

    var workout: SharedWorkoutPayload
    var onAdd: () -> Void = {}

    @State private var saveError: String?

    private var existingNames: Set<String> {
        Set(templates.map(\.name))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerCard
                        movementCard

                        if !isSignedIn {
                            signInCard
                        }

                        actionButtons
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Shared Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        dismiss()
                    }
                }
            }
            .alert("Workout could not be added", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    private var headerCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(CoachGradient.accentSoft)
                            .frame(width: 46, height: 46)

                        Image(systemName: "square.and.arrow.down")
                            .font(.headline)
                            .foregroundStyle(Color.coachAccent)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(workout.name)
                            .font(.title3.weight(.black))
                            .lineLimit(2)
                            .minimumScaleFactor(0.76)

                        Text("\(workout.scheduleLabel) · \(workout.exerciseCountText) · \(workout.estimatedMinutes) min · \(workout.goal.displayName)")
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                    }
                }

                Text("Preview this shared plan before adding it to your saved workouts.")
                    .font(.subheadline)
                    .foregroundStyle(Color.coachSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var movementCard: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Movements")
                    .font(.headline)

                VStack(spacing: 10) {
                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                        SharedWorkoutMovementRow(index: index + 1, exercise: exercise)
                    }
                }
            }
        }
    }

    private var signInCard: some View {
        CoachCard {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.title3)
                    .foregroundStyle(Color.coachWarm)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign in first")
                        .font(.headline)

                    Text("Add this workout after opening your AI Coach account.")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: addWorkout) {
                Label("Add to My Workouts", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(CoachPrimaryButtonStyle())
            .disabled(!isSignedIn)

            Button {
                dismiss()
            } label: {
                Text("Discard")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(CoachSecondaryButtonStyle())
        }
    }

    private func addWorkout() {
        guard isSignedIn else { return }

        let template = workout.makeTemplate(existingNames: existingNames)
        modelContext.insert(template)

        do {
            try modelContext.save()
            onAdd()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

private struct SharedWorkoutMovementRow: View {
    var index: Int
    var exercise: SharedWorkoutExercisePayload

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.black.opacity(0.88))
                .frame(width: 28, height: 28)
                .background(CoachGradient.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.exerciseName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text("\(max(1, exercise.targetSets)) sets · \(exercise.targetRepRange) reps · \(exercise.station.rawValue)")
                    .font(.caption)
                    .foregroundStyle(Color.coachSecondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.coachSurfaceElevated.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.coachBorder, lineWidth: 1)
        }
    }
}
