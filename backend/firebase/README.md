# CoachLog Firebase Backend

Firebase is the preferred backend for CoachLog because it fits the app's likely next steps: Sign in with Apple via Firebase Auth, App Check, Cloud Functions secrets, Firestore sync, scheduled jobs, and TestFlight-safe server-side LLM calls.

This backend currently exposes:

- `health`: simple health check.
- `aiCoach`: premium AI coaching proxy for the iOS app.

The iOS app sends structured workout, recovery, freshness, progress, and measurement context. The function calls the configured LLM provider and returns:

```json
{
  "message": "Short coaching message",
  "provider": "anthropic",
  "model": "claude-sonnet-4-6",
  "source": "premium"
}
```

If the provider fails, the function returns the app's local fallback message with `source: "fallback"`.

Claude Sonnet is the default provider. The Anthropic request uses an explicit prompt-cache breakpoint on CoachLog's static coaching rubric so repeated requests can reuse the stable prefix. User workout, recovery, and measurement data stays outside that cached block.

## Local Setup

```bash
cd backend/firebase/functions
npm install
npm run build
```

For local emulator testing, create a local env file from the example:

```bash
cp .env.example .env
```

Use the existing repo root `.env` values, but do not commit actual keys.

## Deploy Setup

From `backend/firebase`, connect a Firebase project:

```bash
cp .firebaserc.example .firebaserc
# edit .firebaserc with your real Firebase project id
firebase login
firebase use --add
```

Set secrets:

```bash
firebase functions:secrets:set CHATGPT_API_KEY
firebase functions:secrets:set CLAUDE_API_KEY
firebase functions:secrets:set XAI_API_KEY
```

Set non-secret params during deploy when prompted, or place non-sensitive values in `functions/.env`:

```bash
LLM_PROVIDER=anthropic
OPENAI_MODEL=gpt-5.5
CLAUDE_MODEL=claude-sonnet-4-6
XAI_MODEL=grok-4.3
```

Deploy:

```bash
firebase deploy --only functions
```

## iOS Configuration

In a DEBUG build, open CoachLog Settings > AI Premium and paste the deployed `aiCoach` HTTPS URL.

For production, the next step should be Firebase Auth + App Check enforcement before broad release. Do not expose a public unauthenticated LLM endpoint beyond limited internal testing.
