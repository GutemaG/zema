// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identified_dao.dart';

// ignore_for_file: type=lint
mixin _$IdentifiedDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $TracksTable get tracks => attachedDatabase.tracks;
  $IdentifiedSongsTable get identifiedSongs => attachedDatabase.identifiedSongs;
  IdentifiedDaoManager get managers => IdentifiedDaoManager(this);
}

class IdentifiedDaoManager {
  final _$IdentifiedDaoMixin _db;
  IdentifiedDaoManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$IdentifiedSongsTableTableManager get identifiedSongs =>
      $$IdentifiedSongsTableTableManager(
        _db.attachedDatabase,
        _db.identifiedSongs,
      );
}
