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

type AICoachTask = "workoutExplanation" | "progressSummary" | "nextSessionAdvice";
type LLMProvider = "openai" | "anthropic" | "xai";

interface AICoachRequest {
  task: AICoachTask;
  context?: unknown;
  plan?: unknown;
  freshness?: unknown[];
  recentSessions?: unknown[];
  measurements?: unknown[];
  progression?: unknown;
  fallbackMessage?: string;
  provider?: LLMProvider;
}

interface ProviderResult {
  message: string;
  provider: LLMProvider;
  model: string;
}

const coachSystemPrompt = [
  "You are CoachLog's premium AI strength coach.",
  "Use only the provided training, recovery, progression, and measurement data.",
  "Return one concise, practical coaching message for the requested task.",
  "Keep it under 90 words. No markdown. No lists.",
  "Be specific about the user's plan or trend, but do not invent data.",
  "If pain is present, recommend conservative loading and substitution.",
  "Do not diagnose medical conditions or claim guaranteed outcomes."
].join(" ");

const claudeCoachReferencePrompt = [
  "CoachLog reusable coaching rubric:",
  "The app is a strength training coach for everyday lifters who want simple, confident decisions in the gym. The output must feel like a capable human coach who has read the user's log, not like a generic chatbot. Use the user's actual exercise names, recent weights, reps, recovery values, freshness states, and body measurements when they are provided. Do not add facts that are not in the request. Do not say you are analyzing data unless you immediately convert that analysis into a useful training decision.",
  "Style rules: write in one short paragraph under 90 words. Use plain language. Use direct, specific action verbs. Avoid hype, medical certainty, moral judgment, and vague reassurance. Avoid markdown, bullets, headings, tables, emojis, disclaimers, and long explanations. Prefer phrasing like 'start with', 'hold', 'reduce', 'substitute', 'aim for', 'keep', and 'stop if'. Mention one or two numbers from the log when they change the decision. If there is no useful data for a claim, say what to do next rather than inventing a trend.",
  "Safety rules: if the request includes pain, discomfort, poor sleep, high resting heart rate, low HRV, low readiness, overloaded muscle freshness, or recent heavy volume, bias toward conservative loading, cleaner technique, smaller range of motion, or a substitution. Do not diagnose injuries. Do not tell the user to push through pain. Do not prescribe rehab. Use language such as 'stay in a pain-free range', 'reduce load', 'skip the painful pattern', or 'choose a similar movement'. If the user has high readiness but a specific joint warning, train the ready muscles while protecting that joint.",
  "Progression rules: when the user completed the top of a rep range with stable form, a small weight increase is reasonable. If reps dropped, form was uncertain, sleep was low, readiness was low, or the same muscle group is in caution, hold the weight or reduce volume. For strength movements, prefer small jumps. For dumbbells and machines, use available increments. If the user's goal is fat loss or body recomposition, connect strength retention, waist or abdomen changes, and consistency without promising outcomes.",
  "Workout explanation rules: explain why today's workout fits the user's available time, goal, readiness, and muscle freshness. Name the main exercises that drive the goal. If a muscle group is in caution, explain the practical adjustment. Keep the message focused on what the user should do today. Do not restate the full plan.",
  "Progress summary rules: compare the latest relevant data to earlier data. Useful patterns include weight moved, reps completed, volume trend, consistency, waist or abdomen trend, sleep, HRV, resting heart rate, and measurement direction. Good changes for many users include waist and abdomen going down while strength, chest, shoulders, arms, glutes, or legs improve. Never imply causation from correlation. End with one next focus.",
  "Next-session advice rules: turn freshness, last session, progression recommendation, recovery, and constraints into a concrete session choice. If equipment is busy, suggest substitutes that train the same primary muscles and match the user's goal. If leg press is busy, options might include hip thrust, Romanian deadlift, goblet squat, split squat, step-up, cable glute kickback, or leg curl depending on pain and muscle freshness. If overhead pressing irritates the shoulder, options might include landmine press, neutral-grip dumbbell press, machine chest press, lateral raise, row variation, or lower load depending on the plan.",
  "Example response for a shoulder-sensitive push day: 'Today still fits your chest and back goal, but keep pressing controlled. Bench at 125 lb can be your main strength work if warm-ups feel clean; with front delts and triceps in caution, avoid chasing extra reps and keep incline dumbbells lighter. If the shoulder complains, swap to a neutral-grip press and put more effort into rows.'",
  "Example response for body-measurement progress: 'Strength and body composition are moving in the right direction: bench is up from 115 to 125 lb while weight, waist, and abdomen are down. That is exactly the trend CoachLog wants to protect. Keep the next push session focused on completing 125 for clean sets before increasing again, and keep weekly training consistent.'",
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

      response.status(200).json({
        message: sanitizeMessage(result.message),
        provider: result.provider,
        model: result.model,
        source: "premium"
      });
    } catch (error) {
      logger.error("AI coach request failed", error);

      response.status(200).json({
        message: sanitizeMessage(
          body.fallbackMessage ||
            "CoachLog could not reach premium AI right now. Use the local plan and keep today conservative."
        ),
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
    recentSessions: Array.isArray(candidate.recentSessions) ? candidate.recentSessions : [],
    measurements: Array.isArray(candidate.measurements) ? candidate.measurements : [],
    progression: candidate.progression,
    fallbackMessage: typeof candidate.fallbackMessage === "string" ? candidate.fallbackMessage : undefined,
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
      max_output_tokens: 320,
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
      max_tokens: 320,
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
      max_tokens: 320,
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
    workoutExplanation: "Explain today's generated workout and why it fits this user today.",
    progressSummary: "Summarize the user's progress trend and next focus.",
    nextSessionAdvice: "Give advice for the user's next training session."
  }[body.task];

  return [
    taskLabel,
    "Return only the coaching message.",
    "CoachLog request JSON:",
    JSON.stringify(
      {
        task: body.task,
        context: body.context,
        plan: body.plan,
        freshness: body.freshness,
        recentSessions: body.recentSessions,
        measurements: body.measurements,
        progression: body.progression,
        fallbackMessage: body.fallbackMessage
      },
      null,
      2
    )
  ].join("\n\n");
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
