import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/features/account/data/backup_builder.dart';
import 'package:zema/features/settings/data/app_settings.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

void main() {
  late ZemaDatabase db;

  setUp(() => db = memoryDatabase());

  Future<int> track(
    String path, {
    String title = 'Song',
    String? artist,
    String? album,
    int durationMs = 200000,
  }) => db
      .into(db.tracks)
      .insert(
        TracksCompanion.insert(
          mediaStoreId: path.hashCode,
          uri: 'content://media/${path.hashCode}',
          path: path,
          folder: path.substring(0, path.lastIndexOf('/')),
          title: title,
          artist: Value(artist),
          album: Value(album),
          durationMs: durationMs,
          sizeBytes: 1000,
          dateAdded: DateTime.utc(2026),
        ),
      );

  const settings = AppSettings(
    palette: ZemaPalette.wine,
    themeMode: ThemeMode.dark,
    languageCode: 'am',
    minTrackSeconds: 10,
    sleepTimerDefault: SleepTimerDefault.minutes30,
    pauseOnUnplug: false,
    duckOnInterruption: true,
    gapless: false,
  );

  test('holds favorites, playlists, manual choices, hidden folders and '
      'songs, and settings', () async {
    final tizita = await track(
      '/storage/emulated/0/Music/Tizita.mp3',
      title: 'Tizita',
      artist: 'Mahmoud Ahmed',
      album: 'Ere Mela Mela',
      durationMs: 241000,
    );
    final ambassel = await track(
      '/storage/emulated/0/Music/Ambassel.flac',
      title: 'Ambassel',
      durationMs: 198500,
    );
    final memo = await track(
      '/storage/emulated/0/Recordings/memo.m4a',
      title: 'memo',
    );
    final auto = await track('/storage/emulated/0/Music/Auto.mp3');

    final collections = db.collectionsDao;
    await collections.addFavorite(tizita, at: DateTime.utc(2026, 1, 1));
    await collections.addFavorite(ambassel, at: DateTime.utc(2026, 2, 1));
    final morning = await collections.createPlaylist(
      'Morning',
      description: 'Slow ones',
      at: DateTime.utc(2026, 3, 1),
    );
    await collections.addToPlaylist(morning, [ambassel, tizita]);
    await collections.createPlaylist('Empty', at: DateTime.utc(2026, 4, 1));
    await db.lyricsLinksDao.setManual(tizita, 'song-tizita');
    await db.lyricsLinksDao.setManual(ambassel, null);
    await db.lyricsLinksDao.replaceAutomatic({auto: 'song-auto'});
    await db.libraryDao.hideFolder('/storage/emulated/0/Recordings');
    await db.libraryDao.hideFolder('/storage/1A2B-3C4D/Ringtones');
    await db.libraryDao.hideTrack(memo);
    await db.historyDao.recordPlay(tizita);

    final now = DateTime.utc(2026, 10, 30, 12);
    final document = await backupBuilderOf(db).build(settings, now: now);

    const tizitaId = TrackIdentity(
      title: 'Tizita',
      artist: 'Mahmoud Ahmed',
      album: 'Ere Mela Mela',
      durationMs: 241000,
      fileName: 'Tizita.mp3',
    );
    const ambasselId = TrackIdentity(
      title: 'Ambassel',
      durationMs: 198500,
      fileName: 'Ambassel.flac',
    );
    expect(document.createdAt, now);
    expect(document.favorites.map((f) => f.track), [tizitaId, ambasselId]);
    expect(document.favorites.first.addedAt, DateTime.utc(2026, 1, 1));
    expect(document.playlists.map((p) => p.name), ['Morning', 'Empty']);
    expect(document.playlists.first.description, 'Slow ones');
    expect(document.playlists.first.tracks, [ambasselId, tizitaId]);
    expect(document.playlists.last.tracks, isEmpty);
    expect(
      document.lyricsChoices,
      unorderedEquals(const [
        BackupLyricsChoice(track: tizitaId, songId: 'song-tizita'),
        BackupLyricsChoice(track: ambasselId),
      ]),
      reason: 'manual choices only, "no lyrics" included',
    );
    expect(document.hiddenFolders, ['Recordings', 'Ringtones']);
    expect(document.hiddenTracks.single.fileName, 'memo.m4a');
    expect(document.settings, {
      'palette': 'wine',
      'themeMode': 'dark',
      'language': 'am',
      'minTrackSeconds': 10,
      'sleepTimerDefault': 'minutes30',
      'pauseOnUnplug': false,
      'duckOnInterruption': true,
      'gapless': false,
    });
  });

  test('no path but file names, no history, no automatic links', () async {
    final id = await track('/storage/emulated/0/Music/Secret Folder/Song.mp3');
    await db.collectionsDao.addFavorite(id);
    await db.historyDao.recordPlay(id);
    await db.lyricsLinksDao.replaceAutomatic({id: 'song-auto'});

    final json = (await backupBuilderOf(db).build(settings)).encode();
    expect(json, isNot(contains('/storage')));
    expect(json, isNot(contains('Secret Folder')));
    expect(json, isNot(contains('content://')));
    expect(json, isNot(contains('song-auto')));
    expect(jsonDecode(json), isNot(contains('history')));
    expect(json, contains('"file":"Song.mp3"'));
  });

  test('an empty library gives an empty document with the settings', () async {
    final document = await backupBuilderOf(db).build(const AppSettings());
    expect(document.favorites, isEmpty);
    expect(document.playlists, isEmpty);
    expect(document.settings['themeMode'], 'system');
    expect(
      document.settings.containsKey('language'),
      isFalse,
      reason: 'following the phone is not saved',
    );
  });

  test('round-trips through JSON', () async {
    final id = await track('/storage/emulated/0/a/b.mp3', title: 'B');
    await db.collectionsDao.addFavorite(id);
    final document = await backupBuilderOf(db).build(settings);
    expect(BackupDocument.decode(document.encode()), document);
  });

  group('storageRelativePath', () {
    test('drops the storage volume', () {
      expect(
        storageRelativePath('/storage/emulated/0/Recordings'),
        'Recordings',
      );
      expect(storageRelativePath('/storage/emulated/10/A/B'), 'A/B');
      expect(storageRelativePath('/storage/1A2B-3C4D/Music'), 'Music');
      expect(storageRelativePath('/sdcard/Download'), 'Download');
      expect(storageRelativePath('/storage/emulated/0'), '');
    });

    test('keeps other paths whole', () {
      expect(storageRelativePath('/var/mobile/Music'), '/var/mobile/Music');
    });
  });

  group('settingsFromBackup', () {
    test('reads backupSettings back', () {
      expect(
        settingsFromBackup(backupSettings(settings), const AppSettings()),
        settings,
      );
    });

    test('missing, unknown or invalid values keep the current ones', () {
      expect(
        settingsFromBackup(const {
          'palette': 'neon',
          'themeMode': 7,
          'minTrackSeconds': 45,
          'gapless': 'yes',
          'futureSetting': true,
        }, settings),
        settings,
      );
    });
  });
}
