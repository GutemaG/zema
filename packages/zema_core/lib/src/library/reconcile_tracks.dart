import 'scanned_audio.dart';
import 'track.dart';
import 'track_fingerprint.dart';

/// What a scan changes in the stored library. Apply it in one transaction.
class TrackReconciliation {
  const TrackReconciliation({
    required this.added,
    required this.updated,
    required this.newlyMissing,
    required this.moved,
    required this.returned,
  });

  /// Files Zema has not seen before. They get new IDs.
  final List<ScannedAudio> added;

  /// Stored tracks whose data changed, with the new values. Unchanged tracks
  /// are left out so a rescan of an unchanged library writes nothing.
  final List<Track> updated;

  /// IDs of stored tracks the scan didn't find and that weren't missing yet.
  final List<int> newlyMissing;

  /// IDs re-linked by fingerprint because their path changed.
  final Set<int> moved;

  /// IDs that were missing and are back.
  final Set<int> returned;

  bool get isEmpty => added.isEmpty && updated.isEmpty && newlyMissing.isEmpty;
}

/// Matches a fresh [scan] to the [stored] tracks.
///
/// A scanned file matches the stored track with the same path. Files left over
/// are matched by [TrackFingerprint] to stored tracks whose path was not
/// found, but only when exactly one stored track and exactly one scanned file
/// share that fingerprint; anything ambiguous is treated as a new file rather
/// than risking a wrong re-link. Stored tracks that match nothing are marked
/// missing; they are never deleted here.
TrackReconciliation reconcileTracks({
  required Iterable<Track> stored,
  required Iterable<ScannedAudio> scan,
}) {
  final storedByPath = {for (final t in stored) t.path: t};

  // The media index shouldn't list a path twice; if it does, keep the first.
  final scanByPath = <String, ScannedAudio>{};
  for (final audio in scan) {
    scanByPath.putIfAbsent(audio.path, () => audio);
  }

  final matches = <Track, ScannedAudio>{};
  final unmatchedScan = <ScannedAudio>[];
  for (final audio in scanByPath.values) {
    final track = storedByPath[audio.path];
    if (track != null) {
      matches[track] = audio;
    } else {
      unmatchedScan.add(audio);
    }
  }

  final unmatchedStored = storedByPath.values.where(
    (t) => !matches.containsKey(t),
  );
  final storedByPrint = <TrackFingerprint, List<Track>>{};
  for (final track in unmatchedStored) {
    storedByPrint
        .putIfAbsent(TrackFingerprint.ofTrack(track), () => [])
        .add(track);
  }
  final scanByPrint = <TrackFingerprint, List<ScannedAudio>>{};
  for (final audio in unmatchedScan) {
    scanByPrint
        .putIfAbsent(TrackFingerprint.ofScan(audio), () => [])
        .add(audio);
  }

  final moved = <int>{};
  final added = <ScannedAudio>[];
  for (final MapEntry(key: print, value: files) in scanByPrint.entries) {
    final candidates = storedByPrint[print];
    if (files.length == 1 && candidates != null && candidates.length == 1) {
      final track = candidates.single;
      matches[track] = files.single;
      moved.add(track.id);
    } else {
      added.addAll(files);
    }
  }

  final updated = <Track>[];
  final returned = <int>{};
  matches.forEach((track, audio) {
    final fresh = Track.fromScan(track.id, audio);
    if (fresh != track) updated.add(fresh);
    if (track.missing) returned.add(track.id);
  });

  final newlyMissing = [
    for (final track in storedByPath.values)
      if (!matches.containsKey(track) && !track.missing) track.id,
  ];

  return TrackReconciliation(
    added: added,
    updated: updated,
    newlyMissing: newlyMissing,
    moved: moved,
    returned: returned,
  );
}
