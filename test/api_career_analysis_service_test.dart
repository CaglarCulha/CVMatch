import 'dart:convert';

import 'package:cvmatch/src/features/analysis/data/services/api_career_analysis_service.dart';
import 'package:cvmatch/src/features/analysis/domain/services/career_analysis_service.dart';
import 'package:cvmatch/src/features/cv_upload/domain/models/cv_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const cvDocument = CvDocument(
    fileName: 'Derya_Kaya_CV.pdf',
    fileSize: 2048,
    extractedText:
        'Product discovery, roadmap ownership, prompt testing, and AI workflows.',
    pageCount: 2,
    extractionSucceeded: true,
  );

  test('posts CV text and parses a valid analysis response', () async {
    late Map<String, dynamic> requestBody;
    final service = ApiCareerAnalysisService(
      backendUrl: 'https://api.example.com/analyze',
      client: MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'matchScore': 78,
            'atsScore': 74,
            'missingKeywords': ['Activation metrics'],
            'strongPoints': ['Roadmap ownership is clear.'],
            'weakPoints': ['Add more quantified outcomes.'],
            'suggestedImprovements': ['Add measurable product impact.'],
            'coverLetter': 'Dear hiring team...',
            'interviewQuestions': ['Tell me about an AI workflow.'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.analyze(
      cvDocument: cvDocument,
      jobDescription:
          'We need an AI product manager with roadmap ownership and prompt testing experience.',
      locale: 'en-US',
      targetRole: 'AI Product Manager',
    );

    expect(requestBody['cvText'], cvDocument.extractedText);
    expect(requestBody['cvFileName'], cvDocument.fileName);
    expect(requestBody['locale'], 'en-US');
    expect(requestBody['targetRole'], 'AI Product Manager');
    expect(result.matchScore, 78);
    expect(result.missingKeywords, contains('Activation metrics'));
  });

  test('throws a friendly exception for invalid JSON', () async {
    final service = ApiCareerAnalysisService(
      backendUrl: 'https://api.example.com/analyze',
      client: MockClient((request) async => http.Response('not-json', 200)),
    );

    expect(
      () => service.analyze(
        cvDocument: cvDocument,
        jobDescription: 'A valid long job description for product work.',
      ),
      throwsA(isA<CareerAnalysisException>()),
    );
  });

  test(
    'throws a friendly exception when required fields are missing',
    () async {
      final service = ApiCareerAnalysisService(
        backendUrl: 'https://api.example.com/analyze',
        client: MockClient(
          (request) async => http.Response(jsonEncode({'matchScore': 72}), 200),
        ),
      );

      expect(
        () => service.analyze(
          cvDocument: cvDocument,
          jobDescription: 'A valid long job description for product work.',
        ),
        throwsA(isA<CareerAnalysisException>()),
      );
    },
  );

  test('surfaces backend error messages', () async {
    final service = ApiCareerAnalysisService(
      backendUrl: 'https://api.example.com/analyze',
      client: MockClient(
        (request) async =>
            http.Response(jsonEncode({'error': 'Backend unavailable'}), 503),
      ),
    );

    expect(
      () => service.analyze(
        cvDocument: cvDocument,
        jobDescription: 'A valid long job description for product work.',
      ),
      throwsA(
        isA<CareerAnalysisException>().having(
          (error) => error.message,
          'message',
          'Backend unavailable',
        ),
      ),
    );
  });

  test('surfaces successful-status API error payloads', () async {
    final service = ApiCareerAnalysisService(
      backendUrl: 'https://api.example.com/analyze',
      client: MockClient(
        (request) async =>
            http.Response(jsonEncode({'message': 'Model quota exceeded'}), 200),
      ),
    );

    expect(
      () => service.analyze(
        cvDocument: cvDocument,
        jobDescription: 'A valid long job description for product work.',
      ),
      throwsA(
        isA<CareerAnalysisException>().having(
          (error) => error.message,
          'message',
          'Model quota exceeded',
        ),
      ),
    );
  });
}
