import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../player/application/player_providers.dart';
import '../data/bundled_lyrics_repository.dart';
import 'lyrics_links.dart';
import 'lyrics_prefs.dart';

final _log = Logger('lyrics.track');

/// A track's lyrics: its linked song as sung, and the timing of the song's
/// recording when there is one.
class TrackLyrics {
  const TrackLyrics({
    required this.song,
    required this.lines,
    this.recording,
    this.synced,
  });

  final Song song;

  /// The lines in sung order, repeats included.
  final List<LineOccurrence> lines;

  /// The recording whose timing is used, if any.
  final Recording? recording;

  /// Null for plain lyrics (no timing, or timing that doesn't fit).
  final SyncedLyrics? synced;
}

/// The lyrics of track [trackId], or null when it isn't linked to a song.
final trackLyricsProvider = FutureProvider.family<TrackLyrics?, int>((
  ref,
  trackId,
) async {
  final song = switch (ref.watch(trackSongProvider(trackId))) {
    AsyncData(:final value) => value,
    AsyncError(:final error, :final stackTrace) => Error.throwWithStackTrace(
      error,
      stackTrace,
    ),
    // Rebuilt when the link loads.
    _ => await Completer<Song?>().future,
  };
  if (song == null) return null;
  final lines = expandPlayOrder(song).occurrences;
  final repository = ref.watch(lyricsRepositoryProvider);
  final recording = (await repository.recordings(song.id)).firstOrNull;
  if (recording == null) return TrackLyrics(song: song, lines: lines);
  final timing = await repository.timing(recording.id);
  SyncedLyrics? synced;
  if (timing != null) {
    try {
      synced = SyncedLyrics.of(song, timing);
    } on LyricsFormatFailure catch (e) {
      // Shown as plain lyrics instead.
      _log.warning('Timing ${recording.id} does not fit ${song.id}', e);
    }
  }
  return TrackLyrics(
    song: song,
    lines: synced?.lines ?? lines,
    recording: recording,
    synced: synced,
  );
});

/// The total shift of [lyrics]' timing: the recording's own offset plus the
/// user's correction for it, or the default correction.
final lyricsShiftProvider = Provider.family<Duration, TrackLyrics>((
  ref,
  lyrics,
) {
  final recording = lyrics.recording;
  if (recording == null) return Duration.zero;
  final own = ref.watch(lyricsOffsetProvider(recording.id));
  return recording.offset +
      (own ?? ref.watch(lyricsDisplayProvider).defaultOffset);
});

/// The index of the line being sung in track [trackId]'s lyrics, or null
/// (plain lyrics, or before the first line). Changes only when the line
/// does, not on every position update.
final currentLineProvider = Provider.family<int?, int>((ref, trackId) {
  final lyrics = ref.watch(trackLyricsProvider(trackId)).value;
  final synced = lyrics?.synced;
  if (lyrics == null || synced == null) return null;
  final position = ref.watch(positionProvider).value ?? Duration.zero;
  return synced.engine
      .at(position, offset: ref.watch(lyricsShiftProvider(lyrics)))
      .current;
});
