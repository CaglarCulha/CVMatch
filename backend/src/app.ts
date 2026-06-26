import cors from "cors";
import express from "express";
import helmet from "helmet";

import { corsOptions } from "./config/cors.js";
import { env } from "./config/env.js";
import { errorHandler } from "./middleware/errorHandler.js";
import { notFound } from "./middleware/notFound.js";
import { AnalysisOrchestrator, ProviderFactory } from "./providers/index.js";
import { createAnalyzeRouter } from "./routes/analyze.js";
import type { CareerAnalysisService } from "./types/analysis.js";

type CreateAppOptions = {
  analysisService?: CareerAnalysisService;
};

export function createApp(options: CreateAppOptions = {}) {
  const app = express();
  const analysisService =
    options.analysisService ??
    new AnalysisOrchestrator({ provider: ProviderFactory.create() });

  app.disable("x-powered-by");
  app.use(helmet());
  app.use(cors(corsOptions));
  app.options("*", cors(corsOptions));
  app.use(express.json({ limit: env.requestSizeLimit }));

  app.get("/health", (_request, response) => {
    response.status(200).json({
      status: "ok",
      service: "cvmatch-backend",
    });
  });

  app.use(createAnalyzeRouter(analysisService));
  app.use(notFound);
  app.use(errorHandler);

  return app;
}
