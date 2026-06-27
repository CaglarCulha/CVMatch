import OpenAI from "openai";
import { z } from "zod";

import { env } from "../config/env.js";
import { CareerAnalysisException } from "../errors/careerAnalysisException.js";
import { cvAnalysisResultSchema } from "../schemas/analysisSchemas.js";
import { cvAnalysisJsonSchema } from "./cvAnalysisJsonSchema.js";
import type { AIProvider, AnalysisPrompt, ProviderResponse } from "./provider.js";

type OpenAIRequestOptions = {
  timeout?: number;
  maxRetries?: number;
};

type OpenAIChatCreateBody = {
  model: string;
  messages: Array<{
    role: "system" | "user";
    content: string;
  }>;
  response_format: {
    type: "json_schema";
    json_schema: {
      name: string;
      strict: true;
      schema: typeof cvAnalysisJsonSchema;
    };
  };
  temperature: number;
};

type OpenAIChatCompletion = {
  model?: string;
  choices?: Array<{
    finish_reason?: string | null;
    message?: {
      content?: string | null;
      refusal?: string | null;
    };
  }>;
};

export type OpenAIChatClient = {
  chat: {
    completions: {
      create(
        body: OpenAIChatCreateBody,
        options?: OpenAIRequestOptions,
      ): Promise<OpenAIChatCompletion>;
    };
  };
};

type OpenAIProviderOptions = {
  apiKey?: string;
  model?: string;
  timeoutMs?: number;
  maxRetries?: number;
  retryDelayMs?: number;
  client?: OpenAIChatClient;
};

const defaultModel = "gpt-4.1-mini";
const defaultMaxRetries = 2;
const defaultRetryDelayMs = 250;
const openAIAnalysisResultSchema = cvAnalysisResultSchema.extend({
  keywordCoverage: z.number().int().min(0).max(100),
  strengths: z.array(z.string().min(1)).min(1).max(20),
  weaknesses: z.array(z.string().min(1)).min(1).max(20),
  improvements: z.array(z.string().min(1)).min(1).max(20),
  rewrittenSummary: z.string().min(1).max(2_000),
  mainReasonsForScore: z.array(z.string().min(1)).min(1).max(8),
  confidenceLevel: z.enum(["low", "medium", "high"]),
  recruiterVerdict: z.string().min(1).max(1_200),
  rejectionRisks: z.array(z.string().min(1)).length(3),
  fastestFixes: z.array(z.string().min(1)).length(3),
});

export class OpenAIProvider implements AIProvider {
  readonly name = "openai";
  private readonly apiKey: string | undefined;
  private readonly model: string;
  private readonly timeoutMs: number;
  private readonly maxRetries: number;
  private readonly retryDelayMs: number;
  private readonly injectedClient: OpenAIChatClient | undefined;
  private lazyClient: OpenAIChatClient | undefined;

  constructor(options: OpenAIProviderOptions = {}) {
    this.apiKey =
      options.apiKey === undefined
        ? env.openAiApiKey
        : cleanOptionalString(options.apiKey);
    this.model = cleanOptionalString(options.model) ?? defaultModel;
    this.timeoutMs = options.timeoutMs ?? env.openAiTimeoutMs;
    this.maxRetries = options.maxRetries ?? defaultMaxRetries;
    this.retryDelayMs = options.retryDelayMs ?? defaultRetryDelayMs;
    this.injectedClient = options.client;
  }

  async generateAnalysis(prompt: AnalysisPrompt): Promise<ProviderResponse> {
    const client = this.client();
    const startedAt = Date.now();
    let lastError: CareerAnalysisException | undefined;

    for (let attempt = 0; attempt <= this.maxRetries; attempt += 1) {
      try {
        const response = await client.chat.completions.create(
          this.requestBody(prompt),
          {
            timeout: remainingTimeoutMs(startedAt, this.timeoutMs),
            maxRetries: 0,
          },
        );
        const result = validateOpenAIJson(outputText(response));

        return {
          provider: this.name,
          model: response.model ?? this.model,
          content: JSON.stringify(result),
        };
      } catch (error) {
        const providerError = toCareerAnalysisException(error);
        lastError = providerError;

        if (
          !providerError.retryable ||
          attempt >= this.maxRetries ||
          remainingTimeoutMs(startedAt, this.timeoutMs) <= 1
        ) {
          throw providerError;
        }

        await delay(retryDelay(attempt, this.retryDelayMs, startedAt, this.timeoutMs));
      }
    }

    throw lastError ?? new CareerAnalysisException(502, "OpenAI provider request failed.");
  }

  private client(): OpenAIChatClient {
    if (this.injectedClient) {
      return this.injectedClient;
    }

    if (this.lazyClient) {
      return this.lazyClient;
    }

    if (!this.apiKey) {
      throw new CareerAnalysisException(503, "OpenAI provider is not configured.");
    }

    this.lazyClient = new OpenAI({
      apiKey: this.apiKey,
      timeout: this.timeoutMs,
      maxRetries: 0,
    }) as unknown as OpenAIChatClient;

    return this.lazyClient;
  }

  private requestBody(prompt: AnalysisPrompt): OpenAIChatCreateBody {
    return {
      model: this.model,
      messages: [
        { role: "system", content: prompt.system },
        { role: "user", content: prompt.user },
      ],
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "cv_analysis_result",
          strict: true,
          schema: cvAnalysisJsonSchema,
        },
      },
      temperature: 0.2,
    };
  }
}

function validateOpenAIJson(content: string) {
  let parsed: unknown;

  try {
    parsed = JSON.parse(content);
  } catch {
    throw new CareerAnalysisException(502, "OpenAI provider returned invalid JSON.");
  }

  const result = openAIAnalysisResultSchema.safeParse(parsed);
  if (!result.success) {
    throw new CareerAnalysisException(502, "OpenAI provider returned an invalid result.");
  }

  return result.data;
}

function outputText(response: OpenAIChatCompletion): string {
  const choice = response.choices?.[0];
  const refusal = choice?.message?.refusal;
  if (typeof refusal === "string" && refusal.trim().length > 0) {
    throw new CareerAnalysisException(502, "OpenAI provider refused to produce analysis.");
  }

  if (choice?.finish_reason === "length") {
    throw new CareerAnalysisException(502, "OpenAI provider response was truncated.");
  }

  const content = choice?.message?.content;
  if (typeof content === "string" && content.trim().length > 0) {
    return content;
  }

  throw new CareerAnalysisException(502, "OpenAI provider returned a malformed response.");
}

function toCareerAnalysisException(error: unknown): CareerAnalysisException {
  if (error instanceof CareerAnalysisException) {
    return error;
  }

  if (isTimeoutError(error)) {
    return new CareerAnalysisException(504, "OpenAI provider request timed out.", true);
  }

  const status = statusCode(error);
  if (status === 401 || status === 403) {
    return new CareerAnalysisException(
      503,
      "OpenAI provider is not configured correctly.",
    );
  }

  if (status === 408 || status === 409 || status === 429) {
    return new CareerAnalysisException(
      503,
      "OpenAI provider is temporarily unavailable.",
      true,
    );
  }

  if (status !== undefined && status >= 500) {
    return new CareerAnalysisException(
      503,
      "OpenAI provider is temporarily unavailable.",
      true,
    );
  }

  if (status === undefined && isNetworkError(error)) {
    return new CareerAnalysisException(
      503,
      "OpenAI provider is temporarily unavailable.",
      true,
    );
  }

  return new CareerAnalysisException(502, "OpenAI provider request failed.");
}

function isTimeoutError(error: unknown): boolean {
  if (!isErrorLike(error)) {
    return false;
  }

  return (
    error.name === "APIConnectionTimeoutError" ||
    error.code === "ETIMEDOUT" ||
    error.message.toLowerCase().includes("timeout")
  );
}

function isNetworkError(error: unknown): boolean {
  if (!isErrorLike(error)) {
    return false;
  }

  return (
    error.name === "APIConnectionError" ||
    error.code === "ECONNRESET" ||
    error.code === "ECONNREFUSED" ||
    error.code === "ENOTFOUND"
  );
}

function statusCode(error: unknown): number | undefined {
  if (!isErrorLike(error)) {
    return undefined;
  }

  if (typeof error.status === "number") {
    return error.status;
  }

  if (typeof error.statusCode === "number") {
    return error.statusCode;
  }

  return undefined;
}

function remainingTimeoutMs(startedAt: number, timeoutMs: number): number {
  return Math.max(timeoutMs - (Date.now() - startedAt), 1);
}

function retryDelay(
  attempt: number,
  retryDelayMs: number,
  startedAt: number,
  timeoutMs: number,
): number {
  const exponentialDelay = retryDelayMs * 2 ** attempt;
  const remaining = remainingTimeoutMs(startedAt, timeoutMs);

  return Math.min(exponentialDelay, Math.max(remaining - 1, 0));
}

function delay(ms: number): Promise<void> {
  if (ms <= 0) {
    return Promise.resolve();
  }

  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

function cleanOptionalString(value: string | undefined): string | undefined {
  const trimmed = value?.trim();

  return trimmed && trimmed.length > 0 ? trimmed : undefined;
}

function isErrorLike(
  error: unknown,
): error is {
  name?: string;
  message: string;
  code?: string;
  status?: number;
  statusCode?: number;
} {
  return (
    typeof error === "object" &&
    error !== null &&
    "message" in error &&
    typeof (error as { message?: unknown }).message === "string"
  );
}
