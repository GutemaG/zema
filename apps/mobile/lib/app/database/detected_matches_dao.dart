import 'package:drift/drift.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'detected_matches_dao.g.dart';

@DriftAccessor(tables: [DetectedMatches])
class DetectedMatchesDao extends DatabaseAccessor<ZemaDatabase>
    with _$DetectedMatchesDaoMixin {
  DetectedMatchesDao(super.attachedDatabase);

  Stream<List<DetectedMatchRow>> watchAll() => select(detectedMatches).watch();

  Future<void> remember(
    String sourceKey,
    String? songId, {
    Duration offset = Duration.zero,
    required DateTime at,
  }) => into(detectedMatches).insertOnConflictUpdate(
    DetectedMatchesCompanion.insert(
      sourceKey: sourceKey,
      songId: Value(songId),
      offsetMs: Value(offset.inMilliseconds),
      decidedAt: at,
    ),
  );

  Future<void> forget(String sourceKey) => (delete(
    detectedMatches,
  )..where((t) => t.sourceKey.equals(sourceKey))).go();

  Future<void> clear() => delete(detectedMatches).go();
}
