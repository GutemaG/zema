import 'package:drift/drift.dart';

// Schema version 1. Every change after release needs a new schema version and
// a migration step: run `dart run drift_dev make-migrations` from apps/mobile.

/// Local audio files Zema has seen. Rows are never deleted by a scan: a file
/// that disappears is marked [missing] so its favorites and playlist entries
/// come back with it.
@DataClassName('TrackRow')
@TableIndex(name: 'tracks_folder', columns: {#folder})
class Tracks extends Table {
  /// Zema's own ID, stable across rescans (see `reconcileTracks`).
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mediaStoreId => integer()();
  TextColumn get uri => text()();
  TextColumn get path => text().unique()();

  /// Parent folder of [path], stored so folder queries can use an index.
  TextColumn get folder => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get year => integer().nullable()();
  IntColumn get durationMs => integer()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get dateAdded => dateTime()();
  BoolColumn get missing => boolean().withDefault(const Constant(false))();
}

/// Folders hidden from the whole library, subfolders included.
@DataClassName('HiddenFolderRow')
class HiddenFolders extends Table {
  TextColumn get path => text()();
  DateTimeColumn get hiddenAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

/// Single songs hidden from the whole library.
@DataClassName('HiddenTrackRow')
class HiddenTracks extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get hiddenAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}

@DataClassName('FavoriteRow')
class Favorites extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}

@DataClassName('PlaylistRow')
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// [name] trimmed and lowercased; unique, so names can't repeat in any
  /// letter case.
  TextColumn get nameKey => text().unique()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// A song at a position in a playlist. A song appears at most once per
/// playlist.
@DataClassName('PlaylistEntryRow')
@TableIndex(name: 'playlist_entries_order', columns: {#playlistId, #position})
class PlaylistEntries extends Table {
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {playlistId, trackId};
}

/// One counted play of a track; feeds Most played and Recently played.
@DataClassName('PlayEventRow')
@TableIndex(name: 'play_events_track', columns: {#trackId})
@TableIndex(name: 'play_events_time', columns: {#playedAt})
class PlayEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get playedAt => dateTime()();
}
