import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/account/data/backup_builder.dart';
import 'package:zema/features/lyrics/application/lyrics_prefs.dart';
import 'package:zema/features/settings/data/app_settings.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

void main() {
  late ZemaDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<int> track(String path, {String title = 'Song'}) => db
      .into(db.tracks)
      .insert(
        TracksCompanion.insert(
          mediaStoreId: path.hashCode,
          uri: 'content://media/${path.hashCode}',
          path: path,
          folder: path.substring(0, path.lastIndexOf('/')),
          title: title,
          durationMs: 200000,
          sizeBytes: 1000,
          dateAdded: DateTime.utc(2026),
        ),
      );

  Future<void> edit(int id, {String? title, String? cover}) =>
      db.libraryDao.setOverride(
        TrackOverrideRow(
          trackId: id,
          title: title,
          coverPath: cover,
          updatedAt: DateTime.utc(2026),
        ),
      );

  const fileSelam = TrackIdentity(
    title: 'Selam',
    durationMs: 200000,
    fileName: 'selam.mp3',
  );

  test('a backup holds the edits by the file\'s own tags, and the sync '
      'offsets', () async {
    SharedPreferences.setMockInitialValues({
      'lyricsOffset.rec-1': -500,
      'lyricsOffset.rec-2': 99000,
      'other': 1,
    });
    final prefs = await SharedPreferences.getInstance();
    final id = await track('/m/selam.mp3', title: 'Selam');
    final coverOnly = await track('/m/b.mp3', title: 'B');
    await edit(id, title: 'Selam (live)');
    await edit(coverOnly, cover: '/covers/b.jpg');
    await db.collectionsDao.addFavorite(id);

    final document = await backupBuilderOf(
      db,
      prefs,
    ).build(const AppSettings());
    expect(document.songInfo, [
      const BackupSongInfo(track: fileSelam, title: 'Selam (live)'),
    ], reason: 'a cover alone is not backed up');
    expect(document.favorites.single.track, fileSelam);
    expect(document.syncOffsets, {
      'rec-1': const Duration(milliseconds: -500),
      'rec-2': LyricsOffsetController.limit,
    });
    expect(BackupDocument.decode(document.encode()), document);
  });

  test('a restore adds edits for songs found without edits of their own, '
      'and offsets for recordings without one', () async {
    final selam = await track('/m/selam.mp3', title: 'Selam');
    final kept = await track('/m/kept.mp3', title: 'Kept');
    await edit(kept, title: 'Mine');
    final document = BackupDocument(
      createdAt: DateTime.utc(2026),
      songInfo: const [
        BackupSongInfo(track: fileSelam, title: 'Selam (live)', trackNumber: 3),
        BackupSongInfo(
          track: TrackIdentity(
            title: 'Kept',
            durationMs: 200000,
            fileName: 'kept.mp3',
          ),
          title: 'Theirs',
        ),
        BackupSongInfo(
          track: TrackIdentity(
            title: 'Gone',
            durationMs: 1000,
            fileName: 'gone.mp3',
          ),
          title: 'Nowhere',
        ),
      ],
    );
    await db.restoreDao.merge(document);
    final shown = await db.libraryDao.tracksByIds([selam, kept]);
    expect([for (final t in shown) t.title], ['Selam (live)', 'Mine']);
    expect(shown.first.trackNumber, 3);

    SharedPreferences.setMockInitialValues({'lyricsOffset.rec-1': 1000});
    final prefs = await SharedPreferences.getInstance();
    await restoreSyncOffsets(prefs, {
      'rec-1': const Duration(seconds: -2),
      'rec-2': const Duration(milliseconds: 1500),
    });
    expect(prefs.getInt('lyricsOffset.rec-1'), 1000, reason: 'own one kept');
    expect(prefs.getInt('lyricsOffset.rec-2'), 1500);
  });
}
