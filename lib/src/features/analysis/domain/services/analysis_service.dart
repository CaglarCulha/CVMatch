import '../models/cv_analysis_request.dart';
import '../models/cv_analysis_result.dart';

abstract class AnalysisService {
  Future<CvAnalysisResult> analyze(CvAnalysisRequest request);
}
