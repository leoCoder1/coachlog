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

const slug = "muscle-group-filter-chest";
const prompt = [
  "Square 1:1 dark-mode fitness app icon.",
  "Simple front torso only, no head, no legs.",
  "Graphite gray anatomical torso on a charcoal background.",
  "Two large bright teal pectoral chest muscle shapes highlighted clearly on the upper front torso.",
  "Clean professional 3D render, high contrast, readable at tiny iOS filter-chip size.",
  "No text, no letters, no logo, no watermark, no organs, no skeleton, no gore, no equipment, no extra people."
].join(" ");

console.log("Regenerating Chest...");
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
  throw new Error(`xAI request failed: ${JSON.stringify(json)}`);
}

const item = json.data?.[0];
const url = item?.url;
const b64 = item?.b64_json;
const retryPath = path.join(outputDir, `${slug}-v2.jpeg`);

if (url) {
  const imageResponse = await fetch(url);
  if (!imageResponse.ok) {
    throw new Error(`Failed to download retry: ${imageResponse.status}`);
  }
  const buffer = Buffer.from(await imageResponse.arrayBuffer());
  await writeFile(retryPath, buffer);
  await writeFile(path.join(outputDir, `${slug}.jpeg`), buffer);
  await writeFile(path.join(tmpDir, `${slug}.jpeg`), buffer);
} else if (b64) {
  const buffer = Buffer.from(b64, "base64");
  await writeFile(retryPath, buffer);
  await writeFile(path.join(outputDir, `${slug}.jpeg`), buffer);
  await writeFile(path.join(tmpDir, `${slug}.jpeg`), buffer);
} else {
  throw new Error("No image URL or base64 payload returned");
}

const manifestPath = path.join(outputDir, "manifest.json");
const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
manifest.items.push({
  slug: `${slug}-v2`,
  title: "Chest retry",
  status: "ok",
  prompt,
  output_path: retryPath,
  usage: json.usage,
  estimated_cost_usd: json.usage?.cost_in_usd_ticks
    ? json.usage.cost_in_usd_ticks / 10_000_000_000
    : 0.05,
  response_metadata: {
    usage: json.usage
  },
  note: "Retry because the first Chest generation returned a blank black image."
});
await writeFile(manifestPath, JSON.stringify(manifest, null, 2));
console.log(`Wrote ${retryPath}`);
