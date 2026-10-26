import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'collections_dao.g.dart';

/// A user playlist as stored: every entry, hidden and missing songs
/// included, in playlist order.
class StoredPlaylist {
  const StoredPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.trackIds,
  });

  final int id;
  final String name;
  final String? description;
  final List<int> trackIds;
}

/// Reads and writes what the listener collects: favorites and playlists.
/// Rows point at tracks by ID and are kept when a file goes missing, so they
/// come back with it.
@DriftAccessor(tables: [Favorites, Playlists, PlaylistEntries])
class CollectionsDao extends DatabaseAccessor<ZemaDatabase>
    with _$CollectionsDaoMixin {
  CollectionsDao(super.attachedDatabase);

  /// Every favorite, newest first.
  Stream<List<FavoriteRow>> watchFavorites() =>
      (select(favorites)..orderBy([
            (f) => OrderingTerm.desc(f.addedAt),
            (f) => OrderingTerm.desc(f.trackId),
          ]))
          .watch();

  /// Favorites [trackId]; does nothing if it already is one.
  Future<void> addFavorite(int trackId, {DateTime? at}) =>
      into(favorites).insert(
        FavoritesCompanion.insert(
          trackId: Value(trackId),
          addedAt: at ?? DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Favorites every track in [trackIds] at the same time; ones that
  /// already are keep their time.
  Future<void> addFavorites(List<int> trackIds, {DateTime? at}) {
    final addedAt = at ?? DateTime.now();
    return batch((b) {
      b.insertAll(favorites, [
        for (final id in trackIds)
          FavoritesCompanion.insert(trackId: Value(id), addedAt: addedAt),
      ], mode: InsertMode.insertOrIgnore);
    });
  }

  Future<void> removeFavorites(List<int> trackIds) =>
      (delete(favorites)..where((f) => f.trackId.isIn(trackIds))).go();

  /// Removes [trackId] from favorites and returns the removed row (for
  /// undo), or null if it wasn't a favorite.
  Future<FavoriteRow?> removeFavorite(int trackId) => transaction(() async {
    final query = select(favorites)..where((f) => f.trackId.equals(trackId));
    final row = await query.getSingleOrNull();
    if (row != null) {
      await (delete(favorites)..where((f) => f.trackId.equals(trackId))).go();
    }
    return row;
  });

  /// Puts back a row returned by [removeFavorite], with its original time.
  Future<void> restoreFavorite(FavoriteRow row) =>
      into(favorites).insertOnConflictUpdate(row);

  /// Every playlist with its entries in order, by ID.
  Stream<List<StoredPlaylist>> watchPlaylists() {
    final query =
        select(playlists).join([
          leftOuterJoin(
            playlistEntries,
            playlistEntries.playlistId.equalsExp(playlists.id),
          ),
        ])..orderBy([
          OrderingTerm.asc(playlists.id),
          OrderingTerm.asc(playlistEntries.position),
        ]);
    return query.watch().map((rows) {
      final byId = <int, (PlaylistRow, List<int>)>{};
      for (final row in rows) {
        final playlist = row.readTable(playlists);
        final (_, ids) = byId[playlist.id] ??= (playlist, []);
        if (row.readTableOrNull(playlistEntries) case final entry?) {
          ids.add(entry.trackId);
        }
      }
      return [
        for (final (playlist, ids) in byId.values)
          StoredPlaylist(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description,
            trackIds: ids,
          ),
      ];
    });
  }

  /// Creates a playlist and returns its ID.
  ///
  /// Throws [DuplicateNameFailure] when another playlist has the same name,
  /// ignoring letter case and surrounding spaces.
  Future<int> createPlaylist(
    String name, {
    String? description,
    DateTime? at,
  }) => transaction(() async {
    final key = playlistNameKey(name);
    await _checkNameFree(key);
    final now = at ?? DateTime.now();
    return into(playlists).insert(
      PlaylistsCompanion.insert(
        name: name.trim(),
        nameKey: key,
        description: Value(_description(description)),
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  /// Renames playlist [id] and replaces its description.
  ///
  /// Throws [DuplicateNameFailure] like [createPlaylist].
  Future<void> renamePlaylist(
    int id,
    String name, {
    String? description,
    DateTime? at,
  }) => transaction(() async {
    final key = playlistNameKey(name);
    await _checkNameFree(key, except: id);
    await (update(playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(
        name: Value(name.trim()),
        nameKey: Value(key),
        description: Value(_description(description)),
        updatedAt: Value(at ?? DateTime.now()),
      ),
    );
  });

  /// Deletes playlist [id] and its entries.
  Future<void> deletePlaylist(int id) =>
      (delete(playlists)..where((p) => p.id.equals(id))).go();

  /// Adds [trackIds] to the end of playlist [id], skipping songs already in
  /// it (and repeats within [trackIds]). Returns how many were added.
  Future<int> addToPlaylist(int id, List<int> trackIds) =>
      transaction(() async {
        final stored = await _entryIds(id);
        final present = stored.toSet();
        final added = [
          for (final trackId in trackIds)
            if (present.add(trackId)) trackId,
        ];
        if (added.isEmpty) return 0;
        await batch((b) {
          b.insertAll(playlistEntries, [
            for (final (i, trackId) in added.indexed)
              PlaylistEntriesCompanion.insert(
                playlistId: id,
                trackId: trackId,
                position: stored.length + i,
              ),
          ]);
        });
        await _touch(id);
        return added.length;
      });

  /// Removes [trackId] from playlist [id] and returns where it was in the
  /// stored order (for [insertIntoPlaylist]), or null if it wasn't there.
  Future<int?> removeFromPlaylist(int id, int trackId) => transaction(() async {
    final stored = await _entryIds(id);
    final index = stored.indexOf(trackId);
    if (index < 0) return null;
    await (delete(
      playlistEntries,
    )..where((e) => e.playlistId.equals(id) & e.trackId.equals(trackId))).go();
    await _writeOrder(id, stored..removeAt(index));
    return index;
  });

  /// Puts [trackId] back into playlist [id] at [index] in the stored order
  /// (clamped). Does nothing if it is already there.
  Future<void> insertIntoPlaylist(int id, int trackId, int index) =>
      transaction(() async {
        final stored = await _entryIds(id);
        if (stored.contains(trackId)) return;
        final at = index.clamp(0, stored.length);
        await into(playlistEntries).insert(
          PlaylistEntriesCompanion.insert(
            playlistId: id,
            trackId: trackId,
            position: at,
          ),
        );
        await _writeOrder(id, stored..insert(at, trackId));
      });

  /// Saves a new order for playlist [id]. [trackIds] must hold exactly the
  /// playlist's songs.
  Future<void> setPlaylistOrder(int id, List<int> trackIds) =>
      transaction(() async {
        await _writeOrder(id, trackIds);
        await _touch(id);
      });

  Future<List<int>> _entryIds(int id) async {
    final query = select(playlistEntries)
      ..where((e) => e.playlistId.equals(id))
      ..orderBy([(e) => OrderingTerm.asc(e.position)]);
    return [for (final row in await query.get()) row.trackId];
  }

  /// Rewrites the positions of playlist [id] as 0, 1, 2, … in the order of
  /// [trackIds].
  Future<void> _writeOrder(int id, List<int> trackIds) => batch((b) {
    for (final (position, trackId) in trackIds.indexed) {
      b.update(
        playlistEntries,
        PlaylistEntriesCompanion(position: Value(position)),
        where: (e) => e.playlistId.equals(id) & e.trackId.equals(trackId),
      );
    }
  });

  Future<void> _touch(int id) =>
      (update(playlists)..where((p) => p.id.equals(id))).write(
        PlaylistsCompanion(updatedAt: Value(DateTime.now())),
      );

  Future<void> _checkNameFree(String key, {int? except}) async {
    final query = select(playlists)..where((p) => p.nameKey.equals(key));
    final existing = await query.getSingleOrNull();
    if (existing != null && existing.id != except) {
      throw DuplicateNameFailure('A playlist named "$key" already exists');
    }
  }

  static String? _description(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
