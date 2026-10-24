import 'package:flutter/material.dart';

import '../../../app/theme/zema_palette.dart';

/// The user's saved preferences.
@immutable
class AppSettings {
  const AppSettings({
    this.palette = ZemaPalette.fallback,
    this.themeMode = ThemeMode.system,
    this.languageCode,
  });

  final ZemaPalette palette;

  /// Light, dark, or follow the phone (the default).
  final ThemeMode themeMode;

  /// Language picked in Settings, or `null` if never picked (follow the
  /// device). Not validated here; `resolveInitialLanguage` ignores unknown
  /// codes.
  final String? languageCode;

  AppSettings copyWith({
    ZemaPalette? palette,
    ThemeMode? themeMode,
    String? languageCode,
  }) {
    return AppSettings(
      palette: palette ?? this.palette,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.palette == palette &&
      other.themeMode == themeMode &&
      other.languageCode == languageCode;

  @override
  int get hashCode => Object.hash(palette, themeMode, languageCode);

  @override
  String toString() =>
      'AppSettings(palette: ${palette.name}, themeMode: ${themeMode.name}, '
      'languageCode: $languageCode)';
}
