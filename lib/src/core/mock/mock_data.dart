class CandidateProfile {
  const CandidateProfile({
    required this.name,
    required this.currentRole,
    required this.targetRole,
    required this.location,
    required this.resumeFileName,
    required this.matchScore,
    required this.summary,
  });

  final String name;
  final String currentRole;
  final String targetRole;
  final String location;
  final String resumeFileName;
  final int matchScore;
  final String summary;
}

class MatchMetric {
  const MatchMetric({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final int value;
  final String detail;
}

class InsightItem {
  const InsightItem({required this.title, required this.description});

  final String title;
  final String description;
}

const mockCandidate = CandidateProfile(
  name: 'Derya Kaya',
  currentRole: 'Product Designer',
  targetRole: 'AI Product Manager',
  location: 'Istanbul, Turkey',
  resumeFileName: 'Derya_Kaya_CV.pdf',
  matchScore: 84,
  summary:
      'Strong product discovery background with clear signals in AI workflows, stakeholder leadership, and roadmap ownership.',
);

const mockJobTitle = 'Senior AI Product Manager';

const mockJobCompany = 'Northstar Labs';

const mockJobDescription = '''
Northstar Labs is hiring a Senior AI Product Manager to lead discovery, define model-powered workflows, and partner with engineering, design, and GTM teams.

Responsibilities:
- Own product strategy for AI assistant experiences.
- Translate customer problems into roadmap bets and measurable releases.
- Partner with ML engineers to evaluate quality, latency, and trust.
- Create crisp launch narratives for executive and customer audiences.

Requirements:
- 5+ years in product management or product design.
- Experience with AI, automation, or data-heavy SaaS products.
- Strong user research, prioritization, and storytelling skills.
- Comfort with metrics, experiments, and cross-functional leadership.
''';

const mockMetrics = [
  MatchMetric(
    label: 'Role Alignment',
    value: 91,
    detail: 'Your discovery and roadmap experience map cleanly to the role.',
  ),
  MatchMetric(
    label: 'AI Signals',
    value: 78,
    detail: 'Strong workflow framing; add more model evaluation examples.',
  ),
  MatchMetric(
    label: 'Leadership',
    value: 86,
    detail: 'Good cross-functional language with measurable launch outcomes.',
  ),
];

const mockAtsScore = 76;

const mockMissingKeywords = [
  'LLM evaluation',
  'Prompt testing',
  'Activation metrics',
  'Data pipelines',
  'Risk controls',
  'Experiment design',
];

const mockPreviousAnalyses = [
  'AI Product Manager - Northstar Labs',
  'Product Lead, Automation - StudioWorks',
  'Senior PM, Data Products - Meridian',
];

const mockStrengths = [
  InsightItem(
    title: 'Product narrative',
    description: 'Your CV shows crisp problem framing and launch ownership.',
  ),
  InsightItem(
    title: 'Customer discovery',
    description: 'Research and synthesis examples match the JD priorities.',
  ),
  InsightItem(
    title: 'Design fluency',
    description: 'A design background gives you leverage in assistant UX.',
  ),
];

const mockGaps = [
  InsightItem(
    title: 'Model quality metrics',
    description: 'Add one bullet about evaluating AI outputs or user trust.',
  ),
  InsightItem(
    title: 'Commercial impact',
    description: 'Quantify activation, retention, revenue, or cycle time wins.',
  ),
  InsightItem(
    title: 'Technical partnership',
    description: 'Name how you worked with ML, data, or platform teams.',
  ),
];

const mockActionPlan = [
  InsightItem(
    title: 'Rewrite the top summary',
    description:
        'Lead with AI product strategy, discovery, and measurable launches.',
  ),
  InsightItem(
    title: 'Add two proof bullets',
    description:
        'Show one AI workflow result and one experiment with a clear metric.',
  ),
  InsightItem(
    title: 'Tailor keywords',
    description:
        'Use roadmap, model evaluation, trust, automation, and GTM language.',
  ),
];

const mockRecommendedRoles = [
  'AI Product Manager',
  'Product Lead, Automation',
  'Conversational UX Product Manager',
  'Data Product Manager',
];
