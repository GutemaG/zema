import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/preferences_provider.dart';

/// How the lyrics view shows lines, remembered across restarts.
class LyricsDisplay {
  const LyricsDisplay({
    this.showTransliteration = false,
    this.textScale = 1,
    this.defaultOffset = Duration.zero,
  });

  static const double minScale = 0.8;
  static const double maxScale = 1.6;
  static const double scaleStep = 0.1;

  /// Whether each line's transliteration shows below it.
  final bool showTransliteration;

  /// Size of the lyrics text, on top of the phone's text size.
  final double textScale;

  /// The timing correction for recordings without their own; positive
  /// shows lines later.
  final Duration defaultOffset;

  bool get canShrink => textScale > minScale + 0.001;
  bool get canGrow => textScale < maxScale - 0.001;

  LyricsDisplay copyWith({
    bool? showTransliteration,
    double? textScale,
    Duration? defaultOffset,
  }) => LyricsDisplay(
    showTransliteration: showTransliteration ?? this.showTransliteration,
    textScale: textScale ?? this.textScale,
    defaultOffset: defaultOffset ?? this.defaultOffset,
  );

  @override
  bool operator ==(Object other) =>
      other is LyricsDisplay &&
      other.showTransliteration == showTransliteration &&
      other.textScale == textScale &&
      other.defaultOffset == defaultOffset;

  @override
  int get hashCode =>
      Object.hash(showTransliteration, textScale, defaultOffset);
}

final lyricsDisplayProvider =
    NotifierProvider<LyricsDisplayController, LyricsDisplay>(
      LyricsDisplayController.new,
    );

class LyricsDisplayController extends Notifier<LyricsDisplay> {
  static const transliterationKey = 'lyricsTransliteration';
  static const scaleKey = 'lyricsTextScale';
  static const defaultOffsetKey = 'lyricsDefaultOffset';

  @override
  LyricsDisplay build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return LyricsDisplay(
      showTransliteration: prefs.getBool(transliterationKey) ?? false,
      textScale: _clampScale(prefs.getDouble(scaleKey) ?? 1),
      defaultOffset: clampOffset(
        Duration(milliseconds: prefs.getInt(defaultOffsetKey) ?? 0),
      ),
    );
  }

  /// Moves the default offset [steps] × [LyricsOffsetController.step].
  Future<void> nudgeDefaultOffset(int steps) async {
    final offset = clampOffset(
      state.defaultOffset + LyricsOffsetController.step * steps,
    );
    if (offset == state.defaultOffset) return;
    state = state.copyWith(defaultOffset: offset);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(defaultOffsetKey, offset.inMilliseconds);
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

/// Keeps a timing correction within ±[LyricsOffsetController.limit].
Duration clampOffset(Duration offset) {
  const limit = LyricsOffsetController.limit;
  return offset < -limit
      ? -limit
      : offset > limit
      ? limit
      : offset;
}

/// The user's timing correction for one recording, or null when it has
/// none and the default applies; positive shows lines later. Saved per
/// recording ID.
final lyricsOffsetProvider =
    NotifierProvider.family<LyricsOffsetController, Duration?, String>(
      LyricsOffsetController.new,
    );

class LyricsOffsetController extends Notifier<Duration?> {
  LyricsOffsetController(this.recordingId);

  static const step = Duration(milliseconds: 500);
  static const limit = Duration(seconds: 10);

  final String recordingId;

  String get _key => 'lyricsOffset.$recordingId';

  @override
  Duration? build() =>
      switch (ref.read(sharedPreferencesProvider).getInt(_key)) {
        final ms? => clampOffset(Duration(milliseconds: ms)),
        null => null,
      };

  /// The offset in effect: this recording's own, or the default.
  Duration get effective =>
      state ?? ref.read(lyricsDisplayProvider).defaultOffset;

  /// Moves the offset in effect [steps] × [step] and keeps it as this
  /// recording's own; kept within ±[limit].
  Future<void> nudge(int steps) => set(effective + step * steps);

  /// Forgets this recording's own offset, so the default applies.
  Future<void> reset() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_key);
  }

  Future<void> set(Duration offset) async {
    final clamped = clampOffset(offset);
    if (clamped == state) return;
    state = clamped;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_key, clamped.inMilliseconds);
  }
}
