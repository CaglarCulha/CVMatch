import type { AnalyzeRequest, CvAnalysisResult } from "../types/analysis.js";
import { clamp, normalizeText, toTitleCase, unique } from "../utils/text.js";
import type { AIProvider, AnalysisPrompt, ProviderResponse } from "./provider.js";

type KeywordGroup = {
  label: string;
  terms: string[];
};

const keywordCatalog: KeywordGroup[] = [
  { label: "AI workflows", terms: ["ai", "assistant", "automation", "workflow"] },
  { label: "LLM evaluation", terms: ["llm", "model evaluation", "eval", "quality"] },
  { label: "Prompt testing", terms: ["prompt", "prompting", "testing"] },
  {
    label: "Product discovery",
    terms: ["product discovery", "user research", "customer discovery", "research"],
  },
  { label: "Roadmap ownership", terms: ["roadmap", "strategy", "prioritization", "ownership"] },
  { label: "Activation metrics", terms: ["activation", "retention", "conversion", "metrics"] },
  { label: "Experiment design", terms: ["experiment", "hypothesis", "a/b", "ab test"] },
  {
    label: "Stakeholder leadership",
    terms: ["stakeholder", "cross-functional", "leadership", "alignment"],
  },
  { label: "GTM strategy", terms: ["gtm", "go-to-market", "launch", "positioning"] },
  { label: "Risk controls", terms: ["risk", "safety", "governance", "trust"] },
  { label: "Data pipelines", terms: ["data pipeline", "analytics", "sql", "dashboard"] },
  { label: "Cloud platforms", terms: ["aws", "gcp", "azure", "cloud"] },
  { label: "API integration", terms: ["api", "integration", "webhook", "service"] },
  { label: "Security practices", terms: ["security", "privacy", "compliance", "encryption"] },
  { label: "Team management", terms: ["manager", "mentor", "hiring", "team"] },
];

const cvSectionSignals = ["experience", "education", "skills", "projects", "summary"];

export class MockProvider implements AIProvider {
  readonly name = "mock";

  async generateAnalysis(prompt: AnalysisPrompt): Promise<ProviderResponse> {
    const result = buildMockResult(prompt.request);

    return {
      provider: this.name,
      model: "mock-career-analysis-v1",
      content: JSON.stringify(result),
    };
  }
}

function buildMockResult(request: AnalyzeRequest): CvAnalysisResult {
  const cvText = normalizeText(request.cvText);
  const jobDescription = normalizeText(request.jobDescription);
  const jobKeywords = labelsIn(jobDescription);
  const cvKeywords = labelsIn(cvText);
  const overlap = jobKeywords.filter((keyword) => cvKeywords.includes(keyword));
  const missingKeywords = missingKeywordList(jobKeywords, cvKeywords, jobDescription, cvText);
  const sectionScore = cvSectionSignals.filter((signal) => cvText.includes(signal)).length;
  const overlapRatio = jobKeywords.length === 0 ? 0.35 : overlap.length / jobKeywords.length;
  const roleBoost = roleSignal(request.targetRole, cvText, jobDescription);
  const matchScore = clamp(
    Math.round(34 + overlapRatio * 42 + sectionScore * 3 + roleBoost),
    28,
    88,
  );
  const atsScore = clamp(
    Math.round(matchScore - missingKeywords.length * 2 + sectionScore * 4),
    30,
    88,
  );
  const roleLabel = request.targetRole?.trim() || inferRole(jobDescription);
  const strongest = overlap.slice(0, 3);

  return {
    matchScore,
    atsScore,
    missingKeywords,
    strongPoints: strongPoints(strongest, sectionScore, roleLabel),
    weakPoints: weakPoints(missingKeywords, overlapRatio),
    suggestedImprovements: suggestedImprovements(missingKeywords, roleLabel),
    coverLetter: coverLetter(request.cvFileName, roleLabel, strongest, matchScore),
    interviewQuestions: interviewQuestions(roleLabel, missingKeywords, strongest),
  };
}

function labelsIn(text: string): string[] {
  return keywordCatalog
    .filter((group) => group.terms.some((term) => text.includes(term)))
    .map((group) => group.label);
}

function missingKeywordList(
  jobKeywords: string[],
  cvKeywords: string[],
  jobDescription: string,
  cvText: string,
): string[] {
  const curatedMissing = jobKeywords.filter((keyword) => !cvKeywords.includes(keyword));
  const inferredMissing = importantTerms(jobDescription).filter(
    (term) => !cvText.includes(term.toLowerCase()),
  );

  return unique([...curatedMissing, ...inferredMissing.map(toTitleCase)]).slice(0, 8);
}

function importantTerms(text: string): string[] {
  const stopWords = new Set([
    "about",
    "after",
    "also",
    "and",
    "are",
    "for",
    "from",
    "has",
    "have",
    "into",
    "our",
    "the",
    "this",
    "that",
    "with",
    "will",
    "work",
    "you",
    "your",
  ]);
  const words = text.match(/[a-z][a-z-]{3,}/g) ?? [];
  const counts = new Map<string, number>();

  for (const word of words) {
    if (!stopWords.has(word)) {
      counts.set(word, (counts.get(word) ?? 0) + 1);
    }
  }

  return [...counts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([word]) => word);
}

function roleSignal(targetRole: string | undefined, cvText: string, jobDescription: string): number {
  if (!targetRole) return 0;

  const terms = normalizeText(targetRole)
    .split(/\s+/)
    .filter((term) => term.length > 3);

  if (terms.length === 0) return 0;

  const cvHits = terms.filter((term) => cvText.includes(term)).length;
  const jobHits = terms.filter((term) => jobDescription.includes(term)).length;

  return Math.min(cvHits + jobHits, 4);
}

function inferRole(jobDescription: string): string {
  if (jobDescription.includes("product")) return "Product Role";
  if (jobDescription.includes("engineer")) return "Engineering Role";
  if (jobDescription.includes("designer")) return "Design Role";
  if (jobDescription.includes("data")) return "Data Role";

  return "Target Role";
}

function strongPoints(keywords: string[], sectionScore: number, roleLabel: string): string[] {
  const points = keywords.map((keyword) => `${keyword} appears in both the CV and job description.`);

  if (sectionScore >= 3) {
    points.push("The CV includes recognizable sections that support ATS readability.");
  }

  if (points.length === 0) {
    points.push(`The CV contains readable text, but alignment with the ${roleLabel} requirements is limited.`);
  }

  return points.slice(0, 5);
}

function weakPoints(missingKeywords: string[], overlapRatio: number): string[] {
  const points: string[] = [];

  if (missingKeywords.length > 0) {
    points.push(`Missing or underrepresented role signals: ${missingKeywords.slice(0, 4).join(", ")}.`);
  }

  if (overlapRatio < 0.35) {
    points.push("Keyword overlap is low, so the CV may need stronger role-specific framing.");
  }

  points.push("Mock AI provider result. Production AI providers are not enabled yet.");

  return points;
}

function suggestedImprovements(missingKeywords: string[], roleLabel: string): string[] {
  return [
    `Rewrite the professional summary around ${roleLabel} outcomes and measurable impact.`,
    missingKeywords.length > 0
      ? `Add truthful evidence for priority keywords such as ${missingKeywords.slice(0, 3).join(", ")}.`
      : "Add more quantified outcomes that connect responsibilities to business results.",
    "Use bullet points that show scope, action, tooling, and result.",
    "Keep keyword additions natural and only include skills or achievements that are accurate.",
  ];
}

function coverLetter(
  cvFileName: string,
  roleLabel: string,
  strongestKeywords: string[],
  matchScore: number,
): string {
  const focus = strongestKeywords.length > 0 ? strongestKeywords.join(", ") : "role-specific impact";

  return `Dear hiring team,\n\nI am excited to apply for the ${roleLabel}. Based on the current CV analysis for ${cvFileName}, my strongest alignment signals are ${focus}. The current match score is ${matchScore}%, and I would position my application around measurable outcomes, relevant collaboration, and clear evidence of impact.\n\nBest regards`;
}

function interviewQuestions(
  roleLabel: string,
  missingKeywords: string[],
  strongestKeywords: string[],
): string[] {
  const strongestKeyword = strongestKeywords.at(0);
  const missingKeyword = missingKeywords.at(0);

  return [
    `Which project best demonstrates your readiness for this ${roleLabel}?`,
    strongestKeyword
      ? `Can you explain a concrete example involving ${strongestKeyword}?`
      : "Which parts of your CV best match the job requirements?",
    missingKeyword
      ? `How would you address the gap around ${missingKeyword} in an interview?`
      : "What measurable result would you highlight first?",
    "What would you improve in the CV before applying?",
  ];
}
