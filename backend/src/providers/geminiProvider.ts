import { GoogleGenAI } from "@google/genai";

import { env } from "../config/env.js";
import { CareerAnalysisException } from "../errors/careerAnalysisException.js";
import { cvAnalysisJsonSchema } from "./cvAnalysisJsonSchema.js";
import { cvRewriteJsonSchema } from "./cvRewriteJsonSchema.js";
import type {
  AIProvider,
  AnalysisPrompt,
  CvRewritePrompt,
  ProviderResponse,
} from "./provider.js";

type GeminiGenerateContentBody = {
  model: string;
  contents: string;
  config: {
    systemInstruction: string;
    temperature: number;
    responseMimeType: "application/json";
    responseJsonSchema: typeof cvAnalysisJsonSchema | typeof cvRewriteJsonSchema;
    httpOptions: {
      timeout: number;
    };
  };
};

type GeminiGenerateContentResponse = {
  text?: string;
  modelVersion?: string;
  candidates?: Array<{
    finishReason?: string;
  }>;
  promptFeedback?: unknown;
};

export type GeminiClient = {
  models: {
    generateContent(
      body: GeminiGenerateContentBody,
    ): Promise<GeminiGenerateContentResponse>;
  };
};

type GeminiProviderOptions = {
  apiKey?: string;
  model?: string;
  timeoutMs?: number;
  maxRetries?: number;
  retryDelayMs?: number;
  client?: GeminiClient;
};

const defaultModel = "gemini-2.5-flash";
const defaultMaxRetries = 2;
const defaultRetryDelayMs = 250;

export class GeminiProvider implements AIProvider {
  readonly name = "gemini";
  private readonly apiKey: string | undefined;
  private readonly model: string;
  private readonly timeoutMs: number;
  private readonly maxRetries: number;
  private readonly retryDelayMs: number;
  private readonly injectedClient: GeminiClient | undefined;
  private lazyClient: GeminiClient | undefined;

  constructor(options: GeminiProviderOptions = {}) {
    this.apiKey =
      options.apiKey === undefined
        ? env.geminiApiKey
        : cleanOptionalString(options.apiKey);
    this.model = cleanOptionalString(options.model) ?? defaultModel;
    this.timeoutMs = options.timeoutMs ?? env.geminiTimeoutMs;
    this.maxRetries = options.maxRetries ?? defaultMaxRetries;
    this.retryDelayMs = options.retryDelayMs ?? defaultRetryDelayMs;
    this.injectedClient = options.client;
  }

  async generateAnalysis(prompt: AnalysisPrompt): Promise<ProviderResponse> {
    return this.generate(prompt);
  }

  async generateCvRewrite(prompt: CvRewritePrompt): Promise<ProviderResponse> {
    return this.generate(prompt);
  }

  private async generate(
    prompt: AnalysisPrompt | CvRewritePrompt,
  ): Promise<ProviderResponse> {
    const client = this.client();
    const startedAt = Date.now();
    let lastError: CareerAnalysisException | undefined;

    for (let attempt = 0; attempt <= this.maxRetries; attempt += 1) {
      try {
        const response = await client.models.generateContent(
          this.requestBody(prompt, remainingTimeoutMs(startedAt, this.timeoutMs)),
        );

        return {
          provider: this.name,
          model: response.modelVersion ?? this.model,
          content: outputText(response),
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

    throw lastError ?? new CareerAnalysisException(502, "Gemini provider request failed.");
  }

  private client(): GeminiClient {
    if (this.injectedClient) {
      return this.injectedClient;
    }

    if (this.lazyClient) {
      return this.lazyClient;
    }

    if (!this.apiKey) {
      throw new CareerAnalysisException(503, "Gemini provider is not configured.");
    }

    this.lazyClient = new GoogleGenAI({
      apiKey: this.apiKey,
      httpOptions: {
        timeout: this.timeoutMs,
      },
    }) as unknown as GeminiClient;

    return this.lazyClient;
  }

  private requestBody(
    prompt: AnalysisPrompt | CvRewritePrompt,
    timeoutMs: number,
  ): GeminiGenerateContentBody {
    return {
      model: this.model,
      contents: prompt.user,
      config: {
        systemInstruction: prompt.system,
        temperature: 0.2,
        responseMimeType: "application/json",
        responseJsonSchema: schemaFor(prompt),
        httpOptions: {
          timeout: timeoutMs,
        },
      },
    };
  }
}

function schemaFor(prompt: AnalysisPrompt | CvRewritePrompt) {
  return prompt.responseFormat === "CvRewriteResultJson"
    ? cvRewriteJsonSchema
    : cvAnalysisJsonSchema;
}

function outputText(response: GeminiGenerateContentResponse): string {
  const finishReason = response.candidates?.[0]?.finishReason;

  if (finishReason === "MAX_TOKENS") {
    throw new CareerAnalysisException(502, "Gemini provider response was truncated.");
  }

  if (isBlockedFinishReason(finishReason)) {
    throw new CareerAnalysisException(502, "Gemini provider refused to produce analysis.");
  }

  if (response.promptFeedback && response.candidates?.length === 0) {
    throw new CareerAnalysisException(502, "Gemini provider refused to produce analysis.");
  }

  if (typeof response.text === "string" && response.text.trim().length > 0) {
    return response.text;
  }

  throw new CareerAnalysisException(502, "Gemini provider returned a malformed response.");
}

function toCareerAnalysisException(error: unknown): CareerAnalysisException {
  if (error instanceof CareerAnalysisException) {
    return error;
  }

  if (isTimeoutError(error)) {
    return new CareerAnalysisException(504, "Gemini provider request timed out.", true);
  }

  const status = statusCode(error);
  if (status === 400) {
    return new CareerAnalysisException(502, "Gemini provider rejected the request.");
  }

  if (status === 401 || status === 403) {
    return new CareerAnalysisException(
      503,
      "Gemini provider is not configured correctly.",
    );
  }

  if (status === 408 || status === 409 || status === 429) {
    return new CareerAnalysisException(
      503,
      "Gemini provider is temporarily unavailable.",
      true,
    );
  }

  if (status !== undefined && status >= 500) {
    return new CareerAnalysisException(
      503,
      "Gemini provider is temporarily unavailable.",
      true,
    );
  }

  if (status === undefined && isNetworkError(error)) {
    return new CareerAnalysisException(
      503,
      "Gemini provider is temporarily unavailable.",
      true,
    );
  }

  return new CareerAnalysisException(502, "Gemini provider request failed.");
}

function isBlockedFinishReason(finishReason: string | undefined): boolean {
  return (
    finishReason === "SAFETY" ||
    finishReason === "RECITATION" ||
    finishReason === "LANGUAGE" ||
    finishReason === "BLOCKLIST" ||
    finishReason === "PROHIBITED_CONTENT" ||
    finishReason === "SPII"
  );
}

function isTimeoutError(error: unknown): boolean {
  if (!isErrorLike(error)) {
    return false;
  }

  return (
    error.name === "TimeoutError" ||
    error.name === "AbortError" ||
    error.code === "ETIMEDOUT" ||
    error.message.toLowerCase().includes("timeout")
  );
}

function isNetworkError(error: unknown): boolean {
  if (!isErrorLike(error)) {
    return false;
  }

  return (
    error.name === "FetchError" ||
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
