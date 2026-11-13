import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../catalog/data/catalog_lyrics_repository.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../../lyrics/application/track_lyrics.dart';
import '../data/lyrics_overlay.dart';
import 'detected_song.dart';
import 'detection_providers.dart';

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
    this.recordingOffset = Duration.zero,
  });

  final Song song;
  final List<OverlayLine> lines;
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
        lines: [
          for (final (i, sung) in synced.lines.indexed)
            OverlayLine(sung.line.text, at: timing.starts[i]),
        ],
      );
    } on LyricsFormatFailure catch (e) {
      _log.warning('Timing ${recording.id} does not fit $songId', e);
    }
  }
  return DetectedLyrics(
    song: song,
    lines: [
      for (final sung in expandPlayOrder(song).occurrences)
        OverlayLine(sung.line.text),
    ],
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

final closedOverlaysProvider = NotifierProvider<ClosedOverlays, Set<String>>(
  ClosedOverlays.new,
);

class ClosedOverlays extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void close(String key) => state = {...state, key};
}

final lyricsOverlaySyncProvider = Provider<void>((ref) {
  final overlay = ref.watch(lyricsOverlayProvider);

  void apply() {
    final sheet = ref.read(overlayContentProvider);
    final matching =
        ref.read(currentDetectionProvider) != null &&
        ref.read(detectedSongProvider) == null;
    if (sheet == null && matching) return;
    if (sheet == null || ref.read(closedOverlaysProvider).contains(sheet.key)) {
      unawaited(overlay.hide());
    } else {
      unawaited(overlay.show(sheet));
    }
  }

  ref.listen(overlayContentProvider, (_, _) => apply(), fireImmediately: true);
  ref.listen(closedOverlaysProvider, (_, _) => apply());
  final subscription = overlay.actions.listen((action) {
    switch (action) {
      case OverlayClosed(:final key):
        ref.read(closedOverlaysProvider.notifier).close(key);
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
