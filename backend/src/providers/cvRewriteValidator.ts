import { HttpError } from "../errors/httpError.js";
import { cvRewriteResultSchema } from "../schemas/analysisSchemas.js";
import type { CvRewriteResult } from "../types/rewrite.js";

export class CvRewriteValidator {
  validate(value: unknown): CvRewriteResult {
    const parsed = cvRewriteResultSchema.safeParse(value);
    if (!parsed.success) {
      throw new HttpError(502, "CV rewrite provider returned an invalid result.");
    }

    return parsed.data;
  }
}
