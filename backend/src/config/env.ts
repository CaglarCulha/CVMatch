import dotenv from "dotenv";

dotenv.config();

const defaultCorsOrigins = [
  "http://localhost:54321",
  "http://127.0.0.1:54321",
  "http://localhost:3000",
];

function parsePort(value: string | undefined): number {
  if (!value) return 3001;

  const parsed = Number.parseInt(value, 10);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > 65535) {
    throw new Error("PORT must be an integer between 1 and 65535.");
  }

  return parsed;
}

function parseCorsOrigins(value: string | undefined): string[] | true {
  if (!value) return defaultCorsOrigins;
  if (value.trim() === "*") return true;

  return value
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);
}

function parsePositiveInteger(
  value: string | undefined,
  fallback: number,
  name: string,
): number {
  if (!value) return fallback;

  const parsed = Number.parseInt(value, 10);
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error(`${name} must be a positive integer.`);
  }

  return parsed;
}

export const env = Object.freeze({
  nodeEnv: process.env.NODE_ENV ?? "development",
  port: parsePort(process.env.PORT),
  requestSizeLimit: process.env.REQUEST_SIZE_LIMIT ?? "1mb",
  corsOrigins: parseCorsOrigins(process.env.CORS_ORIGIN),
  aiProvider: process.env.AI_PROVIDER?.trim().toLowerCase() || "mock",
  openAiApiKey: process.env.OPENAI_API_KEY?.trim() || undefined,
  openAiModel: process.env.OPENAI_MODEL?.trim() || "gpt-4.1-mini",
  openAiTimeoutMs: parsePositiveInteger(
    process.env.OPENAI_REQUEST_TIMEOUT_MS,
    45_000,
    "OPENAI_REQUEST_TIMEOUT_MS",
  ),
  geminiApiKey: process.env.GEMINI_API_KEY?.trim() || undefined,
  geminiModel: process.env.GEMINI_MODEL?.trim() || "gemini-2.5-flash",
  geminiTimeoutMs: parsePositiveInteger(
    process.env.GEMINI_REQUEST_TIMEOUT_MS,
    45_000,
    "GEMINI_REQUEST_TIMEOUT_MS",
  ),
});
