import type { CvRewriteRequest, CvRewriteResult, CvRewriteService } from "../types/rewrite.js";
import { CvRewriteValidator } from "./cvRewriteValidator.js";
import type { AIProvider } from "./provider.js";
import { PromptBuilder } from "./promptBuilder.js";
import { ResponseParser } from "./responseParser.js";

type CvRewriteOrchestratorOptions = {
  provider: AIProvider;
  promptBuilder?: PromptBuilder;
  responseParser?: ResponseParser;
  resultValidator?: CvRewriteValidator;
};

export class CvRewriteOrchestrator implements CvRewriteService {
  private readonly promptBuilder: PromptBuilder;
  private readonly responseParser: ResponseParser;
  private readonly resultValidator: CvRewriteValidator;

  constructor(private readonly options: CvRewriteOrchestratorOptions) {
    this.promptBuilder = options.promptBuilder ?? new PromptBuilder();
    this.responseParser = options.responseParser ?? new ResponseParser();
    this.resultValidator = options.resultValidator ?? new CvRewriteValidator();
  }

  async rewrite(request: CvRewriteRequest): Promise<CvRewriteResult> {
    const prompt = this.promptBuilder.buildCvRewrite(request);
    const providerResponse = await this.options.provider.generateCvRewrite(prompt);
    const parsedResponse = this.responseParser.parse(providerResponse);

    return this.resultValidator.validate(parsedResponse);
  }
}
