export type AnalyzeRequest = {
  cvText: string;
  cvFileName: string;
  jobDescription: string;
  locale: string;
  targetRole?: string | undefined;
};

export type CvAnalysisResult = {
  matchScore: number;
  atsScore: number;
  keywordCoverage?: number | undefined;
  missingKeywords: string[];
  strengths?: string[] | undefined;
  weaknesses?: string[] | undefined;
  improvements?: string[] | undefined;
  rewrittenSummary?: string | undefined;
  mainReasonsForScore?: string[] | undefined;
  confidenceLevel?: "low" | "medium" | "high" | undefined;
  recruiterVerdict?: string | undefined;
  rejectionRisks?: string[] | undefined;
  fastestFixes?: string[] | undefined;
  strongPoints: string[];
  weakPoints: string[];
  suggestedImprovements: string[];
  coverLetter: string;
  interviewQuestions: string[];
};

export interface CareerAnalysisService {
  analyze(request: AnalyzeRequest): Promise<CvAnalysisResult>;
}
