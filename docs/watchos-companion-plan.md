# CoachLog watchOS companion plan

## Summary

Build a minimal watchOS companion for logging sets during an active iPhone workout, then extend it into the live HealthKit workout surface for heart rate and workout stats. The iPhone remains the source of truth for SwiftData/Firebase persistence, detailed planning, history, AI coaching, HealthKit recovery, and progress views. The Watch starts as a fast gym logging surface and becomes the best path for live heart-rate capture.

Default decisions:
- V1 logs the active iPhone workout only.
- V1 does not start or write Apple Health workout sessions.
- V1.5 adds iPhone post-workout HealthKit writes for completed sessions.
- V2 adds Apple Watch `HKWorkoutSession` live workout tracking for heart rate and active energy.
- Live phone-watch sync uses WatchConnectivity, not Firebase.

## Key changes

- Add a watchOS SwiftUI app target bundled with CoachLog.
- Add a lightweight shared logging contract:
  - `ActiveWorkoutSnapshot`: workout title, exercises, targets, logged set counts, and current inputs.
  - `WatchLogSetCommand`: exercise id/name, weight, reps, RIR, timestamp, and command id.
  - `WatchUndoSetCommand` and optional `WatchFinishWorkoutCommand`.
- Add an iPhone-side `ActiveWorkoutStore`:
  - Stores one in-progress workout draft.
  - Receives logs from both iPhone UI and Watch.
  - De-dupes commands by id.
  - Converts the final draft into existing `WorkoutSession -> CompletedExercise -> WorkoutSet` SwiftData models.
- Update `WorkoutSessionView` to publish the active workout snapshot to the Watch and listen for watch log commands.
- Watch UI:
  - Active workout screen: list exercises with set count and target reps.
  - Exercise logging screen: weight picker, reps picker, RIR picker, "Log Set", and "Undo".
  - Values default to the iPhone/session's latest value for that exercise.
  - No text entry; use wheel/crown-friendly controls and large tap targets.
- Sync behavior:
  - Use `WCSession.sendMessage` when reachable.
  - Fall back to queued `transferUserInfo` when not reachable.
  - Watch shows "Pending sync" if commands are queued.
  - iPhone sends a fresh snapshot back after every accepted command.

## HealthKit and Fitness integration

### V1.5: iPhone saves completed workouts to Apple Health

- Request HealthKit write permissions for:
  - `HKObjectType.workoutType()`
  - Active energy burned, when CoachLog has an estimate.
  - Heart-rate samples only if reliable samples were captured or imported.
- On `Finish Workout`, create an `HKWorkout` from the completed CoachLog session:
  - Workout type: default strength sessions to traditional or functional strength training.
  - Start/end time and duration from the active session.
  - Active energy from CoachLog estimate when available.
  - Metadata for app name and a concise CoachLog summary.
- Keep detailed gym data in CoachLog:
  - Sets, reps, weights, RIR, substitutions, and exercise names remain in SwiftData/Firebase.
  - Apple Health/Fitness should receive the workout-level summary, because HealthKit does not model strength sets/reps/loads as a rich first-class gym log.
- Store the saved `HKWorkout.uuid` against the local workout session to prevent duplicate Health writes.
- Add a Settings control for HealthKit workout writing, separate from recovery import.

### V2: Apple Watch live heart-rate workout mode

- Add a watchOS HealthKit workout path using `HKWorkoutSession` and `HKLiveWorkoutBuilder`.
- Start the HealthKit workout session from the Watch when the user starts logging on Watch.
- Collect live metrics on Watch:
  - Current heart rate.
  - Average heart rate.
  - Active energy.
  - Elapsed time.
- Stream live metrics to the iPhone through WatchConnectivity so the phone workout screen can show heart rate and zones.
- Finish the HealthKit workout from the Watch and save the workout through HealthKit, then send the saved workout summary and HealthKit UUID back to the iPhone.
- Keep the iPhone fallback write path for users who do not use Apple Watch.
- Do not rely on iPhone-only HealthKit reads for live HR. The iPhone can read samples written by another device, but it is not reliable enough for a real-time gym workout UI.

### Data ownership

- CoachLog remains the source of truth for exercise-level logs and coaching analytics.
- HealthKit/Fitness receives completed workout summaries and health metrics.
- Firebase can sync CoachLog logs across devices later, but it should not replace HealthKit for Apple Fitness visibility.

## Test plan

- Build iOS and watchOS schemes for simulator and Release archive.
- Paired simulator tests:
  - Start workout on iPhone, log sets on Watch, verify iPhone UI updates.
  - Log multiple sets for the same exercise; verify Progress/Freshness use saved data after finishing.
  - Undo last set from Watch.
  - Background iPhone, log from Watch, reopen iPhone, verify queued sync.
  - Finish workout on iPhone and confirm Watch clears active workout.
- HealthKit tests:
  - On a real iPhone, finish a workout and verify it appears in Apple Health/Fitness.
  - Confirm duplicate finish/sync does not create duplicate Health workouts.
  - Confirm HealthKit write permission can be declined without breaking CoachLog logging.
  - On Apple Watch, verify live heart rate updates during an active workout.
  - Finish on Watch and confirm the saved workout summary syncs back to iPhone.
- Regression tests:
  - Existing iPhone-only workout logging still works.
  - Existing SwiftData models do not require migration.
  - TestFlight archive includes the Watch app.

## Effort

V1 companion logging estimate: 4-6 focused engineering days.

V1.5 iPhone HealthKit workout writing estimate: 1-2 focused engineering days.

V2 Watch live heart-rate and HealthKit workout session estimate: 5-8 focused engineering days after V1 is stable.

Main risks are active workout reliability across iPhone foreground/background, Watch reachability, duplicate command delivery, HealthKit permission states, and avoiding duplicate saved workouts in Apple Health. Keeping Watch logging and HealthKit workout sessions phased separately lets us ship the simple logging companion first, then add live HR once the Watch workflow is stable.
