import 'dart:ui' show Brightness;

import 'zema_colors.dart';

/// The approved palettes the user can pick in Settings. Each has a dark and a
/// light version; which one is used depends on the theme mode.
enum ZemaPalette {
  nightVigil(dark: ZemaColors.nightVigil, light: ZemaColors.nightVigilLight),
  wine(dark: ZemaColors.wine, light: ZemaColors.wineLight);

  const ZemaPalette({required this.dark, required this.light});

  /// Used when no palette has been saved yet.
  static const ZemaPalette fallback = ZemaPalette.nightVigil;

  final ZemaColors dark;
  final ZemaColors light;

  ZemaColors colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
