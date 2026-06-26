import { HttpError } from "../errors/httpError.js";
import { cvAnalysisResultSchema } from "../schemas/analysisSchemas.js";
import type { CvAnalysisResult } from "../types/analysis.js";

export class ResultValidator {
  validate(value: unknown): CvAnalysisResult {
    const parsed = cvAnalysisResultSchema.safeParse(value);
    if (!parsed.success) {
      throw new HttpError(502, "Analysis provider returned an invalid result.");
    }

    return parsed.data;
  }
}
