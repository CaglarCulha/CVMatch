import { Router } from "express";

import { HttpError } from "../errors/httpError.js";
import {
  analyzeRequestSchema,
  cvAnalysisResultSchema,
} from "../schemas/analysisSchemas.js";
import type { CareerAnalysisService } from "../types/analysis.js";

export function createAnalyzeRouter(
  analysisService: CareerAnalysisService,
): Router {
  const router = Router();

  router.post("/analyze", async (request, response, next) => {
    try {
      const parsedRequest = analyzeRequestSchema.safeParse(request.body);
      if (!parsedRequest.success) {
        return response.status(400).json({
          error: "Invalid analysis request.",
          details: parsedRequest.error.issues.map((issue) => ({
            field: issue.path.join("."),
            message: issue.message,
          })),
        });
      }

      const result = await analysisService.analyze(parsedRequest.data);
      const parsedResult = cvAnalysisResultSchema.safeParse(result);
      if (!parsedResult.success) {
        throw new HttpError(
          500,
          "Analysis service returned an invalid result.",
        );
      }

      return response.status(200).json(parsedResult.data);
    } catch (error) {
      return next(error);
    }
  });

  return router;
}
