// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_links_dao.dart';

// ignore_for_file: type=lint
mixin _$LyricsLinksDaoMixin on DatabaseAccessor<ZemaDatabase> {
  $TracksTable get tracks => attachedDatabase.tracks;
  $LyricsLinksTable get lyricsLinks => attachedDatabase.lyricsLinks;
  LyricsLinksDaoManager get managers => LyricsLinksDaoManager(this);
}

class LyricsLinksDaoManager {
  final _$LyricsLinksDaoMixin _db;
  LyricsLinksDaoManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$LyricsLinksTableTableManager get lyricsLinks =>
      $$LyricsLinksTableTableManager(_db.attachedDatabase, _db.lyricsLinks);
}
