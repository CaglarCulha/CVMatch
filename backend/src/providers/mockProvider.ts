import type { AnalyzeRequest, CvAnalysisResult } from "../types/analysis.js";
import type { CvRewriteRequest, CvRewriteResult } from "../types/rewrite.js";
import { clamp, normalizeText, toTitleCase, unique } from "../utils/text.js";
import type {
  AIProvider,
  AnalysisPrompt,
  CvRewritePrompt,
  ProviderResponse,
} from "./provider.js";

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
  { label: "Roadmap ownership", terms: ["roadmap", "roadmap ownership", "prioritization"] },
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
  { label: "CRM", terms: ["crm", "customer relationship management"] },
  { label: "Salesforce", terms: ["salesforce"] },
  { label: "SAP", terms: ["sap"] },
  { label: "Quota ownership", terms: ["quota", "quota ownership", "quota attainment"] },
  { label: "Pipeline management", terms: ["pipeline", "pipeline management"] },
  { label: "Technical sales", terms: ["technical sales", "solutions selling", "pre-sales"] },
  { label: "Negotiation", terms: ["negotiation", "negotiated", "commercial negotiation"] },
  { label: "B2B sales", terms: ["b2b", "b2b sales", "enterprise sales"] },
];

const cvSectionSignals = ["experience", "education", "skills", "projects", "summary"];
const criticalEvidenceLabels = new Set([
  "CRM",
  "Salesforce",
  "SAP",
  "Quota ownership",
  "Pipeline management",
  "Technical sales",
  "Negotiation",
  "B2B sales",
  "Activation metrics",
  "Stakeholder leadership",
  "Team management",
]);

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

  async generateCvRewrite(prompt: CvRewritePrompt): Promise<ProviderResponse> {
    const result = buildMockRewriteResult(prompt.request);

    return {
      provider: this.name,
      model: "mock-cv-rewrite-v1",
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
  const criticalMissingCount = missingKeywords.filter((keyword) =>
    criticalEvidenceLabels.has(keyword),
  ).length;
  const matchScore = clamp(
    Math.round(
      26 +
        overlapRatio * 58 +
        sectionScore * 2 +
        roleBoost -
        Math.min(missingKeywords.length * 2, 18) -
        criticalMissingCount * 4,
    ),
    18,
    88,
  );
  const atsScore = clamp(
    Math.round(42 + sectionScore * 7 + overlapRatio * 25 - missingKeywords.length - criticalMissingCount * 2),
    25,
    88,
  );
  const roleLabel = request.targetRole?.trim() || inferRole(jobDescription);
  const strongest = overlap.slice(0, 3);
  const strengths = strongPoints(strongest, sectionScore, roleLabel);
  const weaknesses = weakPoints(missingKeywords, overlapRatio, cvText);
  const improvements = suggestedImprovements(missingKeywords, roleLabel);

  return {
    matchScore,
    atsScore,
    keywordCoverage: clamp(Math.round(overlapRatio * 100), 0, 100),
    missingKeywords,
    strengths,
    weaknesses,
    improvements,
    rewrittenSummary: rewrittenSummary(roleLabel, strongest, missingKeywords),
    mainReasonsForScore: mainReasonsForScore(
      overlap,
      missingKeywords,
      overlapRatio,
      criticalMissingCount,
    ),
    confidenceLevel: confidenceLevel(sectionScore, jobKeywords.length),
    recruiterVerdict: recruiterVerdict(matchScore, missingKeywords),
    rejectionRisks: topThree(weaknesses),
    fastestFixes: topThree(improvements),
    strongPoints: strengths,
    weakPoints: weaknesses,
    suggestedImprovements: improvements,
    coverLetter: coverLetter(request.cvFileName, roleLabel, strongest, matchScore),
    interviewQuestions: interviewQuestions(roleLabel, missingKeywords, strongest),
  };
}

function buildMockRewriteResult(request: CvRewriteRequest): CvRewriteResult {
  const cvText = normalizeText(request.cvText);
  const jobDescription = normalizeText(request.jobDescription);
  const cvKeywords = labelsIn(cvText);
  const jobKeywords = labelsIn(jobDescription);
  const overlap = jobKeywords.filter((keyword) => cvKeywords.includes(keyword));
  const missingKeywords = missingKeywordList(jobKeywords, cvKeywords, jobDescription, cvText);
  const roleLabel = request.targetRole?.trim() || inferRole(jobDescription);
  const supportedSkills = supportedRewriteSkills(overlap, cvKeywords, cvText);
  const hasMetrics = containsMetrics(request.cvText);

  return {
    rewrittenSummary: rewriteSummary(roleLabel, supportedSkills, missingKeywords, hasMetrics),
    rewrittenExperienceBullets: rewriteExperienceBullets(roleLabel, supportedSkills, hasMetrics),
    rewrittenSkills: supportedSkills,
    improvementNotes: rewriteImprovementNotes(roleLabel, missingKeywords, hasMetrics),
    warnings: rewriteWarnings(missingKeywords, hasMetrics),
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

  return unique([...curatedMissing, ...inferredMissing.map(toTitleCase)]).slice(0, 12);
}

function importantTerms(text: string): string[] {
  const stopWords = new Set([
    "about",
    "after",
    "also",
    "and",
    "are",
    "business",
    "candidate",
    "company",
    "customer",
    "customers",
    "description",
    "experience",
    "for",
    "from",
    "has",
    "have",
    "into",
    "our",
    "role",
    "sales",
    "skills",
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

function supportedRewriteSkills(
  overlap: string[],
  cvKeywords: string[],
  cvText: string,
): string[] {
  const inferredCvTerms = importantTerms(cvText).map(toTitleCase);
  const skills = unique([...overlap, ...cvKeywords.slice(0, 8), ...inferredCvTerms]).filter(
    (skill) => skill.length > 2,
  );

  return skills.length > 0 ? skills.slice(0, 12) : ["CV-supported transferable experience"];
}

function containsMetrics(text: string): boolean {
  return /\b\d+([.,]\d+)?\s*(%|percent|k|m|million|billion|users|customers|revenue|quota|hours|days|weeks|months|years)\b/i.test(
    text,
  );
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
  if (jobDescription.includes("sales")) return "Sales Role";
  if (jobDescription.includes("product")) return "Product Role";
  if (jobDescription.includes("engineer")) return "Engineering Role";
  if (jobDescription.includes("designer")) return "Design Role";
  if (jobDescription.includes("data")) return "Data Role";

  return "Target Role";
}

function strongPoints(keywords: string[], sectionScore: number, roleLabel: string): string[] {
  const points = keywords.map(
    (keyword) =>
      `${keyword} is evidenced in the CV and matters because the ${roleLabel} depends on this requirement.`,
  );

  if (sectionScore >= 3) {
    points.push("The CV has recognizable sections, which makes recruiter screening and ATS parsing easier.");
  }

  if (points.length === 0) {
    points.push(`The CV provides readable baseline career information, but job-specific evidence for the ${roleLabel} is limited.`);
  }

  return points.slice(0, 5);
}

function weakPoints(missingKeywords: string[], overlapRatio: number, cvText: string): string[] {
  const points: string[] = [];

  if (missingKeywords.length > 0) {
    points.push(`The CV does not provide clear evidence for role-critical requirements: ${missingKeywords.slice(0, 4).join(", ")}.`);
  }

  if (
    cvText.includes("business development") &&
    missingKeywords.some((keyword) => keyword === "Quota ownership" || keyword === "Pipeline management")
  ) {
    points.push(
      "The CV mentions business development but does not show quota ownership, pipeline value, or conversion metrics.",
    );
  }

  if (overlapRatio < 0.35) {
    points.push("Keyword overlap is low, so a recruiter would likely see the CV as under-evidenced for this role.");
  }

  points.push("Mock AI provider result. Production AI providers are not enabled yet.");

  return points;
}

function suggestedImprovements(missingKeywords: string[], roleLabel: string): string[] {
  return [
    `Rewrite the professional summary for the ${roleLabel}: add a one-line positioning statement, place it at the top, and connect it to the job. Example: "${roleLabel} candidate with experience in [insert strongest truthful domain] and [insert measurable result if present]."`,
    missingKeywords.length > 0
      ? `Add truthful evidence for ${missingKeywords.slice(0, 3).join(", ")} in the Experience or Skills section because these appear important to screening. Example wording: "Used [tool/process] to [action] resulting in [insert verified outcome]."`
      : "Add quantified outcomes under Experience because recruiters need proof of impact. Example wording: \"Improved [metric] by [insert verified percentage or amount].\"",
    "Rewrite bullets using scope, action, tooling, and result so recruiters can verify fit quickly. Example: \"Managed [scope] using [tool/process] to achieve [verified result].\"",
    "Remove or avoid unsupported keyword stuffing; only add skills or achievements that are accurate and can be defended in an interview.",
  ];
}

function rewrittenSummary(
  roleLabel: string,
  strongestKeywords: string[],
  missingKeywords: string[],
): string {
  const evidence =
    strongestKeywords.length > 0
      ? strongestKeywords.join(", ")
      : "[insert strongest CV-supported experience]";
  const gap =
    missingKeywords.length > 0
      ? ` Add truthful evidence for ${missingKeywords.slice(0, 2).join(" and ")} if you have it.`
      : "";

  return `${roleLabel} candidate with CV-supported experience in ${evidence}. Focused on practical outcomes and cross-functional execution; include metrics such as [insert monthly volume], [insert quota attainment], or [insert KPI improvement] only if these facts are present in the CV.${gap}`;
}

function mainReasonsForScore(
  overlap: string[],
  missingKeywords: string[],
  overlapRatio: number,
  criticalMissingCount: number,
): string[] {
  const reasons = [
    overlap.length > 0
      ? `Supported alignment exists for ${overlap.slice(0, 3).join(", ")}.`
      : "The CV has little direct evidence for the role-specific requirements.",
    missingKeywords.length > 0
      ? `The score is penalized for missing evidence around ${missingKeywords.slice(0, 4).join(", ")}.`
      : "The CV covers most detected role-specific requirements.",
    `Keyword coverage is approximately ${Math.round(overlapRatio * 100)}%, but match score is based on evidence quality rather than keywords alone.`,
  ];

  if (criticalMissingCount > 0) {
    reasons.push("Several missing items appear to be recruiter-critical rather than cosmetic keyword gaps.");
  }

  return reasons;
}

function confidenceLevel(
  sectionScore: number,
  jobKeywordCount: number,
): "low" | "medium" | "high" {
  if (sectionScore < 2 || jobKeywordCount < 3) return "low";
  if (sectionScore < 4) return "medium";

  return "high";
}

function recruiterVerdict(matchScore: number, missingKeywords: string[]): string {
  if (matchScore >= 75) {
    return "Likely worth recruiter review, but the CV should still make the strongest evidence easier to find.";
  }

  if (matchScore >= 55) {
    return "Borderline. A recruiter may continue only if the missing requirements are not mandatory.";
  }

  return `Unlikely to be shortlisted without stronger evidence for ${missingKeywords.slice(0, 3).join(", ") || "the core job requirements"}.`;
}

function topThree(items: string[]): string[] {
  const fallback = "Add more concrete, CV-supported evidence for the target role.";
  const uniqueItems = unique(items).slice(0, 3);

  while (uniqueItems.length < 3) {
    uniqueItems.push(fallback);
  }

  return uniqueItems;
}

function rewriteSummary(
  roleLabel: string,
  supportedSkills: string[],
  missingKeywords: string[],
  hasMetrics: boolean,
): string {
  const evidence = supportedSkills.slice(0, 3).join(", ");
  const metricPhrase = hasMetrics
    ? "with measurable outcomes already present in the CV"
    : "with placeholders for measurable outcomes that must be filled truthfully";
  const gapPhrase =
    missingKeywords.length > 0
      ? ` Avoid claiming unsupported requirements such as ${missingKeywords.slice(0, 2).join(" or ")} unless they are true.`
      : "";

  return `${roleLabel} candidate with CV-supported experience in ${evidence}, positioned for the target job ${metricPhrase}.${gapPhrase}`;
}

function rewriteExperienceBullets(
  roleLabel: string,
  supportedSkills: string[],
  hasMetrics: boolean,
): string[] {
  const metricPlaceholder = hasMetrics ? "[insert existing verified metric]" : "[insert measurable result]";
  const primarySkills = supportedSkills.slice(0, 4);

  return primarySkills.map(
    (skill) =>
      `Applied ${skill} in CV-supported work relevant to the ${roleLabel}; clarify scope, action, and outcome with ${metricPlaceholder}.`,
  );
}

function rewriteImprovementNotes(
  roleLabel: string,
  missingKeywords: string[],
  hasMetrics: boolean,
): string[] {
  return [
    `Rewrite the summary for the ${roleLabel} using only the strongest CV-supported evidence and job language that is truthful.`,
    hasMetrics
      ? "Move verified metrics into the most relevant experience bullets so recruiters can see proof quickly."
      : "Add measurable results where possible using placeholders such as [insert measurable result] until the candidate supplies accurate numbers.",
    missingKeywords.length > 0
      ? `Do not add unsupported job requirements as skills; if truthful, add evidence for ${missingKeywords.slice(0, 3).join(", ")} in Experience or Skills.`
      : "Keep skills concise and aligned with the job while avoiding keyword stuffing.",
  ];
}

function rewriteWarnings(missingKeywords: string[], hasMetrics: boolean): string[] {
  const warnings = [
    "Mock rewrite uses extracted CV text only; the candidate must verify every line before applying.",
  ];

  if (!hasMetrics) {
    warnings.push("No clear measurable results were detected, so metric placeholders must be replaced with truthful values.");
  }

  if (missingKeywords.length > 0) {
    warnings.push(
      `The job appears to require unsupported or under-evidenced items: ${missingKeywords.slice(0, 5).join(", ")}.`,
    );
  }

  return warnings;
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
