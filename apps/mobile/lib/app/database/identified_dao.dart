import 'package:drift/drift.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'identified_dao.g.dart';

const identifiedRepeatWindow = Duration(minutes: 10);

@DriftAccessor(tables: [IdentifiedSongs])
class IdentifiedDao extends DatabaseAccessor<ZemaDatabase>
    with _$IdentifiedDaoMixin {
  IdentifiedDao(super.attachedDatabase);

  Future<void> add(int trackId, DateTime at) => transaction(() async {
    final last =
        await (select(identifiedSongs)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    if (last != null &&
        last.trackId == trackId &&
        at.difference(last.identifiedAt) < identifiedRepeatWindow) {
      await (update(identifiedSongs)..where((t) => t.id.equals(last.id))).write(
        IdentifiedSongsCompanion(identifiedAt: Value(at)),
      );
      return;
    }
    await into(identifiedSongs).insert(
      IdentifiedSongsCompanion.insert(trackId: trackId, identifiedAt: at),
    );
  });

  Stream<List<IdentifiedSongRow>> watchAll() => (select(
    identifiedSongs,
  )..orderBy([(t) => OrderingTerm.desc(t.id)])).watch();

  Future<void> remove(int id) =>
      (delete(identifiedSongs)..where((t) => t.id.equals(id))).go();

  Future<void> clear() => delete(identifiedSongs).go();
}
