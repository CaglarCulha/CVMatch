import { Router } from "express";

import { HttpError } from "../errors/httpError.js";
import {
  cvRewriteResultSchema,
  rewriteCvRequestSchema,
} from "../schemas/analysisSchemas.js";
import type { CvRewriteService } from "../types/rewrite.js";

export function createRewriteCvRouter(rewriteService: CvRewriteService): Router {
  const router = Router();

  router.post("/rewrite-cv", async (request, response, next) => {
    try {
      const parsedRequest = rewriteCvRequestSchema.safeParse(request.body);
      if (!parsedRequest.success) {
        return response.status(400).json({
          error: "Invalid CV rewrite request.",
          details: parsedRequest.error.issues.map((issue) => ({
            field: issue.path.join("."),
            message: issue.message,
          })),
        });
      }

      const result = await rewriteService.rewrite(parsedRequest.data);
      const parsedResult = cvRewriteResultSchema.safeParse(result);
      if (!parsedResult.success) {
        throw new HttpError(500, "CV rewrite service returned an invalid result.");
      }

      return response.status(200).json(parsedResult.data);
    } catch (error) {
      return next(error);
    }
  });

  return router;
}
