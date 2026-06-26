import { HttpError } from "./httpError.js";

export class CareerAnalysisException extends HttpError {
  constructor(
    statusCode: number,
    message: string,
    public readonly retryable = false,
  ) {
    super(statusCode, message);
    this.name = "CareerAnalysisException";
  }
}
