// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restore_dao.dart';

// ignore_for_file: type=lint
mixin _$RestoreDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $TracksTable get tracks => attachedDatabase.tracks;
  $FavoritesTable get favorites => attachedDatabase.favorites;
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $PlaylistEntriesTable get playlistEntries => attachedDatabase.playlistEntries;
  $LyricsLinksTable get lyricsLinks => attachedDatabase.lyricsLinks;
  $HiddenFoldersTable get hiddenFolders => attachedDatabase.hiddenFolders;
  $HiddenTracksTable get hiddenTracks => attachedDatabase.hiddenTracks;
  $TrackOverridesTable get trackOverrides => attachedDatabase.trackOverrides;
  RestoreDaoManager get managers => RestoreDaoManager(this);
}

class RestoreDaoManager {
  final _$RestoreDaoMixin _db;
  RestoreDaoManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db.attachedDatabase, _db.favorites);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
  $$PlaylistEntriesTableTableManager get playlistEntries =>
      $$PlaylistEntriesTableTableManager(
        _db.attachedDatabase,
        _db.playlistEntries,
      );
  $$LyricsLinksTableTableManager get lyricsLinks =>
      $$LyricsLinksTableTableManager(_db.attachedDatabase, _db.lyricsLinks);
  $$HiddenFoldersTableTableManager get hiddenFolders =>
      $$HiddenFoldersTableTableManager(_db.attachedDatabase, _db.hiddenFolders);
  $$HiddenTracksTableTableManager get hiddenTracks =>
      $$HiddenTracksTableTableManager(_db.attachedDatabase, _db.hiddenTracks);
  $$TrackOverridesTableTableManager get trackOverrides =>
      $$TrackOverridesTableTableManager(
        _db.attachedDatabase,
        _db.trackOverrides,
      );
}
