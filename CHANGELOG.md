# Changelog

All notable TestFlight and release-facing changes for AI Coach are tracked here.

Format follows Keep a Changelog conventions, with entries grouped by app version and build number.

## [1.0 (10)] - 2026-06-20

### Changed
- Standardized the user-facing app name to AI Coach across iOS, watchOS, HealthKit permission copy, workout sharing text, settings, progress guidance, and release documentation.
- Kept the existing `com.machvect.CoachLog` bundle identifiers and internal code names unchanged to preserve TestFlight/App Store Connect, HealthKit, deep link, and installed-app update continuity.
- Build number bumped to 10 for the next TestFlight upload.

### Verified
- iOS simulator build passes with the embedded watchOS app.

## [1.0 (9)] - 2026-06-20

### Added
- Premium AI daily advisor now reviews recent workouts, readiness, recovery trends, weekly muscle loads, measurements, and local progression guardrails before suggesting today's training approach.
- AI guidance now returns structured training modes: push, normal, hold, deload, or rest.
- Per-exercise AI advice appears in the Train flow, including capped weight suggestions when recent performance and readiness support a small increase.
- Workout logging pre-fills AI-supported load suggestions only when the local progression engine also allows the increase.
- Firebase `aiCoach` backend now supports the `todayAdvisor` task and structured exercise advice responses.
- Apple Watch companion logging and HealthKit workout sync support are included in the current dev build.
- LLM coaching plan now documents the future 2-week free trial and Pro subscription path.

### Changed
- Build number bumped to 9 for the next TestFlight upload.
- Xcode local userdata folders are ignored to keep release commits clean.

### Verified
- Firebase Functions TypeScript build passes.
- iOS simulator build passes.
- Latest app is installed and launched on the local iPhone 17 Pro simulator.
- Live Firebase `aiCoach` endpoint returned structured Claude guidance for a synthetic today-advisor request.
