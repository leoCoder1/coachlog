# AI Coach LLM coaching plan

## Goal

Make the premium coach feel like a personal trainer who has reviewed the user's recent training, readiness, recovery, and body trends before advising today's workout.

The coach should answer:
- Should the user train today, reduce volume, hold steady, or push harder?
- Which muscle groups and exercises make sense based on recent work?
- Which lifts can safely increase weight?
- What should change if readiness, sleep, HRV, pain, or muscle freshness is poor?
- How can the user get back on track after missing training?

## Current state

- Firebase `aiCoach` backend exists and proxies requests to the configured LLM provider.
- Claude Sonnet is the default provider.
- Claude prompt caching is enabled for the static coaching rubric.
- The iOS app has an AI Premium toggle and backend endpoint setting.
- Today workout generation already uses local signals:
  - latest recovery/readiness
  - selected energy, pain, time, and goal
  - recent sessions for muscle freshness and weekly load
- Progression logic already identifies increase, hold, and deload cases from reps, RIR, pain, and performance drops.

## Main gap

Today's LLM coaching call does not yet receive enough recent history. It currently sends the generated plan, latest recovery, and muscle freshness, but not the last few weeks of workout logs, per-exercise progression recommendations, or recent measurement trends.

## V1: Today advisor context

Add a compact `TodayAdvisorContext` payload from the iOS app to the backend.

Include:
- Last 3-6 weeks of workout sessions.
- Last performed date for each planned exercise.
- Last weight, reps, set count, and RIR for each planned exercise.
- Progression recommendation for each planned exercise.
- Current week muscle-group set counts.
- Muscle freshness statuses.
- Latest recovery snapshot and recent recovery trend when available.
- Recent body measurement trend when available.
- User-selected time, energy, pain, and goal.

Keep the payload summarized. The backend should not need raw lifetime history for a single coaching message.

## V1 output shape

Return structured JSON instead of only a paragraph:

```json
{
  "trainingMode": "push|normal|hold|deload|rest",
  "message": "Short coach message",
  "exerciseAdvice": [
    {
      "exerciseName": "Dumbbell Bench Press",
      "action": "increase|hold|reduce|substitute",
      "suggestedWeight": 55,
      "reason": "Clean reps last time and readiness is high."
    }
  ]
}
```

The app can still display one polished paragraph, but structured fields let the workout screen prefill smarter weights and show simple action chips.

## Access model

For TestFlight and early beta, keep AI guidance easy to test.

Production plan:
- Give every new user 2 free weeks of LLM-generated guidance.
- After the trial, keep local rule-based coaching free.
- Ask users to subscribe to Pro to keep premium LLM guidance, personalized notifications, deeper progress summaries, and AI substitutions.
- The app should fail gracefully if the subscription expires: keep workout logging, saved plans, HealthKit sync, and local progression suggestions available.
- Keep subscription checks on the server before broad release so paid LLM calls are not controlled only by a client-side toggle.

## Load progression rules

- Push/increase only when readiness is good, pain is absent, target reps were completed, and RIR suggests the last load was not near max.
- Use small jumps:
  - upper body: usually 2.5-5%
  - lower body/glutes: usually 5-10%
- Hold when sleep/readiness is low, RIR was 0-1, reps dropped sharply, or the same muscle group is still recovering.
- Deload when multiple recent sessions show declining volume or performance.
- If the LLM and local progression engine disagree, the conservative recommendation wins.

## Missed-training nudges

Add a lightweight notification system to nudge users when they have not logged training for more than 2 days.

Rules:
- Only nudge if notifications are enabled by the user.
- Trigger after 2 full days without a completed workout.
- Do not send more than one missed-training nudge per day.
- Do not send more than 1-2 total training-related notifications per day across all notification types.
- Quiet hours should be respected.
- Avoid guilt or pressure language.
- Use the user's real progress when available.

Examples:
- "You were building a strong rhythm last week. A short 25-minute session today keeps the streak alive."
- "Two days off is fine. Start with one clean set and let momentum do the rest."
- "Your last sessions were trending well. Today does not need to be perfect, just logged."
- "Readiness looks solid. This is a good day to get back under the weights."

Premium LLM version:
- Generate a more personal notification using recent consistency, last workout, readiness, and measurement wins.
- Keep notifications short and plain.
- Never shame the user.
- If readiness is poor, suggest a lighter session, mobility, or rest rather than pushing.

Local fallback version:
- Use templated notifications based on days since last workout, readiness, and weekly count.

## Notification implementation plan

1. Add notification permission onboarding in Settings.
2. Store notification preferences:
   - enabled
   - preferred time window
   - quiet hours
   - last nudge date
   - daily notification count
   - last notification timestamps by category
3. Add a notification budget guard:
   - default max: 1 training notification/day
   - hard max: 2 training notifications/day
   - missed-training nudges count toward the same daily cap as readiness, measurement, and workout reminders
   - never schedule two notifications within the same short window
4. Recompute nudge eligibility when:
   - app opens
   - workout finishes
   - daily background refresh runs
5. Prioritize notifications when more than one is eligible:
   - critical: HealthKit permission or sync problem only when user explicitly enabled sync
   - high: missed-training nudge after 2+ days
   - medium: readiness-based training suggestion
   - low: body measurement check-in
6. Schedule local notifications with `UNUserNotificationCenter`.
7. For premium users, optionally call the backend to generate the next nudge copy.
8. Cancel pending missed-training nudges immediately after the user logs a workout.

## UX placement

- Settings: "Training nudges" toggle under AI Premium or Notifications.
- Train tab: small card when the user is overdue, with "Start short workout" and "Not today".
- Notification tap should open the Train tab and suggest a short session.

## Testing

- Unit-test eligibility:
  - no workouts yet
  - last workout 1 day ago
  - last workout 3 days ago
  - notification already sent today
  - poor readiness
  - workout logged after nudge was scheduled
- Simulator-test permission and scheduling flow.
- Real-device test notification delivery timing.
- Backend-test premium nudge generation with sample workout history and readiness.

## Production safeguards

- Keep health/training claims modest.
- Do not promise results.
- Do not pressure users to train through pain or poor recovery.
- Cap LLM nudge generation to avoid background cost spikes.
- Use local fallback if the backend is unavailable.
