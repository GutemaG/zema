import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/cached_songs_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

SongDocument _document(String id, {String line = 'Amen'}) => SongDocument(
  song: Song(
    id: id,
    title: id.toUpperCase(),
    transliteration: '$id-latin',
    artist: 'Choir',
    sections: [
      LyricSection(id: 'v1', kind: SectionKind.verse, lines: [LyricLine(line)]),
    ],
  ),
  recordings: [
    Recording(id: '$id-r', songId: id, source: RecordingSource.localFile),
  ],
  timings: [
    SyncTiming(recordingId: '$id-r', starts: const [Duration(seconds: 1)]),
  ],
);

void main() {
  late ZemaDatabase db;

  setUp(() => db = ZemaDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('starts empty', () async {
    expect(await db.cachedSongsDao.song('selam'), isNull);
    expect(await db.cachedSongsDao.watchSongs().first, isEmpty);
  });

  test('a saved song reads back whole, with its version and time', () async {
    final at = DateTime.utc(2026, 10, 29, 10);
    await withClock(
      Clock.fixed(at),
      () => db.cachedSongsDao.save(_document('selam'), 3),
    );

    final cached = (await db.cachedSongsDao.song('selam'))!;
    expect(cached.version, 3);
    expect(cached.document.toJson(), _document('selam').toJson());
    final row = await db.select(db.cachedSongs).getSingle();
    expect(row.cachedAt, at);
  });

  test('saving again replaces the old copy', () async {
    await db.cachedSongsDao.save(_document('selam'), 1);
    await db.cachedSongsDao.save(_document('selam', line: 'Haleluya'), 2);

    final cached = (await db.cachedSongsDao.song('selam'))!;
    expect(cached.version, 2);
    expect(cached.document.song.sections.single.lines.single.text, 'Haleluya');
    expect(await db.select(db.cachedSongs).get(), hasLength(1));
  });

  test('watchSongs lists every song by ID and emits after a save', () async {
    final emitted = <List<String>>[];
    final sub = db.cachedSongsDao.watchSongs().listen(
      (songs) => emitted.add([for (final s in songs) s.document.song.id]),
    );
    await pumpEventQueue();
    await db.cachedSongsDao.save(_document('selam'), 1);
    await pumpEventQueue();
    await db.cachedSongsDao.save(_document('amlak'), 1);
    await pumpEventQueue();
    await sub.cancel();

    expect(emitted, [
      <String>[],
      ['selam'],
      ['amlak', 'selam'],
    ]);
  });

  test('a row that no longer decodes counts as not cached', () async {
    await db.cachedSongsDao.save(_document('amlak'), 1);
    await db
        .into(db.cachedSongs)
        .insert(
          CachedSongsCompanion.insert(
            id: 'broken',
            version: 1,
            document: '{"song": 42}',
            cachedAt: DateTime.utc(2026),
          ),
        );

    expect(await db.cachedSongsDao.song('broken'), isNull);
    final listed = await db.cachedSongsDao.watchSongs().first;
    expect([for (final s in listed) s.document.song.id], ['amlak']);
  });

  test(
    'usage counts songs and their bytes, and follows saves and clear',
    () async {
      final dao = db.cachedSongsDao;
      final usage = <LyricsUsage>[];
      final sub = dao.watchUsage().listen(usage.add);
      addTearDown(sub.cancel);
      Future<LyricsUsage> settled() async {
        await pumpEventQueue();
        return usage.last;
      }

      expect(await settled(), (songs: 0, bytes: 0));
      await dao.save(_document('selam'), 1);
      await dao.save(_document('amlak'), 1);
      final bytes =
          jsonEncode(_document('selam').toJson()).length +
          jsonEncode(_document('amlak').toJson()).length;
      expect(await settled(), (songs: 2, bytes: bytes));

      await dao.clear();
      expect(await settled(), (songs: 0, bytes: 0));
      expect(await dao.song('selam'), isNull);
    },
  );
}
