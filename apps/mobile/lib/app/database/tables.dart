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

/// Which lyrics song a track is. Automatic links are recomputed when the
/// library or the lyrics change; manual ones (the user's choice, including
/// "no lyrics" with [songId] null) are never overwritten.
@DataClassName('LyricsLinkRow')
class LyricsLinks extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  TextColumn get songId => text().nullable()();
  BoolColumn get manual => boolean()();
  DateTimeColumn get linkedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}

/// The catalog's song index (no lyrics), refreshed from the backend and kept
/// for offline linking and title search. Replaced whole on each refresh.
@DataClassName('CatalogSongRow')
class CatalogSongs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get transliteration => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  BoolColumn get synced => boolean()();
  IntColumn get version => integer()();
  DateTimeColumn get approvedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Lyrics downloaded from the catalog: one row per song holding its whole
/// document (song, recordings, timings) as JSON, so a song is saved in one
/// write and never partly.
@DataClassName('CachedSongRow')
class CachedSongs extends Table {
  TextColumn get id => text()();

  /// The catalog version the document was fetched at.
  IntColumn get version => integer()();

  /// [SongDocument.toJson], encoded.
  TextColumn get document => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Reports of wrong lyrics made offline, sent when the catalog can be
/// reached again.
@DataClassName('QueuedReportRow')
class QueuedReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get songId => text()();
  TextColumn get recordingId => text().nullable()();

  /// [ReportReason.name].
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
