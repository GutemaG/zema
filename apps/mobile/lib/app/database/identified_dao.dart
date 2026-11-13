import 'package:drift/drift.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'identified_dao.g.dart';

const identifiedRepeatWindow = Duration(minutes: 10);

@DriftAccessor(tables: [IdentifiedSongs, PendingLookups])
class IdentifiedDao extends DatabaseAccessor<ZemaDatabase>
    with _$IdentifiedDaoMixin {
  IdentifiedDao(super.attachedDatabase);

  /// Adds library track [trackId] or catalog song [songId] at [at]; the same
  /// song again within [identifiedRepeatWindow] only moves the time.
  Future<void> add(DateTime at, {int? trackId, String? songId}) =>
      transaction(() async {
        final last =
            await (select(identifiedSongs)
                  ..orderBy([(t) => OrderingTerm.desc(t.id)])
                  ..limit(1))
                .getSingleOrNull();
        if (last != null &&
            last.trackId == trackId &&
            last.songId == songId &&
            at.difference(last.identifiedAt) < identifiedRepeatWindow) {
          await (update(identifiedSongs)..where((t) => t.id.equals(last.id)))
              .write(IdentifiedSongsCompanion(identifiedAt: Value(at)));
          return;
        }
        await into(identifiedSongs).insert(
          IdentifiedSongsCompanion.insert(
            trackId: Value(trackId),
            songId: Value(songId),
            identifiedAt: at,
          ),
        );
      });

  Stream<List<IdentifiedSongRow>> watchAll() => (select(
    identifiedSongs,
  )..orderBy([(t) => OrderingTerm.desc(t.id)])).watch();

  Future<void> remove(int id) =>
      (delete(identifiedSongs)..where((t) => t.id.equals(id))).go();

  Future<void> clear() => delete(identifiedSongs).go();

  Future<void> addPending(Uint8List queries, DateTime heardAt) => into(
    pendingLookups,
  ).insert(PendingLookupsCompanion.insert(queries: queries, heardAt: heardAt));

  Future<List<PendingLookupRow>> pending() =>
      (select(pendingLookups)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<void> removePending(int id) =>
      (delete(pendingLookups)..where((t) => t.id.equals(id))).go();
}
