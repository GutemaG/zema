import 'package:flutter/material.dart';

import 'zema_colors.dart';
import 'zema_palette.dart';
import 'zema_typography.dart';

/// Builds the app's [ThemeData] for [palette] in [brightness].
///
/// Material widgets read the [ColorScheme]; tokens without a Material slot
/// (`faint`, `soft`, `tile`, `primaryText`, `accentText`, ...) are read from
/// the [ZemaColors] extension via `context.zemaColors`.
ThemeData buildTheme(ZemaPalette palette, Brightness brightness) {
  final c = palette.colorsFor(brightness);
  final scheme = brightness == Brightness.dark
      ? ColorScheme.dark
      : ColorScheme.light;
  final colorScheme = scheme(
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
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.line,
    fontFamily: ZemaTypography.latinFamily,
    fontFamilyFallback: ZemaTypography.fallback,
    textTheme: ZemaTypography.textTheme(text: c.text, muted: c.muted),
    // No Material 3 tint when content scrolls under the bar; gold is reserved
    // for one thing per area.
    appBarTheme: AppBarTheme(
      // Titles sit next to the back button on both platforms, as designed.
      centerTitle: false,
      backgroundColor: c.bg,
      foregroundColor: c.text,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.line,
    ),
    extensions: [c],
  );
}
