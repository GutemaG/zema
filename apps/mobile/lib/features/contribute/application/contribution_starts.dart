import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:zema_core/zema_core.dart';

import '../../catalog/application/catalog_index.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../../lyrics/application/track_lyrics.dart';
import '../../player/application/player_providers.dart';

/// The catalog index's entry for song [songId] (with the version a
/// correction is based on), or null when the index doesn't list it.
final catalogEntryProvider = Provider.family<CatalogEntry?, String>(
  (ref, songId) => ref.watch(
    catalogEntriesProvider.select(
      (index) => index.value?.where((e) => e.id == songId).firstOrNull,
    ),
  ),
);

/// A new-song draft for library [track], which has no lyrics: its title
/// and artist filled in, and the track already chosen as the recording.
ContributionDraft newSongDraftFor(Track track) => ContributionDraft(
  song: Song(
    id: '',
    title: track.title,
    artist: track.artist,
    sections: const [],
  ),
  recording: Recording(
    id: newRecordingId(),
    songId: '',
    source: RecordingSource.localFile,
    artist: track.artist,
    duration: track.duration,
    fileName: p.basename(track.path),
  ),
  trackId: track.id,
);

/// A catalog recording the phone can time, and the track that plays it.
typedef SyncableRecording = ({Recording recording, Track track});

/// The first of [recordings] without a timing that is a local file one of
/// [tracks] plays (same file name, as S20 saves it), trying the tracks in
/// order. Null when there is none: YouTube and Telegram recordings can't be
/// played from the phone's library.
SyncableRecording? recordingToSync(
  List<RecordingInfo> recordings,
  List<Track> tracks,
) {
  for (final track in tracks) {
    final name = p.basename(track.path);
    for (final (:recording, :synced) in recordings) {
      if (!synced &&
          recording.source == RecordingSource.localFile &&
          recording.fileName == name) {
        return (recording: recording, track: track);
      }
    }
  }
  return null;
}

/// What Song detail's Sync this recording times for song [songId]: its
/// recording without a timing that the playing track, or another track
/// linked to the song, plays. Null while loading or when there is none.
final syncableRecordingProvider = Provider.family<SyncableRecording?, String>((
  ref,
  songId,
) {
  final recordings = ref.watch(songRecordingsInfoProvider(songId)).value;
  if (recordings == null) return null;
  final linked = ref.watch(songTracksProvider(songId));
  final playing = ref.watch(currentTrackProvider);
  return recordingToSync(recordings, [
    if (playing != null && linked.any((t) => t.id == playing.id)) playing,
    for (final track in linked)
      if (track.id != playing?.id) track,
  ]);
});
