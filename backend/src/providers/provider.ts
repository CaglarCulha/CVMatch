import type { AnalyzeRequest } from "../types/analysis.js";

export type AnalysisProviderName = "mock" | "openai" | (string & {});

export type AnalysisPrompt = {
  system: string;
  user: string;
  request: AnalyzeRequest;
  responseFormat: "CvAnalysisResultJson";
};

export type ProviderResponse = {
  provider: AnalysisProviderName;
  content: string;
  model?: string;
};

export interface AIProvider {
  readonly name: AnalysisProviderName;

  generateAnalysis(prompt: AnalysisPrompt): Promise<ProviderResponse>;
}
