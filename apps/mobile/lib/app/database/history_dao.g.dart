// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_dao.dart';

// ignore_for_file: type=lint
mixin _$HistoryDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $TracksTable get tracks => attachedDatabase.tracks;
  $PlayEventsTable get playEvents => attachedDatabase.playEvents;
  HistoryDaoManager get managers => HistoryDaoManager(this);
}

class HistoryDaoManager {
  final _$HistoryDaoMixin _db;
  HistoryDaoManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$PlayEventsTableTableManager get playEvents =>
      $$PlayEventsTableTableManager(_db.attachedDatabase, _db.playEvents);
}
