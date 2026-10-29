// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_dao.dart';

// ignore_for_file: type=lint
mixin _$CatalogDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $CatalogSongsTable get catalogSongs => attachedDatabase.catalogSongs;
  CatalogDaoManager get managers => CatalogDaoManager(this);
}

class CatalogDaoManager {
  final _$CatalogDaoMixin _db;
  CatalogDaoManager(this._db);
  $$CatalogSongsTableTableManager get catalogSongs =>
      $$CatalogSongsTableTableManager(_db.attachedDatabase, _db.catalogSongs);
}
