import 'package:flutter/material.dart';

/// The app's default dark palette, "Night Vigil" (see
/// `apps/mobile/lib/app/theme/zema_colors.dart`).
abstract final class AdminColors {
  static const bg = Color(0xFF110D0B);
  static const surface = Color(0xFF1C1613);
  static const line = Color(0xFF2F2622);
  static const text = Color(0xFFF2E8D7);
  static const muted = Color(0xFFA39586);
  static const primary = Color(0xFFE3AE4A);
  static const soft = Color(0xFF3A2B17);
}

ThemeData buildAdminTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AdminColors.primary,
      onPrimary: AdminColors.bg,
      secondary: AdminColors.primary,
      onSecondary: AdminColors.bg,
      surface: AdminColors.bg,
      onSurface: AdminColors.text,
      onSurfaceVariant: AdminColors.muted,
      surfaceContainerLowest: AdminColors.bg,
      surfaceContainerLow: AdminColors.surface,
      surfaceContainer: AdminColors.surface,
      surfaceContainerHigh: AdminColors.surface,
      surfaceContainerHighest: AdminColors.surface,
      secondaryContainer: AdminColors.soft,
      outline: AdminColors.line,
      outlineVariant: AdminColors.line,
    ),
    scaffoldBackgroundColor: AdminColors.bg,
    dividerColor: AdminColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: AdminColors.bg,
      foregroundColor: AdminColors.text,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
