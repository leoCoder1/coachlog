#!/usr/bin/env node
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";

const args = parseArgs(process.argv.slice(2));
const repo = path.resolve(args.repo ?? process.cwd());
const jobsPath = must(args.jobs, "--jobs is required");
const outDir = path.resolve(args.out ?? "/private/tmp/coachlog-xai-exercise-videos");
const envPath = path.resolve(args.env ?? path.join(repo, ".env"));
const model = args.model ?? "grok-imagine-video";
const duration = Number(args.duration ?? 8);
const dryRun = Boolean(args["dry-run"]);

const env = await readEnv(envPath);
const apiKey = env.XAI_API_KEY ?? process.env.XAI_API_KEY;
if (!apiKey && !dryRun) throw new Error("XAI_API_KEY is missing from .env or environment");

const jobs = JSON.parse(await readFile(path.resolve(jobsPath), "utf8"));
if (!Array.isArray(jobs) || jobs.length === 0) throw new Error("jobs JSON must be a non-empty array");

await mkdir(outDir, { recursive: true });
await mkdir(path.join(outDir, "raw"), { recursive: true });
await mkdir(path.join(outDir, "app-ready"), { recursive: true });

const manifest = {
  created_at: new Date().toISOString(),
  model,
  duration,
  repo,
  out_dir: outDir,
  jobs: []
};

for (const job of jobs) {
  const slug = job.slug ?? slugify(job.exercise);
  const filename = `${slug}.mp4`;
  const prompt = job.prompt ?? defaultPrompt(job.exercise);
  const sourceImage = resolveMaybe(repo, job.sourceImage);
  const modelImage = resolveMaybe(repo, job.modelImage);
  const body = {
    model,
    prompt,
    duration
  };

  if (sourceImage) {
    body.image = {
      url: await dataUri(sourceImage),
      type: "image_url"
    };
  }

  if (modelImage) {
    body.reference_images = [
      {
        url: await dataUri(modelImage),
        type: "image_url"
      }
    ];
  }

  const record = {
    exercise: job.exercise,
    slug,
    filename,
    sourceImage,
    modelImage,
    prompt,
    status: "pending"
  };
  manifest.jobs.push(record);
  await saveManifest();

  if (dryRun) {
    record.status = "dry-run";
    continue;
  }

  console.log(`Submitting ${job.exercise ?? slug}...`);
  let submit = await postJson("https://api.x.ai/v1/videos/generations", apiKey, body);

  if (!submit.ok && modelImage && String(JSON.stringify(submit.json)).includes("reference_images")) {
    record.reference_images_retry = submit.json;
    delete body.reference_images;
    submit = await postJson("https://api.x.ai/v1/videos/generations", apiKey, body);
  }

  record.submit_status = submit.status;
  record.submit_response = submit.json;
  if (!submit.ok) {
    record.status = "submit-error";
    await saveManifest();
    continue;
  }

  const requestId = submit.json.request_id;
  record.request_id = requestId;
  await saveManifest();

  let result = null;
  for (let attempt = 0; attempt < 120; attempt += 1) {
    await sleep(5000);
    const poll = await getJson(`https://api.x.ai/v1/videos/${requestId}`, apiKey);
    record.last_poll_status = poll.status;
    record.last_poll_response = poll.json;
    await saveManifest();

    if (poll.ok && poll.json.status === "done") {
      result = poll.json;
      break;
    }
    if (poll.ok && ["failed", "error", "cancelled"].includes(poll.json.status)) {
      break;
    }
  }

  if (!result?.video?.url) {
    record.status = "poll-error";
    await saveManifest();
    continue;
  }

  const rawPath = path.join(outDir, "raw", filename);
  const readyPath = path.join(outDir, "app-ready", filename);
  const videoResponse = await fetch(result.video.url);
  if (!videoResponse.ok) {
    record.status = "download-error";
    record.download_status = videoResponse.status;
    await saveManifest();
    continue;
  }

  await writeFile(rawPath, Buffer.from(await videoResponse.arrayBuffer()));
  normalizeVideo(rawPath, readyPath);

  record.status = "downloaded";
  record.video_url = result.video.url;
  record.raw_path = rawPath;
  record.app_ready_path = readyPath;
  record.usage = result.usage;
  record.estimated_cost_usd = result.usage?.cost_in_usd_ticks
    ? result.usage.cost_in_usd_ticks / 10_000_000_000
    : null;
  await saveManifest();
}

await saveManifest();
console.log(`Manifest: ${path.join(outDir, "manifest.json")}`);

async function saveManifest() {
  await writeFile(path.join(outDir, "manifest.json"), JSON.stringify(manifest, null, 2));
}

function normalizeVideo(input, output) {
  const result = spawnSync("ffmpeg", [
    "-y",
    "-i",
    input,
    "-an",
    "-vf",
    "scale=480:480:force_original_aspect_ratio=increase,crop=480:480,fps=24",
    "-c:v",
    "libx264",
    "-profile:v",
    "high",
    "-pix_fmt",
    "yuv420p",
    "-movflags",
    "+faststart",
    output
  ], { encoding: "utf8" });

  if (result.status !== 0) {
    throw new Error(`ffmpeg failed for ${input}: ${result.stderr}`);
  }
}

async function postJson(url, apiKey, body) {
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`
    },
    body: JSON.stringify(body)
  });
  return { ok: response.ok, status: response.status, json: await response.json().catch(() => ({})) };
}

async function getJson(url, apiKey) {
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${apiKey}` }
  });
  return { ok: response.ok, status: response.status, json: await response.json().catch(() => ({})) };
}

async function dataUri(filePath) {
  const buffer = await readFile(filePath);
  const ext = path.extname(filePath).toLowerCase();
  const mime = ext === ".png" ? "image/png" : ext === ".webp" ? "image/webp" : "image/jpeg";
  return `data:${mime};base64,${buffer.toString("base64")}`;
}

async function readEnv(filePath) {
  try {
    const text = await readFile(filePath, "utf8");
    return Object.fromEntries(text.split(/\r?\n/).map((line) => line.trim()).filter((line) => line && !line.startsWith("#") && line.includes("=")).map((line) => {
      const idx = line.indexOf("=");
      return [line.slice(0, idx), line.slice(idx + 1)];
    }));
  } catch {
    return {};
  }
}

function resolveMaybe(repo, value) {
  if (!value) return null;
  return path.isAbsolute(value) ? value : path.resolve(repo, value);
}

function defaultPrompt(exercise) {
  return `Create an 8 second muted seamless looping instructional fitness video. One adult athletic fitness model performs one complete correct repetition of ${exercise}. Fixed camera, full body visible, no cuts, no zoom. Return to the exact starting position for a smooth loop. No text, no logos, no watermark, no extra people, no distorted hands, no unsafe posture.`;
}

function slugify(value) {
  return `exercise-${String(value ?? "video").toLowerCase().replace(/&/g, "and").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
}

function must(value, message) {
  if (!value) throw new Error(message);
  return value;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseArgs(argv) {
  const parsed = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith("--")) continue;
    const key = arg.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith("--")) {
      parsed[key] = true;
    } else {
      parsed[key] = next;
      i += 1;
    }
  }
  return parsed;
}
