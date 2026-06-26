import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _lightPrimary = Color(0xFF2563EB);
  static const _lightSecondary = Color(0xFF4F46E5);
  static const _lightTertiary = Color(0xFF0EA5E9);
  static const _darkPrimary = Color(0xFF93C5FD);
  static const _darkSecondary = Color(0xFFA5B4FC);
  static const _darkTertiary = Color(0xFF67E8F9);

  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    primary: _lightPrimary,
    secondary: _lightSecondary,
    tertiary: _lightTertiary,
    scaffold: const Color(0xFFF6F8FC),
    surface: Colors.white,
    surfaceContainer: const Color(0xFFEFF4FF),
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    primary: _darkPrimary,
    secondary: _darkSecondary,
    tertiary: _darkTertiary,
    scaffold: const Color(0xFF080C17),
    surface: const Color(0xFF111827),
    surfaceContainer: const Color(0xFF172033),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color tertiary,
    required Color scaffold,
    required Color surface,
    required Color surfaceContainer,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,
          surface: surface,
          surfaceContainerHighest: surfaceContainer,
          outline: isDark ? const Color(0xFF334155) : const Color(0xFFD7DEEA),
          outlineVariant: isDark
              ? const Color(0xFF1F2937)
              : const Color(0xFFE4EAF4),
        );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
    );

    final textTheme = baseTheme.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return baseTheme.copyWith(
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1,
        shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          selectedBackgroundColor: primary.withValues(
            alpha: isDark ? 0.22 : 0.12,
          ),
          selectedForegroundColor: isDark ? Colors.white : primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
