import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/own_copies_dao.dart';
import '../../contribute/application/own_copies.dart';
import '../../player/application/player_providers.dart';
import '../../catalog/data/catalog_lyrics_repository.dart';
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
    this.pending = false,
    this.localDraftId,
  });

  final Song song;

  /// The lines in sung order, repeats included.
  final List<LineOccurrence> lines;

  /// The recording whose timing is used, if any.
  final Recording? recording;

  /// Null for plain lyrics (no timing, or timing that doesn't fit).
  final SyncedLyrics? synced;

  /// Whether these are the user's own contribution, waiting for review
  /// (shown on this phone only).
  final bool pending;

  /// For lyrics saved on this phone only, the draft they were saved from.
  final int? localDraftId;
}

/// The recording of a song whose timing the lyrics view uses.
Recording? usedRecording(List<Recording> recordings) => recordings.firstOrNull;

/// The lyrics of track [trackId], or null when it isn't linked to a song.
/// The user's own contribution for the track, while it waits for review,
/// or lyrics saved for it on this phone only, come before the linked song. Fails when the song can't be downloaded
/// (see [songProvider]).
final trackLyricsProvider = FutureProvider.family<TrackLyrics?, int>((
  ref,
  trackId,
) async {
  final own = switch (ref.watch(trackOwnCopyProvider(trackId))) {
    AsyncData(:final value) => value,
    // The linked song shows instead.
    AsyncError() => null,
    // Rebuilt when the copies load.
    _ => await Completer<OwnCopy?>().future,
  };
  if (own != null) return _pendingLyrics(own);
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
  final recording = usedRecording(await repository.recordings(song.id));
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
  // A failure shows C07 at once; its Try again retries.
}, retry: (_, _) => null);

/// The lyrics of the user's own copy [own], marked pending, or as saved on
/// this phone.
TrackLyrics _pendingLyrics(OwnCopy own) {
  final song = own.song;
  SyncedLyrics? synced;
  if (own.timing case final timing?) {
    try {
      synced = SyncedLyrics.of(song, timing);
    } on LyricsFormatFailure catch (e) {
      _log.warning('Own timing does not fit ${own.contributionId}', e);
    }
  }
  return TrackLyrics(
    song: song,
    lines: synced?.lines ?? expandPlayOrder(song).occurrences,
    recording: own.recording,
    synced: synced,
    pending: own.localDraftId == null,
    localDraftId: own.localDraftId,
  );
}

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

/// A song's recording, and whether it has a timing (synced lyrics).
typedef RecordingInfo = ({Recording recording, bool synced});

/// The recordings of the song [songId] with whether each is synced; the
/// recordings keep the catalog's order (see [usedRecording]). Read again
/// with the song, so C07's Try again covers it too.
final songRecordingsInfoProvider =
    FutureProvider.family<List<RecordingInfo>, String>((ref, songId) async {
      await ref.watch(songProvider(songId).future);
      final repository = ref.watch(lyricsRepositoryProvider);
      final recordings = await repository.recordings(songId);
      return [
        for (final recording in recordings)
          (
            recording: recording,
            synced: await repository.timing(recording.id) != null,
          ),
      ];
    }, retry: (_, _) => null);
