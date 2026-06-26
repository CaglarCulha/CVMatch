import 'package:flutter/material.dart';

import '../features/analysis/presentation/analysis_result_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/cv_upload/presentation/upload_cv_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/job_description/presentation/job_description_screen.dart';
import '../features/paywall/presentation/paywall_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const login = '/';
  static const home = '/home';
  static const uploadCV = '/upload-cv';
  static const jobDescription = '/job-description';
  static const analysisResult = '/analysis-result';
  static const paywall = '/paywall';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final screen = switch (settings.name) {
      login => const LoginScreen(),
      home => const HomeScreen(),
      uploadCV => const UploadCVScreen(),
      jobDescription => const JobDescriptionScreen(),
      analysisResult => const AnalysisResultScreen(),
      paywall => const PaywallScreen(),
      _ => const LoginScreen(),
    };

    return MaterialPageRoute(builder: (_) => screen, settings: settings);
  }
}
