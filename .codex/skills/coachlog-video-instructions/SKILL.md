---
name: coachlog-video-instructions
description: Generate, review, and wire CoachLog exercise instruction videos. Use when the user asks to create or replace CoachLog exercise/movement videos, add video instructions to popular weekly-plan or Sports movements, use xAI/Grok exercise media generation, review whether generated exercise form looks correct, track generation cost, or decide to keep thumbnail-only media when generated video is confusing or unsafe.
---

# CoachLog Video Instructions

## Core Rule

Only ship a generated video when it clearly demonstrates the exercise with natural movement and correct form. If the video is confusing, unsafe, distorted, starts mid-rep, uses extra people, has warped equipment/limbs, or does not represent the named movement, leave that exercise thumbnail-only and keep the instruction/detail view intact.

## Workflow

1. Work from latest `origin/dev` in an isolated worktree or branch. Do not mutate a dirty shared checkout.
2. Identify candidates from the app itself, not only the library list:
   - Weekly plan builder: `CoachLog/Views/SavedWorkoutsView.swift`
   - Today generator: `CoachLog/Engines/WorkoutGenerator.swift`
   - Sports routines: `CoachLog/Support/SportsTrainingLibrary.swift`
   - Media map: `CoachLog/Views/ExerciseVisuals.swift`
3. Prefer missing videos for movements the app suggests often. As of June 2026, high-priority missing weekly-plan videos are `Push-ups`, `Seated Row`, `Dumbbell Lateral Raise`, `Dumbbell Bench Press`, `Leg Press`, `Cable Curl`, `Dead Bug`, and `Assisted Pull-up`.
4. Confirm the user has approved paid generation for the batch. Use `XAI_API_KEY` from `.env`; do not print secrets.
5. Use existing app stills from `CoachLog/Assets.xcassets/exercise-*.imageset/image.jpeg` plus the model reference photos already used in this project (`/Users/S/Downloads/model_1.jpg` through `model_4.jpg`) when available.
6. Generate candidates with `scripts/generate_xai_exercise_videos.mjs` into an output folder under `/private/tmp` or `output/imagegen/...`.
7. Create a review contact sheet with `scripts/make_video_review_sheet.sh` for every candidate. Visually inspect the MP4 and contact sheet before wiring anything.
8. Normalize accepted clips to the app’s existing format: muted H.264 MP4, square 480x480, 24 fps, roughly 8 seconds.
9. Wire only accepted MP4s:
   - Add files under `CoachLog/Resources/ExerciseMedia/`.
   - Add Xcode project file references/build resources if the project does not auto-include them.
   - Set `videoResourceName` in `CoachLog/Views/ExerciseVisuals.swift`.
10. Do not wire rejected clips. Leave `videoResourceName: nil`; the existing thumbnail and instructions remain the fallback.
11. Update `docs/media-generation-ledger.md` immediately with model, request IDs, count, duration, usage cost ticks, selected/rejected status, and estimated USD.
12. Build and run at least a simulator smoke test before committing. If the simulator is in use by another agent, build first and coordinate before UI testing.

## Prompt Pattern

Use a specific movement prompt, not a generic template. Preserve the model/outfit/gym from the references.

```text
Create an 8 second muted seamless looping instructional fitness video using the uploaded exercise still/reference image and uploaded AI-generated model reference photo.

One adult athletic fitness model performs one complete correct repetition of [EXERCISE].

First frame must be the exact starting position: [exercise-specific start]. Movement sequence: [controlled full-range movement with key form constraints]. Finish by returning to the exact starting position for a smooth loop.

Fixed camera, full body visible, no cuts, no zoom. Preserve a consistent single model, outfit, gym, lighting, camera angle, and equipment throughout. No text, no logos, no watermark, no extra people, no distorted hands, no exaggerated proportions, no unsafe posture.
```

For stretches or drills, define the full sequence and whether it is a hold, dynamic flow, or one side only. If a movement cannot be represented clearly in video after reasonable retries, stop and keep thumbnail-only.

## QA Checklist

Accept only if all are true:

- The first frame is the correct start position.
- The clip shows one clear rep or one clear stretch/drill cycle.
- The end frame returns naturally to the start for looping.
- Form is safe: neutral joints, stable torso, correct equipment path, no collapsed knees/back/shoulders.
- The named movement is recognizable without text.
- One model only; no changing face/body/outfit.
- No distorted limbs, extra limbs, floating equipment, or impossible anatomy.
- Full body/equipment is visible enough to teach the movement.
- MP4 is muted and app-ready.

Reject and do not wire if any of these fail.

## Useful Commands

Generate a batch from a JSON job file:

```bash
node ~/.codex/skills/coachlog-video-instructions/scripts/generate_xai_exercise_videos.mjs \
  --repo /path/to/coach-log \
  --jobs /path/to/jobs.json \
  --out /private/tmp/coachlog-xai-videos
```

Make a frame sheet:

```bash
~/.codex/skills/coachlog-video-instructions/scripts/make_video_review_sheet.sh \
  /private/tmp/coachlog-xai-videos/app-ready/exercise-push-ups.mp4 \
  /private/tmp/coachlog-xai-videos/review/exercise-push-ups-sheet.jpg
```

Validate app resource availability:

```bash
find CoachLog/Resources/ExerciseMedia -maxdepth 1 -name 'exercise-*.mp4' -print | sort
rg -n 'videoResourceName: "(exercise-[^"]+)"|videoResourceName: nil' CoachLog/Views/ExerciseVisuals.swift
```

## Job JSON Format

```json
[
  {
    "exercise": "Push-ups",
    "slug": "exercise-push-ups",
    "sourceImage": "CoachLog/Assets.xcassets/exercise-push-ups.imageset/image.jpeg",
    "modelImage": "/Users/S/Downloads/model_1.jpg",
    "prompt": "Create an 8 second muted seamless looping instructional fitness video..."
  }
]
```

Use `sourceImage` for the app still and `modelImage` for the preferred model. If xAI rejects multiple image inputs, retry with only `sourceImage` and explicitly describe the model/outfit in the prompt.
