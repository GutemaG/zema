import 'package:flutter/material.dart';

import '../../../app/theme/zema_palette.dart';

/// The option C05 preselects.
enum SleepTimerDefault {
  none(null),
  minutes15(15),
  minutes30(30),
  minutes45(45),
  minutes60(60),
  endOfSong(null);

  const SleepTimerDefault(this.minutes);

  /// The preset's length, or null for [none] and [endOfSong].
  final int? minutes;
}

/// The user's saved preferences.
@immutable
class AppSettings {
  const AppSettings({
    this.palette = ZemaPalette.fallback,
    this.themeMode = ThemeMode.system,
    this.languageCode,
    this.minTrackSeconds = defaultMinTrackSeconds,
    this.sleepTimerDefault = SleepTimerDefault.none,
    this.pauseOnUnplug = true,
    this.duckOnInterruption = false,
    this.gapless = true,
    this.floatLyrics = true,
  });

  /// The choices for [minTrackSeconds]; 0 is off.
  static const minTrackChoices = [0, 10, 30, 60];
  static const defaultMinTrackSeconds = 30;

  final ZemaPalette palette;

  /// Light, dark, or follow the phone (the default).
  final ThemeMode themeMode;

  /// Language picked in Settings, or `null` if never picked (follow the
  /// device). Not validated here; `resolveInitialLanguage` ignores unknown
  /// codes.
  final String? languageCode;

  /// Audio shorter than this many seconds is left out of the library
  /// (voice notes, sounds); 0 keeps everything.
  final int minTrackSeconds;

  final SleepTimerDefault sleepTimerDefault;

  /// Pause when headphones are unplugged.
  final bool pauseOnUnplug;

  /// When another app plays a short sound: lower the volume (true) or pause
  /// (false). Calls always pause.
  final bool duckOnInterruption;
  final bool gapless;

  /// Android: the lyrics of a song playing in Zema float over other apps
  /// when the user leaves Zema.
  final bool floatLyrics;

  Duration get minTrackDuration => Duration(seconds: minTrackSeconds);

  AppSettings copyWith({
    ZemaPalette? palette,
    ThemeMode? themeMode,
    String? languageCode,
    int? minTrackSeconds,
    SleepTimerDefault? sleepTimerDefault,
    bool? pauseOnUnplug,
    bool? duckOnInterruption,
    bool? gapless,
    bool? floatLyrics,
  }) {
    return AppSettings(
      palette: palette ?? this.palette,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      minTrackSeconds: minTrackSeconds ?? this.minTrackSeconds,
      sleepTimerDefault: sleepTimerDefault ?? this.sleepTimerDefault,
      pauseOnUnplug: pauseOnUnplug ?? this.pauseOnUnplug,
      duckOnInterruption: duckOnInterruption ?? this.duckOnInterruption,
      gapless: gapless ?? this.gapless,
      floatLyrics: floatLyrics ?? this.floatLyrics,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.palette == palette &&
      other.themeMode == themeMode &&
      other.languageCode == languageCode &&
      other.minTrackSeconds == minTrackSeconds &&
      other.sleepTimerDefault == sleepTimerDefault &&
      other.pauseOnUnplug == pauseOnUnplug &&
      other.duckOnInterruption == duckOnInterruption &&
      other.gapless == gapless &&
      other.floatLyrics == floatLyrics;

  @override
  int get hashCode => Object.hash(
    palette,
    themeMode,
    languageCode,
    minTrackSeconds,
    sleepTimerDefault,
    pauseOnUnplug,
    duckOnInterruption,
    gapless,
    floatLyrics,
  );

  @override
  String toString() =>
      'AppSettings(palette: ${palette.name}, themeMode: ${themeMode.name}, '
      'languageCode: $languageCode, minTrackSeconds: $minTrackSeconds, '
      'sleepTimerDefault: ${sleepTimerDefault.name}, '
      'pauseOnUnplug: $pauseOnUnplug, '
      'duckOnInterruption: $duckOnInterruption, gapless: $gapless, '
      'floatLyrics: $floatLyrics)';
}
