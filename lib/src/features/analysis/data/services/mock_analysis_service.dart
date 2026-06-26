import '../../domain/models/cv_analysis_request.dart';
import '../../domain/models/cv_analysis_result.dart';
import '../../domain/services/career_analysis_service.dart';
import '../../../cv_upload/domain/models/cv_document.dart';

class MockAnalysisService implements CareerAnalysisService {
  const MockAnalysisService();

  static const _keywordMap = {
    'AI workflows': ['ai', 'assistant', 'automation', 'workflow'],
    'LLM evaluation': ['llm', 'model', 'evaluation', 'quality'],
    'Prompt testing': ['prompt', 'testing'],
    'Product discovery': ['product', 'discovery', 'research'],
    'Roadmap ownership': ['roadmap', 'ownership', 'strategy'],
    'Activation metrics': ['activation', 'retention', 'conversion', 'metrics'],
    'Experiment design': ['experiment', 'hypothesis', 'a/b'],
    'Stakeholder leadership': ['stakeholder', 'leadership', 'cross-functional'],
    'GTM strategy': ['gtm', 'launch', 'go-to-market', 'customer'],
    'Risk controls': ['risk', 'safety', 'governance', 'trust'],
    'Data pipelines': ['data', 'pipeline', 'analytics'],
  };

  @override
  Future<CvAnalysisResult> analyze({
    required CvDocument cvDocument,
    required String jobDescription,
    String locale = 'en',
    String? targetRole,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return buildMockResult(
      CvAnalysisRequest(
        cvFileName: cvDocument.fileName,
        cvFilePath: cvDocument.fileName,
        jobDescription: jobDescription,
        cvText: cvDocument.extractedText,
        isCvValid:
            cvDocument.extractionSucceeded &&
            cvDocument.extractedText.trim().isNotEmpty,
      ),
    );
  }

  CvAnalysisResult buildMockResult(CvAnalysisRequest request) {
    final jobKeywords = _keywordsIn(request.jobDescription);
    final cvKeywords = _keywordsIn(request.cvText ?? '');
    final hasCvContent = request.cvText?.trim().isNotEmpty ?? false;

    if (!request.isCvValid || !hasCvContent) {
      return _lowConfidenceResult(request, jobKeywords);
    }

    final overlap = jobKeywords.intersection(cvKeywords);
    final overlapRatio = jobKeywords.isEmpty
        ? 0.0
        : overlap.length / jobKeywords.length;
    final matchScore = _scoreFor(overlapRatio, jobKeywords.length);
    final atsScore =
        (matchScore - (jobKeywords.length - overlap.length) * 3 + 8).clamp(
          25,
          88,
        );
    final missingKeywords = jobKeywords.difference(cvKeywords).take(6).toList();
    final roleFocus = _roleFocus(jobKeywords);

    return CvAnalysisResult(
      matchScore: matchScore,
      atsScore: atsScore,
      missingKeywords: missingKeywords,
      strongPoints: [
        if (overlap.contains('Product discovery'))
          'Product discovery language appears in both the CV profile and job description.',
        if (overlap.contains('Roadmap ownership'))
          'Roadmap ownership is a clear alignment signal for this role.',
        if (overlap.contains('Stakeholder leadership'))
          'Stakeholder and cross-functional leadership signals are relevant.',
        if (overlap.contains('AI workflows'))
          'AI workflow experience is visible enough for a mock strong signal.',
        if (overlap.isEmpty)
          'The CV file name looks valid, but mock text has limited overlap with this job.',
        'The uploaded file passes the basic CV filename validation.',
      ],
      weakPoints: [
        if (missingKeywords.isNotEmpty)
          'Missing priority terms: ${missingKeywords.take(4).join(', ')}.',
        if (!overlap.contains('LLM evaluation') &&
            jobKeywords.contains('LLM evaluation'))
          'Add concrete examples of model or LLM evaluation work.',
        if (!overlap.contains('Activation metrics') &&
            jobKeywords.contains('Activation metrics'))
          'Quantify activation, retention, or conversion outcomes.',
        'Mock scoring uses extracted PDF text heuristics, so confidence remains limited.',
      ],
      suggestedImprovements: [
        'Rewrite the top summary around $roleFocus and measurable outcomes.',
        'Add two bullets that include scope, action, and a concrete result.',
        'Use matching job keywords naturally where they reflect real experience.',
        'Replace generic responsibility language with evidence of impact.',
      ],
      coverLetter: _coverLetter(
        cvFileName: request.cvFileName,
        roleFocus: roleFocus,
        matchScore: matchScore,
      ),
      interviewQuestions: [
        'Which parts of your CV best prove your fit for this role?',
        'Walk me through a project that connects ${roleFocus.toLowerCase()} to measurable impact.',
        if (jobKeywords.contains('LLM evaluation'))
          'How would you evaluate the quality and trust of an AI assistant workflow?',
        if (jobKeywords.contains('Activation metrics'))
          'Which metrics would you track to decide if this product bet is working?',
        'What would you improve in your CV before applying for this role?',
      ],
    );
  }

  CvAnalysisResult _lowConfidenceResult(
    CvAnalysisRequest request,
    Set<String> jobKeywords,
  ) {
    final missingKeywords = jobKeywords.isEmpty
        ? _keywordMap.keys.take(5).toList()
        : jobKeywords.take(6).toList();

    return CvAnalysisResult(
      matchScore: 29,
      atsScore: 31,
      missingKeywords: missingKeywords,
      strongPoints: const [
        'A PDF file was selected, but the mock parser cannot confirm CV content.',
      ],
      weakPoints: const [
        'Low confidence: the file name or available mock content does not look like a CV.',
        'Readable CV text was not available, so this result should not be treated as a true analysis.',
        'Upload a file named like CV or resume before running a meaningful mock analysis.',
      ],
      suggestedImprovements: const [
        'Upload a valid CV or resume PDF.',
        'Use a clear file name such as Firstname_Lastname_CV.pdf or Firstname_Lastname_Resume.pdf.',
        'Try a text-based CV PDF before using this score for decisions.',
      ],
      coverLetter:
          'A cover letter draft is not reliable because ${request.cvFileName} could not be validated as a CV in mock mode.',
      interviewQuestions: const [
        'Can you confirm this document is a CV or resume?',
        'Which role-specific achievements should be extracted from the CV?',
        'What measurable outcomes should be highlighted once real CV parsing is enabled?',
      ],
    );
  }

  Set<String> _keywordsIn(String text) {
    final normalized = text.toLowerCase();
    final keywords = <String>{};

    for (final entry in _keywordMap.entries) {
      if (entry.value.any(normalized.contains)) {
        keywords.add(entry.key);
      }
    }

    return keywords;
  }

  int _scoreFor(double overlapRatio, int keywordCount) {
    if (keywordCount == 0 || overlapRatio < 0.25) {
      return 25 + (overlapRatio * 80).round().clamp(0, 20);
    }
    if (overlapRatio < 0.58) {
      return 46 + ((overlapRatio - 0.25) * 72).round().clamp(0, 24);
    }
    return 71 + ((overlapRatio - 0.58) * 40).round().clamp(0, 17);
  }

  String _roleFocus(Set<String> keywords) {
    if (keywords.contains('AI workflows') &&
        keywords.contains('Product discovery')) {
      return 'AI product strategy';
    }
    if (keywords.contains('Activation metrics') &&
        keywords.contains('Product discovery')) {
      return 'data-informed product leadership';
    }
    if (keywords.contains('LLM evaluation')) {
      return 'AI quality and trust';
    }
    if (keywords.contains('Roadmap ownership')) {
      return 'product roadmap ownership';
    }
    return 'role-specific product impact';
  }

  String _coverLetter({
    required String cvFileName,
    required String roleFocus,
    required int matchScore,
  }) {
    return 'Dear hiring team,\n\n'
        'I am excited about this opportunity because it connects with my background in $roleFocus. '
        'In mock analysis, $cvFileName shows a $matchScore% alignment signal based on extracted text and keyword overlap.\n\n'
        'I would position my experience around customer discovery, cross-functional execution, and measurable product outcomes while tailoring the CV language to this role.\n\n'
        'Best,\nDerya';
  }
}
