import type { ErrorRequestHandler } from "express";

import { HttpError } from "../errors/httpError.js";

export const errorHandler: ErrorRequestHandler = (
  error,
  request,
  response,
  next,
) => {
  if (response.headersSent) {
    return next(error);
  }

  const parserError = error as { status?: number; type?: string };
  const statusCode = statusCodeFor(error, parserError);

  console.error("backend_exception", {
    method: request.method,
    path: request.path,
    statusCode,
    errorName: error instanceof Error ? error.name : "UnknownError",
    message: error instanceof Error ? error.message : "Unknown backend error",
    stack: error instanceof Error ? error.stack : undefined,
  });

  return response.status(statusCode).json({ error: "internal_error" });
};

function statusCodeFor(
  error: unknown,
  parserError: { status?: number; type?: string },
): number {
  if (parserError.type === "entity.too.large") {
    return 413;
  }

  if (error instanceof SyntaxError && parserError.status === 400) {
    return 400;
  }

  if (error instanceof HttpError) {
    return error.statusCode;
  }

  return 500;
}
