// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unmatched_dao.dart';

// ignore_for_file: type=lint
mixin _$UnmatchedDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $UnmatchedEntriesTable get unmatchedEntries =>
      attachedDatabase.unmatchedEntries;
  UnmatchedDaoManager get managers => UnmatchedDaoManager(this);
}

class UnmatchedDaoManager {
  final _$UnmatchedDaoMixin _db;
  UnmatchedDaoManager(this._db);
  $$UnmatchedEntriesTableTableManager get unmatchedEntries =>
      $$UnmatchedEntriesTableTableManager(
        _db.attachedDatabase,
        _db.unmatchedEntries,
      );
}
