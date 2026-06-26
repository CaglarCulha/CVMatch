import '../../../cv_upload/domain/models/cv_document.dart';
import '../models/cv_analysis_result.dart';

abstract class CareerAnalysisService {
  Future<CvAnalysisResult> analyze({
    required CvDocument cvDocument,
    required String jobDescription,
    String locale = 'en',
    String? targetRole,
  });
}

class CareerAnalysisException implements Exception {
  const CareerAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}
