import { onRequest } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

const chatgptApiKey = defineSecret("CHATGPT_API_KEY");
const claudeApiKey = defineSecret("CLAUDE_API_KEY");
const xaiApiKey = defineSecret("XAI_API_KEY");

const llmProvider = defineString("LLM_PROVIDER", { default: "openai" });
const openAIModel = defineString("OPENAI_MODEL", { default: "gpt-5.5" });
const claudeModel = defineString("CLAUDE_MODEL", { default: "" });
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

export const health = onRequest(
  {
    region: "us-central1",
    timeoutSeconds: 10,
    memory: "256MiB"
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
      system: coachSystemPrompt,
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
