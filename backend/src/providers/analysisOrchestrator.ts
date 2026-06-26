import type { CareerAnalysisService, AnalyzeRequest, CvAnalysisResult } from "../types/analysis.js";
import type { AIProvider } from "./provider.js";
import { PromptBuilder } from "./promptBuilder.js";
import { ResponseParser } from "./responseParser.js";
import { ResultValidator } from "./resultValidator.js";

type AnalysisOrchestratorOptions = {
  provider: AIProvider;
  promptBuilder?: PromptBuilder;
  responseParser?: ResponseParser;
  resultValidator?: ResultValidator;
};

export class AnalysisOrchestrator implements CareerAnalysisService {
  private readonly promptBuilder: PromptBuilder;
  private readonly responseParser: ResponseParser;
  private readonly resultValidator: ResultValidator;

  constructor(private readonly options: AnalysisOrchestratorOptions) {
    this.promptBuilder = options.promptBuilder ?? new PromptBuilder();
    this.responseParser = options.responseParser ?? new ResponseParser();
    this.resultValidator = options.resultValidator ?? new ResultValidator();
  }

  async analyze(request: AnalyzeRequest): Promise<CvAnalysisResult> {
    const prompt = this.promptBuilder.build(request);
    const providerResponse = await this.options.provider.generateAnalysis(prompt);
    const parsedResponse = this.responseParser.parse(providerResponse);

    return this.resultValidator.validate(parsedResponse);
  }
}
