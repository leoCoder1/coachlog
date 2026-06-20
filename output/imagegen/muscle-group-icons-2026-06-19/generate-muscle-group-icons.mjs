import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

const repoRoot = process.cwd();
const envText = await readFile(path.join(repoRoot, ".env"), "utf8");
const env = Object.fromEntries(
  envText
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith("#") && line.includes("="))
    .map((line) => {
      const index = line.indexOf("=");
      return [line.slice(0, index), line.slice(index + 1)];
    })
);

const apiKey = env.XAI_API_KEY;
if (!apiKey) {
  throw new Error("XAI_API_KEY is missing from .env");
}

const outputDir = path.join(repoRoot, "output/imagegen/muscle-group-icons-2026-06-19");
const tmpDir = "/private/tmp/coachlog-xai-muscle-group-icons";
await mkdir(outputDir, { recursive: true });
await mkdir(tmpDir, { recursive: true });

const commonPrompt = [
  "Square 1:1 polished fitness app muscle-group infographic icon for a dark-mode iOS app.",
  "Centered simplified anatomical human silhouette, graphite gray body, bright teal/cyan target muscle highlight.",
  "High contrast, clean professional 3D anatomical render, rounded dark charcoal vignette background, legible at 24 px.",
  "Tasteful non-sexual fitness anatomy presentation. No gore, no exposed organs, no skeleton, no equipment.",
  "No text, no letters, no numbers, no logo, no watermark, no extra people, no cropped body parts."
].join(" ");

const icons = [
  {
    slug: "muscle-group-filter-all",
    title: "All",
    detail: "Show a front-facing full-body silhouette with all major muscle groups softly highlighted in teal."
  },
  {
    slug: "muscle-group-filter-chest",
    title: "Chest",
    detail: "Show a front-facing upper-body torso silhouette with only the left and right pectoral chest muscles highlighted."
  },
  {
    slug: "muscle-group-filter-back",
    title: "Back",
    detail: "Show a rear-facing upper-body torso silhouette with lats, traps, and upper back muscles highlighted."
  },
  {
    slug: "muscle-group-filter-legs",
    title: "Legs",
    detail: "Show a front-facing lower-body silhouette with quadriceps, hamstrings, and calves highlighted."
  },
  {
    slug: "muscle-group-filter-glutes",
    title: "Glutes",
    detail: "Show a rear-facing hips and upper-leg silhouette with only the glute muscles highlighted."
  },
  {
    slug: "muscle-group-filter-shoulders",
    title: "Shoulders",
    detail: "Show a front-facing upper-body silhouette with only the left and right deltoid shoulder caps highlighted."
  },
  {
    slug: "muscle-group-filter-biceps",
    title: "Biceps",
    detail: "Show a front-facing upper-body silhouette with only the front upper arm biceps highlighted."
  },
  {
    slug: "muscle-group-filter-triceps",
    title: "Triceps",
    detail: "Show a rear-facing upper-body silhouette with only the back upper arm triceps highlighted."
  },
  {
    slug: "muscle-group-filter-core",
    title: "Core",
    detail: "Show a front-facing torso silhouette with abs and obliques highlighted."
  }
];

const manifest = {
  model: "grok-imagine-image-quality",
  resolution: "1k",
  aspect_ratio: "1:1",
  generated_at: new Date().toISOString(),
  items: []
};

for (const icon of icons) {
  const prompt = `${commonPrompt} ${icon.detail}`;
  console.log(`Generating ${icon.title}...`);

  const response = await fetch("https://api.x.ai/v1/images/generations", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model: "grok-imagine-image-quality",
      prompt,
      n: 1,
      aspect_ratio: "1:1",
      resolution: "1k"
    })
  });

  const json = await response.json();
  if (!response.ok) {
    manifest.items.push({
      ...icon,
      status: "error",
      prompt,
      response: json
    });
    await writeFile(path.join(outputDir, "manifest.json"), JSON.stringify(manifest, null, 2));
    throw new Error(`xAI request failed for ${icon.title}: ${JSON.stringify(json)}`);
  }

  const item = json.data?.[0];
  const url = item?.url;
  const b64 = item?.b64_json;
  const filePath = path.join(outputDir, `${icon.slug}.jpeg`);
  const tmpPath = path.join(tmpDir, `${icon.slug}.jpeg`);

  if (url) {
    const imageResponse = await fetch(url);
    if (!imageResponse.ok) {
      throw new Error(`Failed to download ${icon.title}: ${imageResponse.status}`);
    }
    const buffer = Buffer.from(await imageResponse.arrayBuffer());
    await writeFile(filePath, buffer);
    await writeFile(tmpPath, buffer);
  } else if (b64) {
    const buffer = Buffer.from(b64, "base64");
    await writeFile(filePath, buffer);
    await writeFile(tmpPath, buffer);
  } else {
    throw new Error(`No image URL or base64 payload returned for ${icon.title}`);
  }

  manifest.items.push({
    ...icon,
    status: "ok",
    prompt,
    output_path: filePath,
    usage: json.usage,
    estimated_cost_usd: json.usage?.cost_in_usd_ticks
      ? json.usage.cost_in_usd_ticks / 10_000_000_000
      : 0.05,
    response_metadata: {
      usage: json.usage
    }
  });

  await writeFile(path.join(outputDir, "manifest.json"), JSON.stringify(manifest, null, 2));
}

console.log(`Wrote ${manifest.items.length} icons to ${outputDir}`);
