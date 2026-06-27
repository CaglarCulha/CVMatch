import { z } from "zod";

const optionalTrimmedString = (maxLength: number) =>
  z.preprocess(
    (value) => {
      if (typeof value === "string" && value.trim().length === 0) {
        return undefined;
      }

      return value;
    },
    z.string().trim().min(2).max(maxLength).optional(),
  );

export const analyzeRequestSchema = z.object({
  cvText: z
    .string({
      required_error: "cvText is required.",
      invalid_type_error: "cvText must be a string.",
    })
    .trim()
    .min(40, "cvText must contain readable CV text.")
    .max(120_000, "cvText is too large for analysis."),
  cvFileName: z
    .string({
      required_error: "cvFileName is required.",
      invalid_type_error: "cvFileName must be a string.",
    })
    .trim()
    .min(5)
    .max(255)
    .regex(/\.pdf$/i, "cvFileName must reference a PDF file."),
  jobDescription: z
    .string({
      required_error: "jobDescription is required.",
      invalid_type_error: "jobDescription must be a string.",
    })
    .trim()
    .min(100, "jobDescription must be at least 100 characters.")
    .max(60_000, "jobDescription is too large for analysis."),
  locale: z
    .string({
      required_error: "locale is required.",
      invalid_type_error: "locale must be a string.",
    })
    .trim()
    .min(2)
    .max(35)
    .regex(/^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/, "locale must be a valid language tag."),
  targetRole: optionalTrimmedString(120),
});

export const cvAnalysisResultSchema = z.object({
  matchScore: z.number().int().min(0).max(100),
  atsScore: z.number().int().min(0).max(100),
  keywordCoverage: z.number().int().min(0).max(100).optional(),
  missingKeywords: z.array(z.string().min(1)).max(20),
  strengths: z.array(z.string().min(1)).min(1).max(20).optional(),
  weaknesses: z.array(z.string().min(1)).min(1).max(20).optional(),
  improvements: z.array(z.string().min(1)).min(1).max(20).optional(),
  rewrittenSummary: z.string().min(1).max(2_000).optional(),
  mainReasonsForScore: z.array(z.string().min(1)).min(1).max(8).optional(),
  confidenceLevel: z.enum(["low", "medium", "high"]).optional(),
  recruiterVerdict: z.string().min(1).max(1_200).optional(),
  rejectionRisks: z.array(z.string().min(1)).length(3).optional(),
  fastestFixes: z.array(z.string().min(1)).length(3).optional(),
  strongPoints: z.array(z.string().min(1)).min(1).max(20),
  weakPoints: z.array(z.string().min(1)).min(1).max(20),
  suggestedImprovements: z.array(z.string().min(1)).min(1).max(20),
  coverLetter: z.string().min(1).max(8_000),
  interviewQuestions: z.array(z.string().min(1)).min(1).max(20),
});

export type ParsedAnalyzeRequest = z.infer<typeof analyzeRequestSchema>;
