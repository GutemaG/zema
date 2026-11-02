// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_dao.dart';

// ignore_for_file: type=lint
mixin _$LibraryDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $TracksTable get tracks => attachedDatabase.tracks;
  $HiddenFoldersTable get hiddenFolders => attachedDatabase.hiddenFolders;
  $HiddenTracksTable get hiddenTracks => attachedDatabase.hiddenTracks;
  $TrackOverridesTable get trackOverrides => attachedDatabase.trackOverrides;
  LibraryDaoManager get managers => LibraryDaoManager(this);
}

class LibraryDaoManager {
  final _$LibraryDaoMixin _db;
  LibraryDaoManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
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
