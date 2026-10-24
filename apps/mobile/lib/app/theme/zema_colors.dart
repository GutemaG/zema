import 'package:flutter/material.dart';

/// Design tokens from `docs/design-system.md`, carried on [ThemeData] as an
/// extension. Token names match the design canvas as-is.
///
/// Read them with `context.zemaColors`. Never write `Color(0x…)` literals
/// outside `lib/app/theme/`; a test enforces this.
@immutable
class ZemaColors extends ThemeExtension<ZemaColors> {
  const ZemaColors({
    required this.bg,
    required this.surface,
    required this.line,
    required this.text,
    required this.muted,
    required this.faint,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.accent,
    required this.accentText,
    required this.soft,
    required this.tile,
    required this.tileFg,
    required this.shadow,
  });

  /// Default palette.
  static const ZemaColors nightVigil = ZemaColors(
    bg: Color(0xFF110D0B),
    surface: Color(0xFF1C1613),
    line: Color(0xFF2F2622),
    text: Color(0xFFF2E8D7),
    muted: Color(0xFFA39586),
    faint: Color(0xFF7D7065),
    primary: Color(0xFFE3AE4A),
    onPrimary: Color(0xFF110D0B),
    primaryText: Color(0xFFFFF4E0),
    accent: Color(0xFFE3AE4A),
    accentText: Color(0xFFE3AE4A),
    soft: Color(0xFF3A2B17),
    tile: Color(0xFF2A1E19),
    tileFg: Color(0xFFE3AE4A),
    shadow: Color(0x80000000),
  );

  /// Alternative palette, "Night Vigil · Wine".
  static const ZemaColors wine = ZemaColors(
    bg: Color(0xFF15090D),
    surface: Color(0xFF22121A),
    line: Color(0xFF3A2029),
    text: Color(0xFFF4E7DD),
    muted: Color(0xFFB3989A),
    faint: Color(0xFF876C6F),
    primary: Color(0xFFD9A441),
    onPrimary: Color(0xFF15090D),
    primaryText: Color(0xFFFFF1E2),
    accent: Color(0xFFD9A441),
    accentText: Color(0xFFE2B45B),
    soft: Color(0xFF3B2418),
    tile: Color(0xFF2C141C),
    tileFg: Color(0xFFD9A441),
    shadow: Color(0x80000000),
  );

  /// Light version of Night Vigil. Draft values (2026-10-24) until a design
  /// pass; see `docs/design-system.md`.
  static const ZemaColors nightVigilLight = ZemaColors(
    bg: Color(0xFFFAF6EE),
    surface: Color(0xFFFFFDF8),
    line: Color(0xFFE6DCCB),
    text: Color(0xFF1F1712),
    muted: Color(0xFF6B5D50),
    faint: Color(0xFF958676),
    primary: Color(0xFFE3AE4A),
    onPrimary: Color(0xFF1F1712),
    primaryText: Color(0xFF120C08),
    accent: Color(0xFFA87420),
    accentText: Color(0xFF87570A),
    soft: Color(0xFFF5E6C8),
    tile: Color(0xFFF0E5D3),
    tileFg: Color(0xFF87570A),
    shadow: Color(0x1F000000),
  );

  /// Light version of Wine. Draft values (2026-10-24) until a design pass.
  static const ZemaColors wineLight = ZemaColors(
    bg: Color(0xFFFAF3F2),
    surface: Color(0xFFFFFCFB),
    line: Color(0xFFEAD9D8),
    text: Color(0xFF24141A),
    muted: Color(0xFF735C60),
    faint: Color(0xFF9C8689),
    primary: Color(0xFFD9A441),
    onPrimary: Color(0xFF24141A),
    primaryText: Color(0xFF170A0F),
    accent: Color(0xFFA06C24),
    accentText: Color(0xFF85540C),
    soft: Color(0xFFF5E3CF),
    tile: Color(0xFFF2E1E1),
    tileFg: Color(0xFF85540C),
    shadow: Color(0x1F000000),
  );

  /// Screen background.
  final Color bg;

  /// Cards, inputs, sheets, mini player.
  final Color surface;

  /// Borders, dividers, inactive progress.
  final Color line;

  /// Primary text.
  final Color text;

  /// Secondary text, inactive icons.
  final Color muted;

  /// Lyrics already sung (dimmed). Only for text at 17px or larger.
  final Color faint;

  /// Main buttons, active states, progress.
  final Color primary;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// Current lyric line, active nav item.
  final Color primaryText;

  /// Chorus markers, highlights, borders of the active line.
  final Color accent;

  /// Accent-colored text (badges, links, timestamps).
  final Color accentText;

  /// Badge and tip backgrounds ("Synced", chorus chips).
  final Color soft;

  /// Album-art placeholder tile.
  final Color tile;

  /// Letter on the placeholder tile.
  final Color tileFg;

  /// Shadows.
  final Color shadow;

  @override
  ZemaColors copyWith({
    Color? bg,
    Color? surface,
    Color? line,
    Color? text,
    Color? muted,
    Color? faint,
    Color? primary,
    Color? onPrimary,
    Color? primaryText,
    Color? accent,
    Color? accentText,
    Color? soft,
    Color? tile,
    Color? tileFg,
    Color? shadow,
  }) {
    return ZemaColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      line: line ?? this.line,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryText: primaryText ?? this.primaryText,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      soft: soft ?? this.soft,
      tile: tile ?? this.tile,
      tileFg: tileFg ?? this.tileFg,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  ZemaColors lerp(ZemaColors? other, double t) {
    if (other == null) {
      return this;
    }
    return ZemaColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      tile: Color.lerp(tile, other.tile, t)!,
      tileFg: Color.lerp(tileFg, other.tileFg, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Shortcut for reading the design tokens from the current theme.
extension ZemaColorsContext on BuildContext {
  ZemaColors get zemaColors {
    final colors = Theme.of(this).extension<ZemaColors>();
    assert(
      colors != null,
      'ZemaColors not found in the theme. Wrap the widget in ZemaApp, or in a '
      'Theme built with buildTheme(), before reading context.zemaColors.',
    );
    return colors!;
  }
}
