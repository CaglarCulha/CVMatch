class AppConfig {
  const AppConfig({required this.analysisApiUrl});

  static const fromEnvironment = AppConfig(
    analysisApiUrl: String.fromEnvironment(
      'CVMATCH_ANALYSIS_API_URL',
      defaultValue: '',
    ),
  );

  final String analysisApiUrl;

  bool get hasAnalysisApi => analysisApiUrl.trim().isNotEmpty;
}
