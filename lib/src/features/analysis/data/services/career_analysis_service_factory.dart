import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../domain/services/career_analysis_service.dart';
import 'api_career_analysis_service.dart';
import 'mock_analysis_service.dart';

class CareerAnalysisServiceFactory {
  const CareerAnalysisServiceFactory._();

  static CareerAnalysisService create(AppConfig config, {http.Client? client}) {
    if (!config.hasAnalysisApi) {
      return const MockAnalysisService();
    }

    return ApiCareerAnalysisService(
      backendUrl: config.analysisApiUrl,
      client: client,
    );
  }
}
