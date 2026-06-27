import type { AnalyzeRequest } from "../types/analysis.js";
import type { CvRewriteRequest } from "../types/rewrite.js";
import type { AnalysisPrompt, CvRewritePrompt } from "./provider.js";
import { analysisSystemTemplate } from "./templates/analysisSystemTemplate.js";
import { analysisUserTemplate } from "./templates/analysisUserTemplate.js";
import { rewriteSystemTemplate } from "./templates/rewriteSystemTemplate.js";
import { rewriteUserTemplate } from "./templates/rewriteUserTemplate.js";

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

  buildCvRewrite(request: CvRewriteRequest): CvRewritePrompt {
    return {
      system: rewriteSystemTemplate,
      user: applyTemplate(rewriteUserTemplate, {
        LOCALE: request.locale,
        TARGET_ROLE: request.targetRole ?? "Not provided",
        CV_TEXT: request.cvText,
        JOB_DESCRIPTION: request.jobDescription,
      }),
      request,
      responseFormat: "CvRewriteResultJson",
    };
  }
}

function applyTemplate(template: string, variables: TemplateVariables): string {
  return Object.entries(variables).reduce(
    (result, [key, value]) => result.split(`{{${key}}}`).join(value),
    template,
  );
}
