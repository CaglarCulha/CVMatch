import request from "supertest";
import { afterEach, describe, expect, it, vi } from "vitest";

import { createApp } from "../src/app.js";
import { AnalysisOrchestrator, MockProvider } from "../src/providers/index.js";
import type { CareerAnalysisService } from "../src/types/analysis.js";

const validPayload = {
  cvText:
    "Professional summary experience skills education projects. Product discovery roadmap ownership AI workflows prompt testing activation metrics stakeholder leadership.",
  cvFileName: "Derya_Kaya_CV.pdf",
  jobDescription:
    "We are hiring an AI product manager to own product discovery, roadmap strategy, prompt testing, activation metrics, stakeholder leadership, and launch planning for trusted assistant workflows.",
  locale: "en-US",
  targetRole: "AI Product Manager",
};

describe("POST /analyze", () => {
  const app = createApp({
    analysisService: new AnalysisOrchestrator({ provider: new MockProvider() }),
  });
  const localOrigin = "http://localhost:61732";

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("handles preflight requests for Flutter Web localhost origins", async () => {
    const response = await request(app)
      .options("/analyze")
      .set("Origin", localOrigin)
      .set("Access-Control-Request-Method", "POST")
      .set("Access-Control-Request-Headers", "Content-Type, Authorization")
      .expect(204);

    expect(response.headers["access-control-allow-origin"]).toBe(localOrigin);
    expect(response.headers["access-control-allow-methods"]).toContain("GET");
    expect(response.headers["access-control-allow-methods"]).toContain("POST");
    expect(response.headers["access-control-allow-methods"]).toContain("OPTIONS");
    expect(response.headers["access-control-allow-headers"]).toContain("Content-Type");
    expect(response.headers["access-control-allow-headers"]).toContain("Authorization");
  });

  it("returns a CvAnalysisResult-compatible response", async () => {
    const response = await request(app)
      .post("/analyze")
      .set("Origin", localOrigin)
      .send(validPayload)
      .expect(200);

    expect(response.headers["access-control-allow-origin"]).toBe(localOrigin);
    expect(response.body).toMatchObject({
      matchScore: expect.any(Number),
      atsScore: expect.any(Number),
      missingKeywords: expect.any(Array),
      strongPoints: expect.any(Array),
      weakPoints: expect.any(Array),
      suggestedImprovements: expect.any(Array),
      coverLetter: expect.any(String),
      interviewQuestions: expect.any(Array),
    });
    expect(response.body.matchScore).toBeGreaterThanOrEqual(0);
    expect(response.body.matchScore).toBeLessThanOrEqual(100);
    expect(response.body.weakPoints.join(" ")).toContain("Mock AI provider result");
  });

  it("rejects short job descriptions without echoing sensitive content", async () => {
    const response = await request(app)
      .post("/analyze")
      .set("Origin", localOrigin)
      .send({ ...validPayload, jobDescription: "Too short" })
      .expect(400);

    expect(response.headers["access-control-allow-origin"]).toBe(localOrigin);
    expect(response.body.error).toBe("Invalid analysis request.");
    expect(JSON.stringify(response.body)).not.toContain(validPayload.cvText);
  });

  it("rejects non-PDF CV file names", async () => {
    const response = await request(app)
      .post("/analyze")
      .set("Origin", localOrigin)
      .send({ ...validPayload, cvFileName: "notes.txt" })
      .expect(400);

    expect(response.headers["access-control-allow-origin"]).toBe(localOrigin);
    expect(response.body.error).toBe("Invalid analysis request.");
  });

  it("returns JSON internal_error with CORS when analysis throws", async () => {
    const consoleError = vi.spyOn(console, "error").mockImplementation(() => undefined);
    const throwingService: CareerAnalysisService = {
      analyze: async () => {
        throw new Error("diagnostic failure");
      },
    };
    const throwingApp = createApp({ analysisService: throwingService });

    const response = await request(throwingApp)
      .post("/analyze")
      .set("Origin", "http://127.0.0.1:59321")
      .send(validPayload)
      .expect(500);

    expect(response.headers["access-control-allow-origin"]).toBe("http://127.0.0.1:59321");
    expect(response.body).toEqual({ error: "internal_error" });
    expect(consoleError).toHaveBeenCalledWith(
      "backend_exception",
      expect.objectContaining({
        method: "POST",
        path: "/analyze",
        statusCode: 500,
        errorName: "Error",
        stack: expect.stringContaining("diagnostic failure"),
      }),
    );
  });
});
