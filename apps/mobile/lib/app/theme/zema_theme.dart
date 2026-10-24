import 'package:flutter/material.dart';

import 'zema_colors.dart';
import 'zema_palette.dart';
import 'zema_typography.dart';

/// Builds the app's dark [ThemeData] for [palette].
///
/// Material widgets read the [ColorScheme]; tokens without a Material slot
/// (`faint`, `soft`, `tile`, `primaryText`, `accentText`, ...) are read from
/// the [ZemaColors] extension via `context.zemaColors`.
ThemeData buildTheme(ZemaPalette palette) {
  final c = palette.colors;
  final colorScheme = ColorScheme.dark(
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.accent,
    onSecondary: c.onPrimary,
    surface: c.bg,
    onSurface: c.text,
    onSurfaceVariant: c.muted,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.surface,
    outline: c.line,
    outlineVariant: c.line,
    shadow: c.shadow,
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.line,
    fontFamily: ZemaTypography.latinFamily,
    fontFamilyFallback: ZemaTypography.fallback,
    textTheme: ZemaTypography.textTheme(text: c.text, muted: c.muted),
    extensions: [c],
  );
}
