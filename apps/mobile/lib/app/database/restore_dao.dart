import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'restore_dao.g.dart';

/// What a restore added to this phone.
class RestoreReport {
  const RestoreReport({
    this.favoritesAdded = 0,
    this.playlistsCreated = 0,
    this.playlistSongsAdded = 0,
    this.lyricsChoicesAdded = 0,
    this.hiddenAdded = 0,
    this.notFound = const [],
  });

  final int favoritesAdded;
  final int playlistsCreated;

  /// Songs added to playlists, new or existing.
  final int playlistSongsAdded;
  final int lyricsChoicesAdded;

  /// Hidden folders and songs added.
  final int hiddenAdded;

  /// Backed-up entries whose song isn't on this phone.
  final List<UnmatchedEntry> notFound;

  /// The songs not found, each once, in backup order.
  List<TrackIdentity> get songsNotFound => [
    ...{for (final entry in notFound) entry.track},
  ];
}

/// Merges a backup into the library. Nothing on the phone is removed.
@DriftAccessor(
  tables: [
    Tracks,
    Favorites,
    Playlists,
    PlaylistEntries,
    LyricsLinks,
    HiddenFolders,
    HiddenTracks,
  ],
)
class RestoreDao extends DatabaseAccessor<ZemaDatabase> with _$RestoreDaoMixin {
  RestoreDao(super.attachedDatabase);

  /// Merges [document] into the library in one transaction, matching its
  /// songs with [BackupTrackMatcher]:
  /// - favorites are added (with their dates);
  /// - a playlist with the same name gets its missing songs at the end;
  ///   other playlists are created;
  /// - lyrics choices are added where the song has none made by hand;
  /// - hidden folders and songs are added.
  ///
  /// [keepUnmatched] runs inside the transaction with the entries not
  /// found. If anything throws, nothing changes.
  Future<RestoreReport> merge(
    BackupDocument document, {
    Future<void> Function(List<UnmatchedEntry> notFound)? keepUnmatched,
    DateTime? now,
  }) => transaction(() async {
    final at = (now ?? DateTime.now()).toUtc();
    final rows = await select(tracks).get();
    final matcher = BackupTrackMatcher(rows.map(_toTrack));
    final notFound = <UnmatchedEntry>[];

    // Favorites.
    final favorite = {
      for (final row in await select(favorites).get()) row.trackId,
    };
    var favoritesAdded = 0;
    for (final entry in document.favorites) {
      final track = matcher.match(entry.track);
      if (track == null) {
        notFound.add(
          UnmatchedEntry.favorite(entry.track, addedAt: entry.addedAt),
        );
      } else if (favorite.add(track.id)) {
        await into(favorites).insert(
          FavoritesCompanion.insert(
            trackId: Value(track.id),
            addedAt: entry.addedAt,
          ),
        );
        favoritesAdded++;
      }
    }

    // Playlists.
    var playlistsCreated = 0;
    var playlistSongsAdded = 0;
    for (final playlist in document.playlists) {
      final key = playlistNameKey(playlist.name);
      if (key.isEmpty) continue;
      final existing = await (select(
        playlists,
      )..where((p) => p.nameKey.equals(key))).getSingleOrNull();
      final int id;
      final List<int> entries;
      if (existing == null) {
        id = await into(playlists).insert(
          PlaylistsCompanion.insert(
            name: playlist.name.trim(),
            nameKey: key,
            description: Value(playlist.description),
            createdAt: playlist.createdAt ?? at,
            updatedAt: at,
          ),
        );
        entries = [];
        playlistsCreated++;
      } else {
        id = existing.id;
        entries = [
          for (final row
              in await (select(playlistEntries)
                    ..where((e) => e.playlistId.equals(id))
                    ..orderBy([(e) => OrderingTerm.asc(e.position)]))
                  .get())
            row.trackId,
        ];
      }
      final present = entries.toSet();
      final added = <int>[];
      for (final (position, identity) in playlist.tracks.indexed) {
        final track = matcher.match(identity);
        if (track == null) {
          notFound.add(
            UnmatchedEntry.playlist(
              identity,
              playlist: playlist.name.trim(),
              position: position,
            ),
          );
        } else if (present.add(track.id)) {
          added.add(track.id);
        }
      }
      if (added.isEmpty) continue;
      await batch(
        (b) => b.insertAll(playlistEntries, [
          for (final (i, trackId) in added.indexed)
            PlaylistEntriesCompanion.insert(
              playlistId: id,
              trackId: trackId,
              position: entries.length + i,
            ),
        ]),
      );
      if (existing != null) {
        await (update(playlists)..where((p) => p.id.equals(id))).write(
          PlaylistsCompanion(updatedAt: Value(at)),
        );
      }
      playlistSongsAdded += added.length;
    }

    // Lyrics choices made by hand.
    final manual = {
      for (final row in await (select(
        lyricsLinks,
      )..where((l) => l.manual)).get())
        row.trackId,
    };
    var lyricsChoicesAdded = 0;
    for (final choice in document.lyricsChoices) {
      final track = matcher.match(choice.track);
      if (track == null) {
        notFound.add(
          UnmatchedEntry.lyricsChoice(choice.track, songId: choice.songId),
        );
      } else if (manual.add(track.id)) {
        await into(lyricsLinks).insertOnConflictUpdate(
          LyricsLinksCompanion.insert(
            trackId: Value(track.id),
            songId: Value(choice.songId),
            manual: true,
            linkedAt: at,
          ),
        );
        lyricsChoicesAdded++;
      }
    }

    // Hidden folders and songs.
    var hiddenAdded = 0;
    final hiddenPaths = {
      for (final row in await select(hiddenFolders).get()) row.path,
    };
    final folders = _foldersAndParents(rows.map((r) => r.folder));
    for (final relative in document.hiddenFolders) {
      for (final path in _hiddenFolderPaths(relative, folders)) {
        if (!hiddenPaths.add(path)) continue;
        await into(hiddenFolders)
            .insert(HiddenFoldersCompanion.insert(path: path, hiddenAt: at));
        hiddenAdded++;
      }
    }
    final hiddenIds = {
      for (final row in await select(hiddenTracks).get()) row.trackId,
    };
    for (final identity in document.hiddenTracks) {
      final track = matcher.match(identity);
      if (track == null) {
        notFound.add(UnmatchedEntry.hiddenTrack(identity));
      } else if (hiddenIds.add(track.id)) {
        await into(hiddenTracks).insert(
          HiddenTracksCompanion.insert(trackId: Value(track.id), hiddenAt: at),
        );
        hiddenAdded++;
      }
    }

    await keepUnmatched?.call(notFound);
    return RestoreReport(
      favoritesAdded: favoritesAdded,
      playlistsCreated: playlistsCreated,
      playlistSongsAdded: playlistSongsAdded,
      lyricsChoicesAdded: lyricsChoicesAdded,
      hiddenAdded: hiddenAdded,
      notFound: notFound,
    );
  });

  /// Every folder in [folders] and all of their parents.
  static Set<String> _foldersAndParents(Iterable<String> folders) {
    final all = <String>{};
    for (var folder in folders) {
      while (folder.length > 1 && all.add(folder)) {
        final slash = folder.lastIndexOf('/');
        if (slash <= 0) break;
        folder = folder.substring(0, slash);
      }
    }
    return all;
  }

  /// The folders on this phone that the backup's [relative] folder names
  /// (see `storageRelativePath`). None yet: the same folder on the main
  /// storage, so it is hidden when it appears.
  static Iterable<String> _hiddenFolderPaths(
    String relative,
    Set<String> folders,
  ) {
    if (relative.isEmpty) return const [];
    if (relative.startsWith('/')) return [relative];
    final found = [
      for (final folder in folders)
        if (storageRelativePath(folder) == relative) folder,
    ];
    return found.isEmpty ? ['/storage/emulated/0/$relative'] : found;
  }

  static Track _toTrack(TrackRow r) => Track(
    id: r.id,
    mediaStoreId: r.mediaStoreId,
    uri: r.uri,
    path: r.path,
    title: r.title,
    artist: r.artist,
    album: r.album,
    duration: Duration(milliseconds: r.durationMs),
    sizeBytes: r.sizeBytes,
    dateAdded: r.dateAdded,
    missing: r.missing,
  );
}
