import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../catalog/data/catalog_lyrics_repository.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../../lyrics/application/track_lyrics.dart';
import '../../settings/application/settings_controller.dart';
import '../data/lyrics_overlay.dart';
import 'detected_song.dart';
import 'detection_providers.dart';
import 'player_overlay.dart';

final _log = Logger('detection.overlay');

final lyricsOverlayProvider = Provider<LyricsOverlay>(
  (ref) => Platform.isAndroid
      ? const AndroidLyricsOverlay()
      : const NoLyricsOverlay(),
);

class DetectedLyrics {
  const DetectedLyrics({
    required this.song,
    required this.lines,
    required this.sung,
    this.recordingOffset = Duration.zero,
  });

  final Song song;
  final List<OverlayLine> lines;
  final List<LineOccurrence> sung;
  final Duration recordingOffset;
}

final detectedLyricsProvider = FutureProvider.family<DetectedLyrics?, String>((
  ref,
  songId,
) async {
  final song = await ref.watch(songProvider(songId).future);
  if (song == null) return null;
  final repository = ref.watch(lyricsRepositoryProvider);
  final recording = usedRecording(await repository.recordings(songId));
  final timing = recording == null
      ? null
      : await repository.timing(recording.id);
  if (recording != null && timing != null) {
    try {
      final synced = SyncedLyrics.of(song, timing);
      return DetectedLyrics(
        song: song,
        recordingOffset: recording.offset,
        sung: synced.lines,
        lines: [
          for (final (i, sung) in synced.lines.indexed)
            OverlayLine(sung.line.text, at: timing.starts[i]),
        ],
      );
    } on LyricsFormatFailure catch (e) {
      _log.warning('Timing ${recording.id} does not fit $songId', e);
    }
  }
  final sung = expandPlayOrder(song).occurrences;
  return DetectedLyrics(
    song: song,
    sung: sung,
    lines: [for (final line in sung) OverlayLine(line.line.text)],
  );
}, retry: (_, _) => null);

final overlayContentProvider = Provider<OverlayContent?>((ref) {
  final detected = ref.watch(detectedSongProvider);
  switch (detected) {
    case DetectedUnsure(:final candidates) when candidates.isNotEmpty:
      final best = candidates.first;
      return OverlayQuestion(
        key: detected.key,
        source: detected.playback.source,
        songId: best.id,
        title: best.title,
        artist: best.artist,
      );
    case DetectedMatch():
      return switch (ref.watch(detectedLyricsProvider(detected.song.id))) {
        AsyncData(value: final lyrics?) => OverlaySheet(
          key: detected.key,
          source: detected.playback.source,
          songId: detected.song.id,
          title: lyrics.song.title,
          artist: lyrics.song.artist,
          lines: lyrics.lines,
          offset: detected.offset - lyrics.recordingOffset,
        ),
        AsyncError() => OverlaySheet(
          key: detected.key,
          source: detected.playback.source,
          songId: detected.song.id,
          title: detected.song.title,
          artist: detected.song.artist,
          lines: const [],
          failed: true,
        ),
        _ => null,
      };
    default:
      return null;
  }
});

final overlayAccessProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(lyricsOverlayProvider).canShow(),
);

final overlayHideDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 10),
);

final overlayStartProvider = FutureProvider<OverlayStart>(
  (ref) async => (await ref.watch(lyricsOverlayProvider).appearance()).start,
);

final overlayChoicesProvider =
    NotifierProvider<OverlayChoices, Map<String, bool>>(OverlayChoices.new);

class OverlayChoices extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void close(String key) => state = {...state, key: false};

  void open(String key) => state = {...state, key: true};
}

final lyricsOverlaySyncProvider = Provider<void>((ref) {
  final overlay = ref.watch(lyricsOverlayProvider);
  Timer? hiding;
  ref.onDispose(() => hiding?.cancel());

  bool wanted(String key) =>
      ref.read(overlayChoicesProvider)[key] ??
      switch (ref.read(overlayStartProvider).value) {
        OverlayStart.bubble || OverlayStart.bar => true,
        OverlayStart.tap || null => false,
      };

  void apply() {
    final sheet = ref.read(overlayContentProvider);
    final own = ref.read(playerOverlayProvider);
    if (own != null &&
        playerOverlayWanted(ref, own.sheet.key) &&
        (own.playing || sheet == null)) {
      hiding?.cancel();
      hiding = null;
      unawaited(overlay.show(own.sheet));
      return;
    }
    final playing = ref.read(currentDetectionProvider) != null;
    if (sheet == null && playing && ref.read(detectedSongProvider) == null) {
      return;
    }
    if (sheet != null && wanted(sheet.key)) {
      hiding?.cancel();
      hiding = null;
      unawaited(overlay.show(sheet));
    } else if (sheet == null && !playing) {
      hiding ??= Timer(ref.read(overlayHideDelayProvider), () {
        hiding = null;
        unawaited(overlay.hide());
      });
    } else {
      hiding?.cancel();
      hiding = null;
      unawaited(overlay.hide());
    }
  }

  ref.listen(overlayContentProvider, (_, _) => apply(), fireImmediately: true);
  ref.listen(overlayChoicesProvider, (_, _) => apply());
  ref.listen(overlayStartProvider, (_, _) => apply());
  ref.listen(playerOverlayProvider, (_, _) => apply());
  ref.listen(settingsProvider.select((s) => s.floatLyrics), (_, _) => apply());
  final subscription = overlay.actions.listen((action) {
    switch (action) {
      case OverlayClosed(:final key):
        ref.read(overlayChoicesProvider.notifier).close(key);
      case OverlayOffset(:final key, :final offset)
          when playerOverlayTrack(key) != null:
        final trackId = playerOverlayTrack(key)!;
        unawaited(
          savePlayerOverlayOffset(ref, trackId, offset).catchError((
            Object e,
            StackTrace s,
          ) {
            _log.warning('Could not save the timing', e, s);
          }),
        );
      case OverlayOffset(:final key, :final offset):
        final detected = ref.read(detectedSongProvider);
        if (detected is! DetectedMatch || detected.key != key) return;
        final lyrics = ref.read(detectedLyricsProvider(detected.song.id)).value;
        unawaited(
          ref
              .read(detectedMatchControllerProvider)
              .setOffset(
                detected.playback,
                detected.song.id,
                offset + (lyrics?.recordingOffset ?? Duration.zero),
              )
              .catchError((Object e, StackTrace s) {
                _log.warning('Could not save the timing', e, s);
              }),
        );
      case OverlayConfirmed(:final key, :final songId):
        final detected = ref.read(detectedSongProvider);
        if (detected is! DetectedUnsure || detected.key != key) return;
        final song = detected.candidates.where((c) => c.id == songId);
        if (song.isEmpty) return;
        unawaited(
          ref
              .read(detectedMatchControllerProvider)
              .confirm(detected.playback, song.first)
              .catchError((Object e, StackTrace s) {
                _log.warning('Could not save the answer', e, s);
              }),
        );
      case OverlayNotMezmur(:final key):
        final detected = ref.read(detectedSongProvider);
        if (detected == null || detected.key != key) return;
        unawaited(
          ref
              .read(detectedMatchControllerProvider)
              .notMezmur(detected.playback)
              .catchError((Object e, StackTrace s) {
                _log.warning('Could not save the answer', e, s);
              }),
        );
      case OverlayOpened():
        break;
    }
  });
  ref.onDispose(subscription.cancel);
});
