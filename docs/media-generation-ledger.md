# Media Generation Ledger

This file tracks AI-generated exercise media for CoachLog. Entries before this file existed are reconstructed from local artifacts and are not billing-verified. Use the xAI console invoice as the source of truth for exact spend.

Pricing basis checked on 2026-06-18:
- xAI pricing docs list `grok-imagine-image` at $0.02 per image output and `grok-imagine-image-quality` at $0.01 per input image plus $0.05 per 1K output image.
- xAI pricing docs list `grok-imagine-video` at $0.002 per image input and $0.07/sec for 720p output. They list `grok-imagine-video-1.5` at $0.01 per image input and $0.14/sec for 720p output.
- Source: https://docs.x.ai/developers/pricing
- OpenAI image generation docs list `gpt-image-1.5` 1024x1024 high output at $0.133 per image; edit requests also include input text/image tokens.
- Source: https://developers.openai.com/api/docs/guides/image-generation

## Running Estimate

| Date | Provider / model | Assets | Count | Basis | Estimated cost |
| --- | --- | --- | ---: | --- | ---: |
| 2026-06-17 | xAI Grok Imagine video, exact model not recorded | Glute bridge, dumbbell hip thrust, cable glute kickback, side-lying hip abduction, figure-four glute stretch, Romanian deadlift, dumbbell reverse lunge, step-up, world's greatest stretch, plus retries for hip thrust, cable kickback, Romanian deadlift, step-up | 15 successful 720p videos, 10.041667s each | Reconstructed from `/tmp/coachlog-grok-videos` manifests. Baseline: `grok-imagine-video` 720p at $0.07/sec plus $0.002 image input/request. If these were billed as `grok-imagine-video-1.5`, the estimate is about $21.24 instead. | ~$10.57 baseline |
| 2026-06-17 | xAI Grok Imagine image, exact model not recorded | Hip thrust start still candidates | 6 images | Reconstructed from `/tmp/coachlog-grok-videos/hip-thrust-stills*`. Estimate range is $0.02/image standard to $0.05/image quality. | ~$0.12-$0.30 |
| 2026-06-18 | xAI Grok Imagine image edit | Replacement dumbbell hip thrust start still attempt | 1 blocked request | API returned `permission-denied`: team has used all available credits or hit the monthly spending limit. No media generated. Treat as $0 unless the console shows otherwise. | $0.00 |
| 2026-06-18 | Local reuse / transcode | Dumbbell hip thrust replacement clip | 1 existing video reused | Reused prior local `/tmp/coachlog-grok-videos/v2/exercise-dumbbell-hip-thrust.mp4`; transcoded muted app-ready MP4 and refreshed thumbnail. No new paid generation. | $0.00 |
| 2026-06-18 | OpenAI `gpt-image-1.5` image edit | App icon concept options: dumbbell curl, goblet squat, shoulder press, training pose | 4 successful 1024x1024 high edits, 1 safety-blocked attempt | Outputs in `output/imagegen/app-icon-options/`. Estimate includes output image price only: 4 x $0.133. OpenAI bills edit input text/image tokens separately, so exact total must be checked in the OpenAI usage dashboard. | At least ~$0.53 + input tokens |
| 2026-06-18 | xAI Grok Imagine video | Figure Four Glute Stretch overhead-angle replacement attempt | 1 rejected request | API returned `invalid-argument`: incorrect API key provided. No media generated. | $0.00 |
| 2026-06-18 | xAI `grok-imagine-video` | Figure Four Glute Stretch replacement: overhead/head-end camera attempts | 3 successful 720p videos, 8s each | Generated candidates `ffdbb60e-47bd-99d3-9953-7e593d2c6c64`, `3f2f45f4-8ee1-9d7b-ba18-91f8c23eba59`, and `0e5e45e4-fae2-9513-ada0-91aa1d7be280`. Selected v3 and shipped it as `exercise-figure-four-glute-stretch.mp4`. Estimate: 3 x (8s x $0.07/sec + $0.002 image input). | ~$1.69 |
| 2026-06-18 | xAI `grok-imagine-video` | Figure Four Glute Stretch side-angle modified stretch replacement | 1 successful 720p video, 8s raw, trimmed to 6s for app | Generated candidate `0e1f1533-8e0e-98cd-9c3e-ac2ffcbf538e` using the model reference plus the user-provided side-angle pose reference. Shipped the clean first 6s segment as `exercise-figure-four-glute-stretch.mp4`. Estimate: 8s x $0.07/sec plus two image inputs at $0.002 each. | ~$0.56 |
| 2026-06-18 | xAI `grok-imagine-video` | Figure Four Glute Stretch clearer side-angle setup-to-stretch replacement | 1 successful 720p video, 8s raw, shipped to app | Generated candidate `ed5edee2-4f48-9e3f-93b7-12495e09e8d0` using the model reference plus the user-provided side-angle pose reference. xAI API returned `cost_in_usd_ticks: 5640000000`; treating ticks as 1e10 per USD gives $0.564. Shipped as `exercise-figure-four-glute-stretch.mp4` and refreshed the thumbnail. | ~$0.56 |
| 2026-06-18 | Local app cleanup | Removed Figure Four Glute Stretch video from the app bundle | 1 video removed | Kept the exercise, instruction guidance, and image/muscle-map behavior. Removed only the MP4 resource hookup because generated videos were not clear enough. | $0.00 |

Current billing-unverified reconstructed total: about **$14.03-$14.21 baseline**, plus OpenAI edit input-token charges not reflected here. If the original 2026-06-17 successful video jobs were billed as `grok-imagine-video-1.5`, the estimate is about **$24.70-$24.88**, plus OpenAI edit input-token charges.

## Notes

- Exact historical model IDs were not saved in the old manifests, so the video estimate is a range.
- The earlier 2026-06-18 xAI spend-limit error was resolved after updating `XAI_API_KEY` in `.env`; later video requests completed successfully.
- For future work, add a row before or immediately after each paid generation batch with request IDs, model, duration, resolution, count, and whether the output shipped in the app.
