import 'package:flutter/material.dart';

/// Fonts and text sizes from the typography table in `docs/design-system.md`.
///
/// Both families are bundled in `assets/fonts/` and never fetched at runtime.
abstract final class ZemaTypography {
  /// Latin UI text.
  static const String latinFamily = 'Inter';

  /// Ge'ez script. Used as the fallback after [latinFamily], so mixed Latin
  /// and Ethiopic text renders in one style.
  static const String ethiopicFamily = 'NotoSansEthiopic';

  static const List<String> fallback = [ethiopicFamily];

  /// Ethiopic glyphs are tall; the design system forbids line height below
  /// 1.4. Every style in [textTheme] uses at least this.
  static const double ethiopicLineHeight = 1.5;

  /// Builds the app text theme. Colors come from the palette so text is
  /// readable on `bg` and `surface`.
  static TextTheme textTheme({required Color text, required Color muted}) {
    TextStyle style(
      double size,
      FontWeight weight, {
      Color? color,
      double height = ethiopicLineHeight,
    }) {
      return TextStyle(
        fontFamily: latinFamily,
        fontFamilyFallback: fallback,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? text,
      );
    }

    // Every Material slot is set, so none falls back to a default style
    // without the Ethiopic line height.
    return TextTheme(
      // Larger than any designed screen; kept in proportion for completeness.
      displayLarge: style(36, FontWeight.w700, height: 1.4),
      displayMedium: style(33, FontWeight.w700, height: 1.4),
      // Screen titles: 24–30 / 700.
      displaySmall: style(30, FontWeight.w700, height: 1.4),
      headlineLarge: style(30, FontWeight.w700, height: 1.4),
      headlineMedium: style(28, FontWeight.w700, height: 1.4),
      headlineSmall: style(24, FontWeight.w700, height: 1.4),
      // Song titles in lists: 16 / 600.
      titleLarge: style(20, FontWeight.w600),
      titleMedium: style(16, FontWeight.w600),
      titleSmall: style(14, FontWeight.w600),
      // UI text: 13–16 / 400–600.
      bodyLarge: style(16, FontWeight.w400),
      bodyMedium: style(14, FontWeight.w400),
      bodySmall: style(13, FontWeight.w400, color: muted),
      // Labels and badges: 11–12 / 600–700.
      labelLarge: style(14, FontWeight.w600),
      labelMedium: style(12, FontWeight.w600),
      labelSmall: style(11, FontWeight.w700),
    );
  }
}
