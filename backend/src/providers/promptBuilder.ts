import type { AnalyzeRequest } from "../types/analysis.js";
import type { AnalysisPrompt } from "./provider.js";
import { analysisSystemTemplate } from "./templates/analysisSystemTemplate.js";
import { analysisUserTemplate } from "./templates/analysisUserTemplate.js";

type TemplateVariables = Record<string, string>;

export class PromptBuilder {
  build(request: AnalyzeRequest): AnalysisPrompt {
    return {
      system: analysisSystemTemplate,
      user: applyTemplate(analysisUserTemplate, {
        CV_FILE_NAME: request.cvFileName,
        LOCALE: request.locale,
        TARGET_ROLE: request.targetRole ?? "Not provided",
        CV_TEXT: request.cvText,
        JOB_DESCRIPTION: request.jobDescription,
      }),
      request,
      responseFormat: "CvAnalysisResultJson",
    };
  }
}

function applyTemplate(template: string, variables: TemplateVariables): string {
  return Object.entries(variables).reduce(
    (result, [key, value]) => result.split(`{{${key}}}`).join(value),
    template,
  );
}
