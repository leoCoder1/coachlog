# CoachLog watchOS companion plan

## Summary

Build a minimal watchOS companion for logging sets during an active iPhone workout. The iPhone remains the source of truth, owns SwiftData persistence, and handles detailed planning, history, AI coaching, HealthKit recovery, and progress views. The Watch is only a fast gym logging surface.

Default decisions:
- V1 logs the active iPhone workout only.
- V1 does not start or write Apple Health workout sessions.
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

## Test plan

- Build iOS and watchOS schemes for simulator and Release archive.
- Paired simulator tests:
  - Start workout on iPhone, log sets on Watch, verify iPhone UI updates.
  - Log multiple sets for the same exercise; verify Progress/Freshness use saved data after finishing.
  - Undo last set from Watch.
  - Background iPhone, log from Watch, reopen iPhone, verify queued sync.
  - Finish workout on iPhone and confirm Watch clears active workout.
- Regression tests:
  - Existing iPhone-only workout logging still works.
  - Existing SwiftData models do not require migration.
  - TestFlight archive includes the Watch app.

## Effort

MVP estimate: 4-6 focused engineering days.

Main risk is active workout reliability across iPhone foreground/background, Watch reachability, and duplicate command delivery. Keeping the Watch companion-only avoids larger HealthKit workout-session and standalone sync complexity.
