// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_songs_dao.dart';

// ignore_for_file: type=lint
mixin _$CachedSongsDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $CachedSongsTable get cachedSongs => attachedDatabase.cachedSongs;
  CachedSongsDaoManager get managers => CachedSongsDaoManager(this);
}

class CachedSongsDaoManager {
  final _$CachedSongsDaoMixin _db;
  CachedSongsDaoManager(this._db);
  $$CachedSongsTableTableManager get cachedSongs =>
      $$CachedSongsTableTableManager(_db.attachedDatabase, _db.cachedSongs);
}
