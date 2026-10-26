import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'library_dao.g.dart';

/// Reads and writes the local library: tracks and hidden items.
@DriftAccessor(tables: [Tracks, HiddenFolders, HiddenTracks])
class LibraryDao extends DatabaseAccessor<ZemaDatabase> with _$LibraryDaoMixin {
  LibraryDao(super.attachedDatabase);

  /// Every stored track, missing and hidden ones included (for rescans).
  Future<List<Track>> allTracks() async =>
      (await select(tracks).get()).map(_toTrack).toList();

  /// The tracks with [ids] that still exist, in the order of [ids]
  /// (missing files and unknown IDs are left out).
  Future<List<Track>> tracksByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (select(
      tracks,
    )..where((t) => t.id.isIn(ids) & t.missing.not())).get();
    final byId = {for (final row in rows) row.id: _toTrack(row)};
    return [for (final id in ids) ?byId[id]];
  }

  /// Which tracks the library shows: not missing, at least ?1 ms long, and
  /// neither hidden themselves nor inside a hidden folder (or one of its
  /// subfolders).
  static const _visibleWhere = '''
      t.missing = 0
        AND t.duration_ms >= ?1
        AND NOT EXISTS (SELECT 1 FROM hidden_tracks h WHERE h.track_id = t.id)
        AND NOT EXISTS (
          SELECT 1 FROM hidden_folders f
          WHERE t.folder = f.path
             OR substr(t.folder, 1, length(f.path) + 1) = f.path || '/'
        )
      ''';

  /// Tracks to show in the library, sorted by title: not missing, at least
  /// [minDuration] long, and neither hidden themselves nor inside a hidden
  /// folder (or one of its subfolders).
  Stream<List<Track>> watchVisibleTracks({required Duration minDuration}) {
    return customSelect(
      '''
      SELECT t.* FROM tracks t
      WHERE $_visibleWhere
      ORDER BY t.title COLLATE NOCASE, t.id
      ''',
      variables: [Variable.withInt(minDuration.inMilliseconds)],
      readsFrom: {tracks, hiddenTracks, hiddenFolders},
    ).watch().map(
      (rows) => [for (final row in rows) _toTrack(tracks.map(row.data))],
    );
  }

  /// How many tracks [watchVisibleTracks] lists right now.
  Future<int> countVisibleTracks({required Duration minDuration}) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS n FROM tracks t WHERE $_visibleWhere',
      variables: [Variable.withInt(minDuration.inMilliseconds)],
      readsFrom: {tracks, hiddenTracks, hiddenFolders},
    ).getSingle();
    return row.read<int>('n');
  }

  /// Applies a rescan in one transaction: either all of it lands or none.
  Future<void> applyReconciliation(TrackReconciliation changes) {
    return transaction(() async {
      await batch((b) {
        b.insertAll(tracks, [
          for (final audio in changes.added) _insertable(audio),
        ]);
        for (final track in changes.updated) {
          b.replace(tracks, _row(track));
        }
        if (changes.newlyMissing.isNotEmpty) {
          b.update(
            tracks,
            const TracksCompanion(missing: Value(true)),
            where: (t) => t.id.isIn(changes.newlyMissing),
          );
        }
      });
    });
  }

  Future<void> hideFolder(String path, {DateTime? at}) => into(hiddenFolders)
      .insertOnConflictUpdate(
        HiddenFoldersCompanion.insert(
          path: path,
          hiddenAt: at ?? DateTime.now(),
        ),
      );

  Future<void> unhideFolder(String path) =>
      (delete(hiddenFolders)..where((f) => f.path.equals(path))).go();

  Future<void> hideTrack(int trackId, {DateTime? at}) =>
      into(hiddenTracks).insertOnConflictUpdate(
        HiddenTracksCompanion.insert(
          trackId: Value(trackId),
          hiddenAt: at ?? DateTime.now(),
        ),
      );

  Future<void> unhideTrack(int trackId) =>
      (delete(hiddenTracks)..where((h) => h.trackId.equals(trackId))).go();

  /// Hides every track in [trackIds] in one transaction.
  Future<void> hideTracks(List<int> trackIds, {DateTime? at}) {
    final hiddenAt = at ?? DateTime.now();
    return batch((b) {
      b.insertAllOnConflictUpdate(hiddenTracks, [
        for (final id in trackIds)
          HiddenTracksCompanion.insert(trackId: Value(id), hiddenAt: hiddenAt),
      ]);
    });
  }

  Future<void> unhideTracks(List<int> trackIds) =>
      (delete(hiddenTracks)..where((h) => h.trackId.isIn(trackIds))).go();

  /// Hidden folders, by path.
  Stream<List<String>> watchHiddenFolders() => (select(
    hiddenFolders,
  )..orderBy([(f) => OrderingTerm.asc(f.path)])).map((row) => row.path).watch();

  /// Hidden songs whose files still exist, by title.
  Stream<List<Track>> watchHiddenTracks() {
    final query =
        select(tracks).join([
            innerJoin(hiddenTracks, hiddenTracks.trackId.equalsExp(tracks.id)),
          ])
          ..where(tracks.missing.not())
          ..orderBy([
            OrderingTerm.asc(tracks.title.collate(Collate.noCase)),
            OrderingTerm.asc(tracks.id),
          ]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toTrack(row.readTable(tracks))],
    );
  }

  TracksCompanion _insertable(ScannedAudio audio) => TracksCompanion.insert(
    mediaStoreId: audio.mediaStoreId,
    uri: audio.uri,
    path: audio.path,
    folder: folderOf(audio.path),
    title: resolveTitle(audio),
    artist: Value(audio.artist),
    album: Value(audio.album),
    albumArtist: Value(audio.albumArtist),
    trackNumber: Value(audio.trackNumber),
    year: Value(audio.year),
    durationMs: audio.duration.inMilliseconds,
    sizeBytes: audio.sizeBytes,
    dateAdded: audio.dateAdded,
  );

  TrackRow _row(Track t) => TrackRow(
    id: t.id,
    mediaStoreId: t.mediaStoreId,
    uri: t.uri,
    path: t.path,
    folder: t.folder,
    title: t.title,
    artist: t.artist,
    album: t.album,
    albumArtist: t.albumArtist,
    trackNumber: t.trackNumber,
    year: t.year,
    durationMs: t.duration.inMilliseconds,
    sizeBytes: t.sizeBytes,
    dateAdded: t.dateAdded,
    missing: t.missing,
  );

  Track _toTrack(TrackRow r) => Track(
    id: r.id,
    mediaStoreId: r.mediaStoreId,
    uri: r.uri,
    path: r.path,
    title: r.title,
    artist: r.artist,
    album: r.album,
    albumArtist: r.albumArtist,
    trackNumber: r.trackNumber,
    year: r.year,
    duration: Duration(milliseconds: r.durationMs),
    sizeBytes: r.sizeBytes,
    // Dates are stored as UTC text and come back as UTC; toUtc() guards rows
    // written in local time, which would never equal `Track.fromScan`.
    dateAdded: r.dateAdded.toUtc(),
    missing: r.missing,
  );
}
