import 'package:drift/drift.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'backup_dao.g.dart';

/// A playlist and its songs in order, for a backup.
typedef BackupPlaylistRows = ({PlaylistRow playlist, List<TrackRow> tracks});

/// Everything a backup holds from the database, read at one moment.
class BackupRows {
  const BackupRows({
    required this.favorites,
    required this.playlists,
    required this.manualLinks,
    required this.hiddenFolders,
    required this.hiddenTracks,
  });

  /// Oldest first.
  final List<({TrackRow track, DateTime addedAt})> favorites;
  final List<BackupPlaylistRows> playlists;

  /// Lyrics chosen by hand: the song ID, or null for "no lyrics".
  final List<({TrackRow track, String? songId})> manualLinks;
  final List<String> hiddenFolders;
  final List<TrackRow> hiddenTracks;
}

/// Reads the user's library data for a backup.
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
class BackupDao extends DatabaseAccessor<ZemaDatabase> with _$BackupDaoMixin {
  BackupDao(super.attachedDatabase);

  /// Favorites, playlists, manual lyrics links and hidden folders and
  /// songs, in one transaction so they agree with each other.
  Future<BackupRows> read() => transaction(() async {
    final favoriteRows = await (select(favorites).join([
      innerJoin(tracks, tracks.id.equalsExp(favorites.trackId)),
    ])..orderBy([OrderingTerm.asc(favorites.addedAt)])).get();
    final playlistRows = await (select(
      playlists,
    )..orderBy([(p) => OrderingTerm.asc(p.createdAt)])).get();
    final entryRows =
        await (select(playlistEntries).join([
              innerJoin(tracks, tracks.id.equalsExp(playlistEntries.trackId)),
            ])..orderBy([
              OrderingTerm.asc(playlistEntries.playlistId),
              OrderingTerm.asc(playlistEntries.position),
            ]))
            .get();
    final entries = <int, List<TrackRow>>{};
    for (final row in entryRows) {
      entries
          .putIfAbsent(row.readTable(playlistEntries).playlistId, () => [])
          .add(row.readTable(tracks));
    }
    final linkRows = await (select(lyricsLinks).join([
      innerJoin(tracks, tracks.id.equalsExp(lyricsLinks.trackId)),
    ])..where(lyricsLinks.manual)).get();
    final hiddenTrackRows = await (select(hiddenTracks).join([
      innerJoin(tracks, tracks.id.equalsExp(hiddenTracks.trackId)),
    ])..orderBy([OrderingTerm.asc(hiddenTracks.hiddenAt)])).get();
    return BackupRows(
      favorites: [
        for (final row in favoriteRows)
          (
            track: row.readTable(tracks),
            addedAt: row.readTable(favorites).addedAt,
          ),
      ],
      playlists: [
        for (final playlist in playlistRows)
          (playlist: playlist, tracks: entries[playlist.id] ?? const []),
      ],
      manualLinks: [
        for (final row in linkRows)
          (
            track: row.readTable(tracks),
            songId: row.readTable(lyricsLinks).songId,
          ),
      ],
      hiddenFolders: [
        for (final row in await (select(
          hiddenFolders,
        )..orderBy([(h) => OrderingTerm.asc(h.hiddenAt)])).get())
          row.path,
      ],
      hiddenTracks: [for (final row in hiddenTrackRows) row.readTable(tracks)],
    );
  });
}
