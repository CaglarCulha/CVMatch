export type CvRewriteRequest = {
  cvText: string;
  jobDescription: string;
  targetRole?: string | undefined;
  locale: string;
};

export type CvRewriteResult = {
  rewrittenSummary: string;
  rewrittenExperienceBullets: string[];
  rewrittenSkills: string[];
  improvementNotes: string[];
  warnings: string[];
};

export interface CvRewriteService {
  rewrite(request: CvRewriteRequest): Promise<CvRewriteResult>;
}
