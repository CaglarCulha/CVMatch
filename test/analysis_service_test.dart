import 'package:cvmatch/src/features/analysis/data/services/mock_analysis_service.dart';
import 'package:cvmatch/src/features/analysis/domain/models/cv_analysis_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = MockAnalysisService();

  test('returns low confidence scores when CV validation fails', () {
    final result = service.buildMockResult(
      const CvAnalysisRequest(
        cvFileName: 'invoice.pdf',
        cvFilePath: '/private/invoice.pdf',
        jobDescription:
            'We need an AI product manager with roadmap ownership, prompt testing, model evaluation, and activation metrics experience.',
        isCvValid: false,
      ),
    );

    expect(result.matchScore, inInclusiveRange(25, 45));
    expect(result.atsScore, inInclusiveRange(25, 45));
    expect(result.weakPoints.join(' '), contains('Low confidence'));
  });

  test('keeps strong mock scores below 90', () {
    final result = service.buildMockResult(
      const CvAnalysisRequest(
        cvFileName: 'Derya_Kaya_CV.pdf',
        cvFilePath: '/private/Derya_Kaya_CV.pdf',
        jobDescription:
            'Hiring an AI product leader for product discovery, roadmap ownership, activation metrics, prompt testing, model evaluation, stakeholder leadership, GTM launch, trust, and data analytics.',
        cvText:
            'Product discovery roadmap ownership activation metrics prompt testing model evaluation stakeholder leadership GTM launch trust data analytics AI workflows.',
      ),
    );

    expect(result.matchScore, inInclusiveRange(71, 88));
    expect(result.atsScore, lessThanOrEqualTo(88));
  });

  test('uses keyword overlap to return weak match scores', () {
    final result = service.buildMockResult(
      const CvAnalysisRequest(
        cvFileName: 'Derya_Kaya_CV.pdf',
        cvFilePath: '/private/Derya_Kaya_CV.pdf',
        jobDescription:
            'Hiring for data pipelines, risk controls, model evaluation, activation metrics, and experiment design.',
        cvText: 'Customer discovery and roadmap planning for SaaS features.',
      ),
    );

    expect(result.matchScore, inInclusiveRange(25, 45));
  });
}
