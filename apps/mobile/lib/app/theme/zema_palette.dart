import 'zema_colors.dart';

/// The approved palettes the user can pick in Settings. Both are dark.
enum ZemaPalette {
  nightVigil(ZemaColors.nightVigil),
  wine(ZemaColors.wine);

  const ZemaPalette(this.colors);

  /// Used when no palette has been saved yet.
  static const ZemaPalette fallback = ZemaPalette.nightVigil;

  final ZemaColors colors;
}
