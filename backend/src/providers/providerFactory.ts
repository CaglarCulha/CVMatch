import { env } from "../config/env.js";
import type { AIProvider } from "./provider.js";
import { GeminiProvider } from "./geminiProvider.js";
import { MockProvider } from "./mockProvider.js";
import { OpenAIProvider } from "./openAIProvider.js";

export class ProviderFactory {
  static create(providerName: string = env.aiProvider): AIProvider {
    switch (providerName.toLowerCase()) {
      case "mock":
        return new MockProvider();
      case "openai":
        return new OpenAIProvider(
          env.openAiApiKey
            ? {
                apiKey: env.openAiApiKey,
                model: env.openAiModel,
                timeoutMs: env.openAiTimeoutMs,
              }
            : {
                model: env.openAiModel,
                timeoutMs: env.openAiTimeoutMs,
              },
        );
      case "gemini":
        return new GeminiProvider(
          env.geminiApiKey
            ? {
                apiKey: env.geminiApiKey,
                model: env.geminiModel,
                timeoutMs: env.geminiTimeoutMs,
              }
            : {
                model: env.geminiModel,
                timeoutMs: env.geminiTimeoutMs,
              },
        );
      default:
        throw new Error(`Unsupported AI provider: ${providerName}`);
    }
  }
}
