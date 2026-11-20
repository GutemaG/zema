import 'package:drift/drift.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'fingerprints_dao.g.dart';

/// Audio fingerprints of library files, by Zema's track ID (a track's
/// fingerprint goes with its row), of catalog recordings kept offline, and
/// what library files were identified as by their sound.
@DriftAccessor(
  tables: [
    TrackFingerprints,
    CatalogFingerprints,
    TrackAudioMatches,
    TrackPrints,
  ],
)
class FingerprintsDao extends DatabaseAccessor<ZemaDatabase>
    with _$FingerprintsDaoMixin {
  FingerprintsDao(super.attachedDatabase);

  Future<List<TrackFingerprintRow>> all() => select(trackFingerprints).get();

  Stream<List<TrackFingerprintRow>> watchAll() =>
      select(trackFingerprints).watch();

  Future<void> put(
    int trackId, {
    required int version,
    required int sizeBytes,
    required Uint8List data,
    DateTime? at,
  }) => into(trackFingerprints).insertOnConflictUpdate(
    TrackFingerprintsCompanion.insert(
      trackId: Value(trackId),
      version: version,
      sizeBytes: sizeBytes,
      data: data,
      updatedAt: (at ?? DateTime.now()).toUtc(),
    ),
  );

  Future<void> remove(List<int> trackIds) =>
      (delete(trackFingerprints)..where((f) => f.trackId.isIn(trackIds))).go();

  Future<Map<int, int>> sizes(int version) async {
    final rows =
        await (selectOnly(trackFingerprints)
              ..addColumns([
                trackFingerprints.trackId,
                trackFingerprints.sizeBytes,
              ])
              ..where(_usable(version)))
            .get();
    return {
      for (final row in rows)
        row.read(trackFingerprints.trackId)!: row.read(
          trackFingerprints.sizeBytes,
        )!,
    };
  }

  Future<List<TrackFingerprintRow>> page(
    int version, {
    required int after,
    required int limit,
  }) =>
      (select(trackFingerprints)
            ..where(
              (f) => _usable(version) & f.trackId.isBiggerThanValue(after),
            )
            ..orderBy([(f) => OrderingTerm.asc(f.trackId)])
            ..limit(limit))
          .get();

  Future<(int, DateTime?)> stamp() async {
    final count = trackFingerprints.trackId.count();
    final latest = trackFingerprints.updatedAt.max();
    final row = await (selectOnly(
      trackFingerprints,
    )..addColumns([count, latest])).getSingle();
    return (row.read(count)!, row.read(latest));
  }

  Expression<bool> _usable(int version) =>
      trackFingerprints.version.equals(version) &
      const CustomExpression<bool>('length(data) > 0');

  /// The catalog fingerprints kept, with their sizes in bytes.
  Future<List<KeptFingerprint>> keptCatalog() async {
    final size = catalogFingerprints.data.length;
    final rows =
        await (selectOnly(catalogFingerprints)..addColumns([
              catalogFingerprints.recordingId,
              catalogFingerprints.songId,
              catalogFingerprints.revision,
              catalogFingerprints.version,
              size,
            ]))
            .get();
    return [
      for (final row in rows)
        (
          recordingId: row.read(catalogFingerprints.recordingId)!,
          songId: row.read(catalogFingerprints.songId)!,
          revision: row.read(catalogFingerprints.revision)!,
          version: row.read(catalogFingerprints.version)!,
          bytes: row.read(size) ?? 0,
        ),
    ];
  }

  Future<void> putCatalog(
    String recordingId, {
    required String songId,
    required int revision,
    required int version,
    required Uint8List data,
    DateTime? at,
  }) => into(catalogFingerprints).insertOnConflictUpdate(
    CatalogFingerprintsCompanion.insert(
      recordingId: recordingId,
      songId: songId,
      revision: revision,
      version: version,
      data: data,
      updatedAt: (at ?? DateTime.now()).toUtc(),
    ),
  );

  Future<void> removeCatalog(Iterable<String> recordingIds) => (delete(
    catalogFingerprints,
  )..where((f) => f.recordingId.isIn(recordingIds))).go();

  Future<List<CatalogFingerprintRow>> catalogPage(
    int version, {
    required String after,
    required int limit,
  }) =>
      (select(catalogFingerprints)
            ..where(
              (f) =>
                  f.version.equals(version) &
                  f.recordingId.isBiggerThanValue(after),
            )
            ..orderBy([(f) => OrderingTerm.asc(f.recordingId)])
            ..limit(limit))
          .get();

  /// How many catalog songs the kept fingerprints cover, and their size.
  Stream<({int songs, int bytes})> watchCatalogCoverage() =>
      customSelect(
        'SELECT COUNT(DISTINCT song_id) AS songs, '
        'COALESCE(SUM(length(data)), 0) AS bytes FROM catalog_fingerprints',
        readsFrom: {catalogFingerprints},
      ).watchSingle().map(
        (row) => (songs: row.read<int>('songs'), bytes: row.read<int>('bytes')),
      );

  /// Changes when a catalog fingerprint is added, replaced or removed.
  Future<(int, DateTime?)> catalogStamp() async {
    final count = catalogFingerprints.recordingId.count();
    final latest = catalogFingerprints.updatedAt.max();
    final row = await (selectOnly(
      catalogFingerprints,
    )..addColumns([count, latest])).getSingle();
    return (row.read(count)!, row.read(latest));
  }

  /// What library files were identified as by their sound, by track ID.
  Stream<Map<int, TrackAudioMatchRow>> watchAudioMatches() =>
      select(trackAudioMatches)
          .watch()
          .map((rows) => {for (final row in rows) row.trackId: row});

  Future<TrackAudioMatchRow?> audioMatch(int trackId) => (select(
    trackAudioMatches,
  )..where((m) => m.trackId.equals(trackId))).getSingleOrNull();

  Future<void> putAudioMatch(TrackAudioMatchesCompanion match) =>
      into(trackAudioMatches).insertOnConflictUpdate(match);

  Future<TrackPrintRow?> trackPrint(int trackId) => (select(
    trackPrints,
  )..where((p) => p.trackId.equals(trackId))).getSingleOrNull();

  Future<void> putTrackPrint(TrackPrintsCompanion print) =>
      into(trackPrints).insertOnConflictUpdate(print);

  /// The songs library files' prints matched, by track ID.
  Stream<Map<int, String>> watchTrackPrintMatches() =>
      (select(trackPrints)..where((p) => p.songId.isNotNull())).watch().map(
        (rows) => {for (final row in rows) row.trackId: row.songId!},
      );

  /// Every library file's track print, by track ID.
  Future<Map<int, TrackPrintRow>> trackPrintsByTrack() async => {
    for (final row in await select(trackPrints).get()) row.trackId: row,
  };

  /// The songs a print was shared for.
  Future<Set<String>> sharedPrintSongs() async => {
    for (final row in await (select(
      trackPrints,
    )..where((p) => p.sharedSongId.isNotNull())).get())
      row.sharedSongId!,
  };
}

/// A catalog fingerprint on the phone, without its bytes.
typedef KeptFingerprint = ({
  String recordingId,
  String songId,
  int revision,
  int version,
  int bytes,
});
