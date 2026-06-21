import { onRequest } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

const chatgptApiKey = defineSecret("CHATGPT_API_KEY");
const claudeApiKey = defineSecret("CLAUDE_API_KEY");
const xaiApiKey = defineSecret("XAI_API_KEY");

const llmProvider = defineString("LLM_PROVIDER", { default: "anthropic" });
const openAIModel = defineString("OPENAI_MODEL", { default: "gpt-5.5" });
const claudeModel = defineString("CLAUDE_MODEL", { default: "claude-sonnet-4-6" });
const xaiModel = defineString("XAI_MODEL", { default: "" });

type AICoachTask = "todayAdvisor" | "workoutExplanation" | "progressSummary" | "nextSessionAdvice";
type LLMProvider = "openai" | "anthropic" | "xai";
type TrainingMode = "push" | "normal" | "hold" | "deload" | "rest";
type ExerciseAction = "increase" | "hold" | "reduce" | "substitute";

interface AICoachRequest {
  task: AICoachTask;
  context?: unknown;
  plan?: unknown;
  freshness?: unknown[];
  weeklyLoads?: unknown[];
  recentSessions?: unknown[];
  recoveryTrend?: unknown[];
  measurements?: unknown[];
  exerciseProgressions?: unknown[];
  progression?: unknown;
  fallbackMessage?: string;
  fallbackGuidance?: unknown;
  provider?: LLMProvider;
}

interface ProviderResult {
  message: string;
  provider: LLMProvider;
  model: string;
}

interface AdvisorExerciseAdvice {
  exerciseName: string;
  action: ExerciseAction;
  suggestedWeightPounds?: number;
  reason: string;
}

interface AdvisorResponse {
  trainingMode: TrainingMode;
  message: string;
  exerciseAdvice: AdvisorExerciseAdvice[];
}

const coachSystemPrompt = [
  "You are AI Coach's premium AI strength coach.",
  "Use only the provided training, recovery, progression, and measurement data.",
  "Return the requested format exactly.",
  "Keep user-facing messages under 90 words. No markdown. No lists.",
  "Be specific about the user's plan or trend, but do not invent data.",
  "If pain is present, recommend conservative loading and substitution.",
  "Do not diagnose medical conditions or claim guaranteed outcomes."
].join(" ");

const claudeCoachReferencePrompt = [
  "AI Coach reusable coaching rubric:",
  "The app is a strength training coach for everyday lifters who want simple, confident decisions in the gym. The output must feel like a capable human coach who has read the user's log, not like a generic chatbot. Use the user's actual exercise names, recent weights, reps, recovery values, freshness states, and body measurements when they are provided. Do not add facts that are not in the request. Do not say you are analyzing data unless you immediately convert that analysis into a useful training decision.",
  "Style rules: write in one short paragraph under 90 words. Use plain language. Use direct, specific action verbs. Avoid hype, medical certainty, moral judgment, and vague reassurance. Avoid markdown, bullets, headings, tables, emojis, disclaimers, and long explanations. Prefer phrasing like 'start with', 'hold', 'reduce', 'substitute', 'aim for', 'keep', and 'stop if'. Mention one or two numbers from the log when they change the decision. If there is no useful data for a claim, say what to do next rather than inventing a trend.",
  "Safety rules: if the request includes pain, discomfort, poor sleep, high resting heart rate, low HRV, low readiness, overloaded muscle freshness, or recent heavy volume, bias toward conservative loading, cleaner technique, smaller range of motion, or a substitution. Do not diagnose injuries. Do not tell the user to push through pain. Do not prescribe rehab. Use language such as 'stay in a pain-free range', 'reduce load', 'skip the painful pattern', or 'choose a similar movement'. If the user has high readiness but a specific joint warning, train the ready muscles while protecting that joint.",
  "Progression rules: when the user completed the top of a rep range with stable form, a small weight increase is reasonable. If reps dropped, form was uncertain, sleep was low, readiness was low, or the same muscle group is in caution, hold the weight or reduce volume. For strength movements, prefer small jumps. For dumbbells and machines, use available increments. If the user's goal is fat loss or body recomposition, connect strength retention, waist or abdomen changes, and consistency without promising outcomes.",
  "Today advisor output rules: for task todayAdvisor, return strict JSON only. Use keys trainingMode, message, and exerciseAdvice. trainingMode must be one of push, normal, hold, deload, rest. exerciseAdvice must be an array of objects with exerciseName, action, suggestedWeightPounds, and reason. action must be increase, hold, reduce, or substitute. Include suggestedWeightPounds only when a specific load is justified by the provided progression data. Never suggest a larger increase than the provided exerciseProgressions suggestedWeightPounds.",
  "Workout explanation rules: explain why today's workout fits the user's available time, goal, readiness, and muscle freshness. Name the main exercises that drive the goal. If a muscle group is in caution, explain the practical adjustment. Keep the message focused on what the user should do today. Do not restate the full plan.",
  "Progress summary rules: compare the latest relevant data to earlier data. Useful patterns include weight moved, reps completed, volume trend, consistency, waist or abdomen trend, sleep, HRV, resting heart rate, and measurement direction. Good changes for many users include waist and abdomen going down while strength, chest, shoulders, arms, glutes, or legs improve. Never imply causation from correlation. End with one next focus.",
  "Next-session advice rules: turn freshness, last session, progression recommendation, recovery, and constraints into a concrete session choice. If equipment is busy, suggest substitutes that train the same primary muscles and match the user's goal. If leg press is busy, options might include hip thrust, Romanian deadlift, goblet squat, split squat, step-up, cable glute kickback, or leg curl depending on pain and muscle freshness. If overhead pressing irritates the shoulder, options might include landmine press, neutral-grip dumbbell press, machine chest press, lateral raise, row variation, or lower load depending on the plan.",
  "Example response for a shoulder-sensitive push day: 'Today still fits your chest and back goal, but keep pressing controlled. Bench at 125 lb can be your main strength work if warm-ups feel clean; with front delts and triceps in caution, avoid chasing extra reps and keep incline dumbbells lighter. If the shoulder complains, swap to a neutral-grip press and put more effort into rows.'",
  "Example response for body-measurement progress: 'Strength and body composition are moving in the right direction: bench is up from 115 to 125 lb while weight, waist, and abdomen are down. That is exactly the trend AI Coach wants to protect. Keep the next push session focused on completing 125 for clean sets before increasing again, and keep weekly training consistent.'",
  "Example response for a lower-body substitution: 'Readiness is high, so train glutes and hamstrings without forcing the knee. Start hip thrusts at 90 lb if warm-ups feel stable, then use lying leg curls and cable glute kickbacks. Since leg press is busy and deep knee bend is uncomfortable, skip deep quad work today and keep every set pain-free.'"
].join("\n\n");

export const health = onRequest(
  {
    region: "us-central1",
    timeoutSeconds: 10,
    memory: "256MiB",
    invoker: "public"
  },
  (_request, response) => {
    response.status(200).json({
      ok: true,
      service: "coachlog-ai",
      time: new Date().toISOString()
    });
  }
);

export const aiCoach = onRequest(
  {
    region: "us-central1",
    timeoutSeconds: 30,
    memory: "256MiB",
    maxInstances: 10,
    invoker: "public",
    secrets: [chatgptApiKey, claudeApiKey, xaiApiKey]
  },
  async (request, response) => {
    response.set("Content-Type", "application/json");

    if (request.method !== "POST") {
      response.status(405).json({ error: "Use POST." });
      return;
    }

    const body = normalizeRequestBody(request.body);
    if (!body) {
      response.status(400).json({ error: "Invalid AI coach request." });
      return;
    }

    try {
      const provider = selectedProvider(body.provider);
      const result = await callProvider(provider, body);
      const advisor = body.task === "todayAdvisor" ? advisorResponseFromLLM(result.message, body) : undefined;

      response.status(200).json({
        message: advisor?.message || sanitizeMessage(result.message),
        trainingMode: advisor?.trainingMode,
        exerciseAdvice: advisor?.exerciseAdvice,
        provider: result.provider,
        model: result.model,
        source: "premium"
      });
    } catch (error) {
      logger.error("AI coach request failed", error);

      response.status(200).json({
        message: sanitizeMessage(
          body.fallbackMessage ||
            "AI Coach could not reach premium AI right now. Use the local plan and keep today conservative."
        ),
        trainingMode: fallbackTrainingMode(body.fallbackGuidance),
        exerciseAdvice: fallbackExerciseAdvice(body.fallbackGuidance),
        source: "fallback"
      });
    }
  }
);

function normalizeRequestBody(body: unknown): AICoachRequest | undefined {
  if (!body || typeof body !== "object") {
    return undefined;
  }

  const candidate = body as Partial<AICoachRequest>;
  if (
    candidate.task !== "todayAdvisor" &&
    candidate.task !== "workoutExplanation" &&
    candidate.task !== "progressSummary" &&
    candidate.task !== "nextSessionAdvice"
  ) {
    return undefined;
  }

  return {
    task: candidate.task,
    context: candidate.context,
    plan: candidate.plan,
    freshness: Array.isArray(candidate.freshness) ? candidate.freshness : [],
    weeklyLoads: Array.isArray(candidate.weeklyLoads) ? candidate.weeklyLoads : [],
    recentSessions: Array.isArray(candidate.recentSessions) ? candidate.recentSessions : [],
    recoveryTrend: Array.isArray(candidate.recoveryTrend) ? candidate.recoveryTrend : [],
    measurements: Array.isArray(candidate.measurements) ? candidate.measurements : [],
    exerciseProgressions: Array.isArray(candidate.exerciseProgressions) ? candidate.exerciseProgressions : [],
    progression: candidate.progression,
    fallbackMessage: typeof candidate.fallbackMessage === "string" ? candidate.fallbackMessage : undefined,
    fallbackGuidance: candidate.fallbackGuidance,
    provider: candidate.provider
  };
}

function selectedProvider(requestedProvider?: LLMProvider): LLMProvider {
  if (requestedProvider) {
    return requestedProvider;
  }

  const configuredProvider = (process.env.LLM_PROVIDER || llmProvider.value()).toLowerCase();
  if (configuredProvider === "anthropic" || configuredProvider === "claude") {
    return "anthropic";
  }

  if (configuredProvider === "xai" || configuredProvider === "grok") {
    return "xai";
  }

  return "openai";
}

async function callProvider(provider: LLMProvider, body: AICoachRequest): Promise<ProviderResult> {
  switch (provider) {
    case "anthropic":
      return callAnthropic(body);
    case "xai":
      return callXAI(body);
    case "openai":
      return callOpenAI(body);
  }
}

async function callOpenAI(body: AICoachRequest): Promise<ProviderResult> {
  const apiKey = secretValue(chatgptApiKey, "CHATGPT_API_KEY") || secretValue(chatgptApiKey, "OPENAI_API_KEY");
  if (!apiKey) {
    throw new Error("CHATGPT_API_KEY or OPENAI_API_KEY is not configured.");
  }

  const model = process.env.OPENAI_MODEL || openAIModel.value();
  const providerResponse = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model,
      reasoning: { effort: "low" },
      text: { verbosity: "low" },
      max_output_tokens: body.task === "todayAdvisor" ? 700 : 320,
      input: [
        {
          role: "system",
          content: coachSystemPrompt
        },
        {
          role: "user",
          content: userPrompt(body)
        }
      ]
    })
  });

  const json = await readProviderJson(providerResponse);
  return {
    message: extractOpenAIMessage(json),
    provider: "openai",
    model
  };
}

async function callAnthropic(body: AICoachRequest): Promise<ProviderResult> {
  const apiKey = secretValue(claudeApiKey, "CLAUDE_API_KEY");
  const model = process.env.CLAUDE_MODEL || claudeModel.value();
  if (!apiKey || !model) {
    throw new Error("CLAUDE_API_KEY and CLAUDE_MODEL must be configured.");
  }

  const providerResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model,
      max_tokens: body.task === "todayAdvisor" ? 700 : 320,
      system: [
        {
          type: "text",
          text: coachSystemPrompt
        },
        {
          type: "text",
          text: claudeCoachReferencePrompt,
          cache_control: { type: "ephemeral" }
        }
      ],
      messages: [
        {
          role: "user",
          content: userPrompt(body)
        }
      ]
    })
  });

  const json = await readProviderJson(providerResponse);
  return {
    message: extractAnthropicMessage(json),
    provider: "anthropic",
    model
  };
}

async function callXAI(body: AICoachRequest): Promise<ProviderResult> {
  const apiKey = secretValue(xaiApiKey, "XAI_API_KEY");
  const model = process.env.XAI_MODEL || xaiModel.value();
  if (!apiKey || !model) {
    throw new Error("XAI_API_KEY and XAI_MODEL must be configured.");
  }

  const providerResponse = await fetch("https://api.x.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model,
      max_tokens: body.task === "todayAdvisor" ? 700 : 320,
      temperature: 0.2,
      messages: [
        {
          role: "system",
          content: coachSystemPrompt
        },
        {
          role: "user",
          content: userPrompt(body)
        }
      ]
    })
  });

  const json = await readProviderJson(providerResponse);
  return {
    message: extractChatCompletionMessage(json),
    provider: "xai",
    model
  };
}

function userPrompt(body: AICoachRequest): string {
  const taskLabel = {
    todayAdvisor: "Give today's personalized training decision using the generated plan, recent workouts, readiness, freshness, weekly loads, measurements, and progression hints.",
    workoutExplanation: "Explain today's generated workout and why it fits this user today.",
    progressSummary: "Summarize the user's progress trend and next focus.",
    nextSessionAdvice: "Give advice for the user's next training session."
  }[body.task];

  const outputInstruction =
    body.task === "todayAdvisor"
      ? [
          "Return strict JSON only. No markdown. No code fence.",
          "Schema: {\"trainingMode\":\"push|normal|hold|deload|rest\",\"message\":\"short advice under 90 words\",\"exerciseAdvice\":[{\"exerciseName\":\"exact planned exercise name\",\"action\":\"increase|hold|reduce|substitute\",\"suggestedWeightPounds\":number,\"reason\":\"short reason\"}]}",
          "Use only planned exercise names. Omit suggestedWeightPounds unless a specific load is provided or safely capped by exerciseProgressions."
        ].join("\n")
      : "Return only the coaching message.";

  return [
    taskLabel,
    outputInstruction,
    "AI Coach request JSON:",
    JSON.stringify(
      {
        task: body.task,
        context: body.context,
        plan: body.plan,
        freshness: body.freshness,
        weeklyLoads: body.weeklyLoads,
        recentSessions: body.recentSessions,
        recoveryTrend: body.recoveryTrend,
        measurements: body.measurements,
        exerciseProgressions: body.exerciseProgressions,
        progression: body.progression,
        fallbackGuidance: body.fallbackGuidance,
        fallbackMessage: body.fallbackMessage
      },
      null,
      2
    )
  ].join("\n\n");
}

function advisorResponseFromLLM(message: string, body: AICoachRequest): AdvisorResponse {
  const parsed = parseJsonObject(message);
  const fallbackMode = fallbackTrainingMode(body.fallbackGuidance);
  const parsedMode = parsed ? normalizeTrainingMode(parsed.trainingMode) : undefined;
  const trainingMode = parsedMode || fallbackMode || "normal";
  const parsedMessage = parsed && typeof parsed.message === "string" ? parsed.message : message;
  const exerciseAdvice =
    parsed && Array.isArray(parsed.exerciseAdvice)
      ? sanitizeAdvisorExerciseAdvice(parsed.exerciseAdvice, body)
      : [];

  return {
    trainingMode,
    message: sanitizeMessage(parsedMessage || body.fallbackMessage || "Use today's plan and keep each set clean."),
    exerciseAdvice: exerciseAdvice.length > 0 ? exerciseAdvice : fallbackExerciseAdvice(body.fallbackGuidance) || []
  };
}

function parseJsonObject(text: string): Record<string, unknown> | undefined {
  const cleaned = text
    .trim()
    .replace(/^```(?:json)?/i, "")
    .replace(/```$/i, "")
    .trim();

  try {
    const parsed: unknown = JSON.parse(cleaned);
    return isObject(parsed) ? parsed : undefined;
  } catch {
    const firstBrace = cleaned.indexOf("{");
    const lastBrace = cleaned.lastIndexOf("}");
    if (firstBrace < 0 || lastBrace <= firstBrace) {
      return undefined;
    }

    try {
      const parsed: unknown = JSON.parse(cleaned.slice(firstBrace, lastBrace + 1));
      return isObject(parsed) ? parsed : undefined;
    } catch {
      return undefined;
    }
  }
}

function sanitizeAdvisorExerciseAdvice(value: unknown[], body: AICoachRequest): AdvisorExerciseAdvice[] {
  const plannedNames = plannedExerciseNames(body.plan);
  const progressionCaps = progressionCapByExerciseName(body.exerciseProgressions || []);
  const results: AdvisorExerciseAdvice[] = [];

  for (const item of value) {
    if (!isObject(item) || typeof item.exerciseName !== "string") {
      continue;
    }

    const exerciseName = item.exerciseName.trim();
    if (!exerciseName) {
      continue;
    }

    if (plannedNames.size > 0 && !plannedNames.has(exerciseName.toLowerCase())) {
      continue;
    }

    const action = normalizeExerciseAction(item.action);
    if (!action) {
      continue;
    }

    const reason = sanitizeMessage(
      typeof item.reason === "string" && item.reason.trim()
        ? item.reason
        : "Use the app's progression guardrails."
    ).slice(0, 220);
    let suggestedWeightPounds =
      typeof item.suggestedWeightPounds === "number" && Number.isFinite(item.suggestedWeightPounds)
        ? Math.max(0, item.suggestedWeightPounds)
        : undefined;

    if (action === "increase") {
      const cap = progressionCaps.get(exerciseName.toLowerCase());
      if (cap === undefined) {
        suggestedWeightPounds = undefined;
      } else if (suggestedWeightPounds !== undefined) {
        suggestedWeightPounds = Math.min(suggestedWeightPounds, cap);
      }
    }

    results.push({
      exerciseName,
      action,
      suggestedWeightPounds,
      reason
    });
  }

  return results.slice(0, 8);
}

function plannedExerciseNames(plan: unknown): Set<string> {
  if (!isObject(plan) || !Array.isArray(plan.exercises)) {
    return new Set();
  }

  return new Set(
    plan.exercises
      .map((exercise) => {
        if (!isObject(exercise) || typeof exercise.name !== "string") {
          return "";
        }

        return exercise.name.trim().toLowerCase();
      })
      .filter(Boolean)
  );
}

function progressionCapByExerciseName(progression: unknown[]): Map<string, number> {
  const caps = new Map<string, number>();

  for (const item of progression) {
    if (!isObject(item) || typeof item.exerciseName !== "string") {
      continue;
    }

    const suggested = item.suggestedWeightPounds;
    if (typeof suggested !== "number" || !Number.isFinite(suggested) || suggested <= 0) {
      continue;
    }

    caps.set(item.exerciseName.trim().toLowerCase(), suggested);
  }

  return caps;
}

function fallbackTrainingMode(guidance: unknown): TrainingMode | undefined {
  if (!isObject(guidance)) {
    return undefined;
  }

  return normalizeTrainingMode(guidance.trainingMode);
}

function fallbackExerciseAdvice(guidance: unknown): AdvisorExerciseAdvice[] | undefined {
  if (!isObject(guidance) || !Array.isArray(guidance.exerciseAdvice)) {
    return undefined;
  }

  return guidance.exerciseAdvice.flatMap((item) => {
    if (!isObject(item) || typeof item.exerciseName !== "string") {
      return [];
    }

    const action = normalizeExerciseAction(item.action);
    const reason = typeof item.reason === "string" ? sanitizeMessage(item.reason).slice(0, 220) : "";
    if (!action || !reason) {
      return [];
    }

    const suggested = item.suggestedWeightPounds;
    return [
      {
        exerciseName: item.exerciseName,
        action,
        suggestedWeightPounds:
          typeof suggested === "number" && Number.isFinite(suggested) ? suggested : undefined,
        reason
      }
    ];
  });
}

function normalizeTrainingMode(value: unknown): TrainingMode | undefined {
  if (value === "push" || value === "normal" || value === "hold" || value === "deload" || value === "rest") {
    return value;
  }

  return undefined;
}

function normalizeExerciseAction(value: unknown): ExerciseAction | undefined {
  if (value === "increase" || value === "hold" || value === "reduce" || value === "substitute") {
    return value;
  }

  return undefined;
}

async function readProviderJson(response: Response): Promise<unknown> {
  const text = await response.text();
  let json: unknown;

  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = { raw: text };
  }

  if (!response.ok) {
    throw new Error(`Provider returned ${response.status}: ${text.slice(0, 500)}`);
  }

  return json;
}

function secretValue(secret: { value(): string }, envName: string): string | undefined {
  const envValue = process.env[envName]?.trim();
  if (envValue) {
    return envValue;
  }

  try {
    const value = secret.value().trim();
    return value || undefined;
  } catch {
    return undefined;
  }
}

function extractOpenAIMessage(json: unknown): string {
  if (isObject(json) && typeof json.output_text === "string") {
    return json.output_text;
  }

  if (isObject(json) && Array.isArray(json.output)) {
    const chunks = json.output.flatMap((item) => {
      if (!isObject(item) || !Array.isArray(item.content)) {
        return [];
      }

      return item.content
        .map((content) => {
          if (!isObject(content)) {
            return "";
          }

          return typeof content.text === "string" ? content.text : "";
        })
        .filter(Boolean);
    });

    if (chunks.length > 0) {
      return chunks.join(" ");
    }
  }

  throw new Error("OpenAI response did not include text.");
}

function extractAnthropicMessage(json: unknown): string {
  if (!isObject(json) || !Array.isArray(json.content)) {
    throw new Error("Anthropic response did not include content.");
  }

  const message = json.content
    .map((content) => {
      if (!isObject(content)) {
        return "";
      }

      return typeof content.text === "string" ? content.text : "";
    })
    .filter(Boolean)
    .join(" ");

  if (!message) {
    throw new Error("Anthropic response did not include text.");
  }

  return message;
}

function extractChatCompletionMessage(json: unknown): string {
  if (!isObject(json) || !Array.isArray(json.choices)) {
    throw new Error("Chat completion response did not include choices.");
  }

  const firstChoice = json.choices[0];
  if (!isObject(firstChoice) || !isObject(firstChoice.message) || typeof firstChoice.message.content !== "string") {
    throw new Error("Chat completion response did not include message content.");
  }

  return firstChoice.message.content;
}

function sanitizeMessage(message: string): string {
  return message
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 700);
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
