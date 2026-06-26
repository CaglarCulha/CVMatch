import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../cv_upload/domain/models/cv_document.dart';
import '../../domain/models/cv_analysis_result.dart';
import '../../domain/services/career_analysis_service.dart';

class ApiCareerAnalysisService implements CareerAnalysisService {
  ApiCareerAnalysisService({
    required String backendUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 45),
  }) : _backendUrl = backendUrl.trim(),
       _client = client ?? http.Client();

  final String _backendUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<CvAnalysisResult> analyze({
    required CvDocument cvDocument,
    required String jobDescription,
    String locale = 'en',
    String? targetRole,
  }) async {
    final endpoint = _endpointUri();
    final body = <String, Object>{
      'cvText': cvDocument.extractedText,
      'cvFileName': cvDocument.fileName,
      'jobDescription': jobDescription,
      'locale': locale,
      if (targetRole?.trim().isNotEmpty ?? false)
        'targetRole': targetRole!.trim(),
    };

    try {
      final response = await _client
          .post(
            endpoint,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CareerAnalysisException(_apiErrorMessage(response));
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }

      final apiError = _apiErrorFromJson(decoded);
      if (apiError != null && !decoded.containsKey('matchScore')) {
        throw CareerAnalysisException(apiError);
      }

      return CvAnalysisResult.fromJson(decoded);
    } on TimeoutException {
      throw const CareerAnalysisException(
        'Analysis is taking longer than expected. Please try again.',
      );
    } on CareerAnalysisException {
      rethrow;
    } on FormatException {
      throw const CareerAnalysisException(
        'The analysis response was not valid. Please try again.',
      );
    } on http.ClientException {
      throw const CareerAnalysisException(
        'Network error. Please check your connection and try again.',
      );
    } catch (_) {
      throw const CareerAnalysisException(
        'Could not analyze your CV right now. Please try again.',
      );
    }
  }

  Uri _endpointUri() {
    if (_backendUrl.isEmpty) {
      throw const CareerAnalysisException(
        'Analysis API is not configured. Mock analysis is available instead.',
      );
    }

    final uri = Uri.tryParse(_backendUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const CareerAnalysisException(
        'Analysis API URL is not configured correctly.',
      );
    }

    return uri;
  }

  String _apiErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final message = _apiErrorFromJson(decoded);
        if (message != null) {
          return message;
        }
      }
    } catch (_) {
      // Keep the UI friendly when the backend returns non-JSON error content.
    }

    return 'Analysis API returned an error. Please try again.';
  }

  String? _apiErrorFromJson(Map<String, dynamic> json) {
    final message = json['error'] ?? json['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return null;
  }
}
