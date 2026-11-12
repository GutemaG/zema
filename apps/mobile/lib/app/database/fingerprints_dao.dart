import 'package:drift/drift.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'fingerprints_dao.g.dart';

/// Audio fingerprints of library files, by Zema's track ID. A track's
/// fingerprint goes with its row.
@DriftAccessor(tables: [TrackFingerprints])
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
}
