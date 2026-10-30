import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'unmatched_dao.g.dart';

/// Backed-up entries whose song isn't on this phone (see [UnmatchedEntries]).
@DriftAccessor(tables: [UnmatchedEntries])
class UnmatchedDao extends DatabaseAccessor<ZemaDatabase>
    with _$UnmatchedDaoMixin {
  UnmatchedDao(super.attachedDatabase);

  /// Every entry, oldest first.
  Future<List<UnmatchedEntry>> all() async => [
    for (final row in await (select(
      unmatchedEntries,
    )..orderBy([(u) => OrderingTerm.asc(u.id)])).get())
      ?_toEntry(row),
  ];

  /// Adds [entries], skipping ones already kept.
  Future<void> addAll(List<UnmatchedEntry> entries) => transaction(() async {
    final kept = (await all()).toSet();
    final added = [
      for (final entry in entries)
        if (kept.add(entry)) entry,
    ];
    await batch((b) => b.insertAll(unmatchedEntries, added.map(_toRow)));
  });

  /// Makes the kept entries exactly [entries].
  Future<void> replaceAll(List<UnmatchedEntry> entries) =>
      transaction(() async {
        await delete(unmatchedEntries).go();
        await addAll(entries);
      });

  Future<void> clear() => delete(unmatchedEntries).go();

  static UnmatchedEntriesCompanion _toRow(UnmatchedEntry e) =>
      UnmatchedEntriesCompanion.insert(
        kind: e.kind.name,
        title: e.track.title,
        artist: Value(e.track.artist),
        album: Value(e.track.album),
        durationMs: e.track.durationMs,
        fileName: e.track.fileName,
        addedAt: Value(e.addedAt?.toUtc()),
        playlist: Value(e.playlist),
        position: Value(e.position),
        songId: Value(e.songId),
      );

  /// Null for a row this app can't read (an unknown kind).
  static UnmatchedEntry? _toEntry(UnmatchedEntryRow r) {
    final track = TrackIdentity(
      title: r.title,
      artist: r.artist,
      album: r.album,
      durationMs: r.durationMs,
      fileName: r.fileName,
    );
    return switch (BackupEntryKind.values.asNameMap()[r.kind]) {
      BackupEntryKind.favorite => UnmatchedEntry.favorite(
        track,
        addedAt: (r.addedAt ?? DateTime.utc(1970)).toUtc(),
      ),
      BackupEntryKind.playlist => UnmatchedEntry.playlist(
        track,
        playlist: r.playlist ?? '',
        position: r.position ?? 0,
      ),
      BackupEntryKind.lyricsChoice => UnmatchedEntry.lyricsChoice(
        track,
        songId: r.songId,
      ),
      BackupEntryKind.hiddenTrack => UnmatchedEntry.hiddenTrack(track),
      null => null,
    };
  }
}
