// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'own_copies_dao.dart';

// ignore_for_file: type=lint
mixin _$OwnCopiesDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $OwnCopiesTable get ownCopies => attachedDatabase.ownCopies;
  OwnCopiesDaoManager get managers => OwnCopiesDaoManager(this);
}

class OwnCopiesDaoManager {
  final _$OwnCopiesDaoMixin _db;
  OwnCopiesDaoManager(this._db);
  $$OwnCopiesTableTableManager get ownCopies =>
      $$OwnCopiesTableTableManager(_db.attachedDatabase, _db.ownCopies);
}
