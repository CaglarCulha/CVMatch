import type { AnalyzeRequest } from "../types/analysis.js";
import type { CvRewriteRequest } from "../types/rewrite.js";

export type AnalysisProviderName = "mock" | "openai" | "gemini" | (string & {});

export type AnalysisPrompt = {
  system: string;
  user: string;
  request: AnalyzeRequest;
  responseFormat: "CvAnalysisResultJson";
};

export type CvRewritePrompt = {
  system: string;
  user: string;
  request: CvRewriteRequest;
  responseFormat: "CvRewriteResultJson";
};

export type ProviderResponse = {
  provider: AnalysisProviderName;
  content: string;
  model?: string;
};

export interface AIProvider {
  readonly name: AnalysisProviderName;

  generateAnalysis(prompt: AnalysisPrompt): Promise<ProviderResponse>;

  generateCvRewrite(prompt: CvRewritePrompt): Promise<ProviderResponse>;
}
