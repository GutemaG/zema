import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/preferences_provider.dart';

/// How the lyrics view shows lines, remembered across restarts.
class LyricsDisplay {
  const LyricsDisplay({this.showTransliteration = false, this.textScale = 1});

  static const double minScale = 0.8;
  static const double maxScale = 1.6;
  static const double scaleStep = 0.1;

  /// Whether each line's transliteration shows below it.
  final bool showTransliteration;

  /// Size of the lyrics text, on top of the phone's text size.
  final double textScale;

  bool get canShrink => textScale > minScale + 0.001;
  bool get canGrow => textScale < maxScale - 0.001;

  LyricsDisplay copyWith({bool? showTransliteration, double? textScale}) =>
      LyricsDisplay(
        showTransliteration: showTransliteration ?? this.showTransliteration,
        textScale: textScale ?? this.textScale,
      );

  @override
  bool operator ==(Object other) =>
      other is LyricsDisplay &&
      other.showTransliteration == showTransliteration &&
      other.textScale == textScale;

  @override
  int get hashCode => Object.hash(showTransliteration, textScale);
}

final lyricsDisplayProvider =
    NotifierProvider<LyricsDisplayController, LyricsDisplay>(
      LyricsDisplayController.new,
    );

class LyricsDisplayController extends Notifier<LyricsDisplay> {
  static const transliterationKey = 'lyricsTransliteration';
  static const scaleKey = 'lyricsTextScale';

  @override
  LyricsDisplay build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return LyricsDisplay(
      showTransliteration: prefs.getBool(transliterationKey) ?? false,
      textScale: _clampScale(prefs.getDouble(scaleKey) ?? 1),
    );
  }

  Future<void> setTransliteration({required bool show}) async {
    state = state.copyWith(showTransliteration: show);
    await ref.read(sharedPreferencesProvider).setBool(transliterationKey, show);
  }

  /// One [LyricsDisplay.scaleStep] larger ([steps] > 0) or smaller.
  Future<void> stepScale(int steps) async {
    final scale = _clampScale(
      state.textScale + steps * LyricsDisplay.scaleStep,
    );
    if (scale == state.textScale) return;
    state = state.copyWith(textScale: scale);
    await ref.read(sharedPreferencesProvider).setDouble(scaleKey, scale);
  }

  static double _clampScale(double scale) =>
      // Rounded so repeated steps don't drift (0.1 isn't exact in binary).
      (scale.clamp(LyricsDisplay.minScale, LyricsDisplay.maxScale) * 10)
          .round() /
      10;
}

/// The user's timing correction for one recording; positive shows lines
/// later. Saved per recording ID.
final lyricsOffsetProvider =
    NotifierProvider.family<LyricsOffsetController, Duration, String>(
      LyricsOffsetController.new,
    );

class LyricsOffsetController extends Notifier<Duration> {
  LyricsOffsetController(this.recordingId);

  static const step = Duration(milliseconds: 500);
  static const limit = Duration(seconds: 10);

  final String recordingId;

  String get _key => 'lyricsOffset.$recordingId';

  @override
  Duration build() => _clamp(
    Duration(
      milliseconds: ref.read(sharedPreferencesProvider).getInt(_key) ?? 0,
    ),
  );

  /// Moves the offset [steps] × [step]; kept within ±[limit].
  Future<void> nudge(int steps) => set(state + step * steps);

  Future<void> reset() => set(Duration.zero);

  Future<void> set(Duration offset) async {
    final clamped = _clamp(offset);
    if (clamped == state) return;
    state = clamped;
    final prefs = ref.read(sharedPreferencesProvider);
    if (clamped == Duration.zero) {
      await prefs.remove(_key);
    } else {
      await prefs.setInt(_key, clamped.inMilliseconds);
    }
  }

  static Duration _clamp(Duration offset) => offset < -limit
      ? -limit
      : offset > limit
      ? limit
      : offset;
}
