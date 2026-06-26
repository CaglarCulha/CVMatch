import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_routes.dart';
import 'cvmatch_state.dart';

class CVMatchApp extends StatefulWidget {
  const CVMatchApp({super.key});

  @override
  State<CVMatchApp> createState() => _CVMatchAppState();
}

class _CVMatchAppState extends State<CVMatchApp> {
  final _state = CVMatchState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CVMatchScope(
      state: _state,
      child: MaterialApp(
        title: 'CVMatch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
