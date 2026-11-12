import 'package:drift/drift.dart';

// Schema version 7. Every change after release needs a new schema version and
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

  /// The report's own UUID, sent with every try so the catalog stores it
  /// once.
  TextColumn get reportId => text()();
  TextColumn get songId => text()();
  TextColumn get recordingId => text().nullable()();

  /// [ReportReason.name].
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Backed-up entries whose song wasn't on this phone at restore. Kept so
/// the next backup still holds them, and added once a scan finds the song.
/// Cleared on sign-out and account deletion.
@DataClassName('UnmatchedEntryRow')
class UnmatchedEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// [BackupEntryKind.name].
  TextColumn get kind => text()();

  // The song's identity (see TrackIdentity).
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get durationMs => integer()();
  TextColumn get fileName => text()();

  /// A favorite's date.
  DateTimeColumn get addedAt => dateTime().nullable()();

  /// A playlist entry's playlist name and place.
  TextColumn get playlist => text().nullable()();
  IntColumn get position => integer().nullable()();

  /// A lyrics choice's song; null is "no lyrics".
  TextColumn get songId => text().nullable()();
}

/// Contributions in progress (intent 006), saved as the user works. Kept on
/// this phone only; deleted on sign-out, after a warning.
@DataClassName('DraftRow')
class Drafts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// [ContributionKind.wire].
  TextColumn get kind => text()();

  /// [DraftStep.name], for the list.
  TextColumn get step => text()();

  /// The song's title as typed, for the list; empty until typed.
  TextColumn get title => text()();

  /// The whole draft ([ContributionDraft.toJson]).
  TextColumn get draft => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// The user's own copy of each contribution they sent (intent 006), kept
/// until it is reviewed: when its track plays, this phone shows its lyrics
/// and timings marked Pending review. Other phones never see it. Cleared on
/// sign-out and account deletion.
@DataClassName('OwnCopyRow')
class OwnCopies extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The contribution's id on the backend.
  TextColumn get contributionId => text().unique()();

  /// [ContributionKind.wire].
  TextColumn get kind => text()();

  /// The lyrics as sent ([Song.toJson]).
  TextColumn get song => text()();

  /// [Recording.toJson] and [SyncTiming.toJson], when sent.
  TextColumn get recording => text().nullable()();
  TextColumn get timing => text().nullable()();

  /// The local track it was made for, if any.
  IntColumn get trackId => integer().nullable()();

  /// Zema's copy of a file shared to it, kept until the contribution is
  /// reviewed.
  TextColumn get audioPath => text().nullable()();
  DateTimeColumn get submittedAt => dateTime()();
}

/// Song info the user edited (S09) over a track's own tags: shown, sorted,
/// searched and matched instead of them. Null fields keep the file's value.
/// The file is never written, and backups still identify the track by its
/// own tags.
@DataClassName('TrackOverrideRow')
class TrackOverrides extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();

  /// A picked cover image, copied into the app's files.
  TextColumn get coverPath => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}

/// The audio fingerprint of a library file (intent 009), at the offline
/// density, so Listen can identify songs on the phone without the network.
/// [sizeBytes] and [version] tell when to fingerprint the file again.
@DataClassName('TrackFingerprintRow')
class TrackFingerprints extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();

  /// `fingerprintVersion` the bytes were made with.
  IntColumn get version => integer()();

  /// The file's size when fingerprinted.
  IntColumn get sizeBytes => integer()();

  /// `AudioFingerprint.toBytes`.
  BlobColumn get data => blob()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}
