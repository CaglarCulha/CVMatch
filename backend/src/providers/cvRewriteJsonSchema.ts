export const cvRewriteJsonSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    rewrittenSummary: {
      type: "string",
      minLength: 1,
      maxLength: 2000,
      description:
        "A truthful, job-tailored professional summary using only CV evidence.",
    },
    rewrittenExperienceBullets: {
      type: "array",
      minItems: 1,
      maxItems: 12,
      items: { type: "string", minLength: 1, maxLength: 600 },
      description:
        "Truthful rewritten experience bullets tailored to the job description.",
    },
    rewrittenSkills: {
      type: "array",
      minItems: 1,
      maxItems: 40,
      items: { type: "string", minLength: 1, maxLength: 120 },
      description:
        "Skills that are supported by the CV and relevant to the job description.",
    },
    improvementNotes: {
      type: "array",
      minItems: 1,
      maxItems: 12,
      items: { type: "string", minLength: 1, maxLength: 800 },
      description:
        "Actionable notes explaining how to improve the CV without inventing experience.",
    },
    warnings: {
      type: "array",
      minItems: 1,
      maxItems: 12,
      items: { type: "string", minLength: 1, maxLength: 800 },
      description:
        "Truthfulness, missing evidence, and placeholder warnings for the candidate.",
    },
  },
  required: [
    "rewrittenSummary",
    "rewrittenExperienceBullets",
    "rewrittenSkills",
    "improvementNotes",
    "warnings",
  ],
} as const;
