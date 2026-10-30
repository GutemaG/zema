import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/account/application/account_providers.dart';
import 'package:zema/features/account/application/profile.dart';
import 'package:zema/features/account/application/restore.dart';
import 'package:zema/features/account/data/backup_builder.dart';
import 'package:zema/features/settings/application/settings_bootstrap.dart';
import 'package:zema/features/settings/data/app_settings.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';

TrackIdentity id(String file, {int ms = 200000}) => TrackIdentity(
  title: file.substring(0, file.lastIndexOf('.')),
  durationMs: ms,
  fileName: file,
);

void main() {
  late ZemaDatabase db;
  final created = DateTime.utc(2026, 10, 30);

  setUp(() => db = memoryDatabase());

  Future<int> track(String file, {int ms = 200000}) => db
      .into(db.tracks)
      .insert(
        TracksCompanion.insert(
          mediaStoreId: file.hashCode,
          uri: 'content://$file',
          path: '/storage/emulated/0/Music/$file',
          folder: '/storage/emulated/0/Music',
          title: file.substring(0, file.lastIndexOf('.')),
          durationMs: ms,
          sizeBytes: 1,
          dateAdded: DateTime.utc(2026),
        ),
      );

  final everyKind = [
    UnmatchedEntry.favorite(id('fav.mp3'), addedAt: DateTime.utc(2026, 1)),
    UnmatchedEntry.playlist(id('pl.mp3'), playlist: 'Morning', position: 1),
    UnmatchedEntry.lyricsChoice(id('ly.mp3'), songId: 'song-1'),
    UnmatchedEntry.lyricsChoice(id('none.mp3')),
    UnmatchedEntry.hiddenTrack(id('hid.mp3')),
  ];

  group('UnmatchedDao', () {
    test('keeps every kind exactly', () async {
      await db.unmatchedDao.addAll(everyKind);
      expect(await db.unmatchedDao.all(), everyKind);
    });

    test('adding the same entries again keeps one of each', () async {
      await db.unmatchedDao.addAll(everyKind);
      await db.unmatchedDao.addAll(everyKind);
      expect(await db.unmatchedDao.all(), everyKind);
    });

    test('replaceAll and clear', () async {
      await db.unmatchedDao.addAll(everyKind);
      await db.unmatchedDao.replaceAll(everyKind.take(2).toList());
      expect(await db.unmatchedDao.all(), everyKind.take(2));
      await db.unmatchedDao.clear();
      expect(await db.unmatchedDao.all(), isEmpty);
    });
  });

  group('the next backup holds them', () {
    test('favorites, choices and hidden songs are added; playlist entries '
        'go back to their place', () async {
      final a = await track('a.mp3');
      final b = await track('b.mp3');
      await db.collectionsDao.addFavorite(a, at: created);
      final morning = await db.collectionsDao.createPlaylist('morning');
      await db.collectionsDao.addToPlaylist(morning, [a, b]);
      await db.unmatchedDao.addAll([
        ...everyKind,
        UnmatchedEntry.playlist(
          id('end.mp3'),
          playlist: 'Morning',
          position: 9,
        ),
        UnmatchedEntry.playlist(id('x.mp3'), playlist: 'Deleted', position: 0),
        // Already in the library's own entries: not added twice.
        UnmatchedEntry.favorite(id('a.mp3'), addedAt: DateTime.utc(2020)),
      ]);

      final document = await backupBuilderOf(db).build(const AppSettings());

      expect(document.favorites.map((f) => f.track.fileName), [
        'a.mp3',
        'fav.mp3',
      ]);
      expect(document.favorites.last.addedAt, DateTime.utc(2026, 1));
      expect(document.playlists.single.tracks.map((t) => t.fileName), [
        'a.mp3',
        'pl.mp3',
        'b.mp3',
        'end.mp3',
      ]);
      expect(document.lyricsChoices, [
        BackupLyricsChoice(track: id('ly.mp3'), songId: 'song-1'),
        BackupLyricsChoice(track: id('none.mp3')),
      ]);
      expect(document.hiddenTracks, [id('hid.mp3')]);
      expect(document.encode(), isNot(contains('Deleted')));
    });
  });

  group('retryUnmatched', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          ...await loadSettingsOverrides(),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
    });

    Future<int> retry() =>
        container.read(backupRestorerProvider).retryUnmatched();

    test('songs that showed up are added and no longer kept', () async {
      final morning = await db.collectionsDao.createPlaylist('Morning');
      final local = await track('local.mp3');
      await db.collectionsDao.addToPlaylist(morning, [local]);
      await db.unmatchedDao.addAll(everyKind);
      expect(await retry(), 0, reason: 'nothing is on the phone yet');
      expect(await db.unmatchedDao.all(), everyKind);

      final fav = await track('fav.mp3');
      final pl = await track('pl.mp3');
      final ly = await track('ly.mp3');

      expect(await retry(), 3);
      expect(
        {for (final r in await db.select(db.favorites).get()) r.trackId},
        {fav},
      );
      final stored = await db.collectionsDao.watchPlaylists().first;
      expect(stored.single.trackIds, [local, pl]);
      final links = await db.select(db.lyricsLinks).get();
      expect(links.single.trackId, ly);
      expect(links.single.songId, 'song-1');
      expect(links.single.manual, isTrue);
      expect(await db.unmatchedDao.all(), [
        everyKind[3], // none.mp3
        everyKind[4], // hid.mp3
      ]);
    });

    test('entries of a playlist deleted on this phone are dropped', () async {
      await db.unmatchedDao.addAll([
        UnmatchedEntry.playlist(id('pl.mp3'), playlist: 'Gone', position: 0),
        UnmatchedEntry.favorite(id('fav.mp3'), addedAt: created),
      ]);
      await retry();
      expect(await db.unmatchedDao.all(), [
        UnmatchedEntry.favorite(id('fav.mp3'), addedAt: created),
      ]);
      expect(await db.select(db.playlists).get(), isEmpty);
    });

    test('kept playlist entries keep their original place', () async {
      await db.collectionsDao.createPlaylist('Morning');
      final entry = UnmatchedEntry.playlist(
        id('pl.mp3'),
        playlist: 'Morning',
        position: 7,
      );
      await db.unmatchedDao.addAll([entry]);
      await retry();
      expect(await db.unmatchedDao.all(), [entry]);
    });

    test('a restore keeps the entries not found', () async {
      await container
          .read(backupRestorerProvider)
          .restore(
            BackupDocument(
              createdAt: created,
              favorites: [
                BackupFavorite(track: id('fav.mp3'), addedAt: created),
              ],
            ),
          );
      expect(await db.unmatchedDao.all(), [
        UnmatchedEntry.favorite(id('fav.mp3'), addedAt: created),
      ]);
    });
  });

  group('cleared with the account', () {
    late FakeAuthRepository auth;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      auth = FakeAuthRepository(user: testUser);
      container = ProviderContainer(
        overrides: [
          ...await loadSettingsOverrides(),
          databaseProvider.overrideWithValue(db),
          ...accountOverrides(auth: auth),
        ],
      );
      addTearDown(container.dispose);
      container
        ..listen(accountActionsProvider, (_, _) {})
        // Listened, or Riverpod pauses it and the restore never runs.
        ..listen(authUserProvider, (_, _) {});
      await container.read(authUserProvider.future);
      await db.unmatchedDao.addAll(everyKind);
    });

    test('on sign-out', () async {
      await container.read(accountActionsProvider.notifier).signOut();
      expect(await db.unmatchedDao.all(), isEmpty);
    });

    test('on delete account', () async {
      await container.read(accountActionsProvider.notifier).deleteAccount();
      expect(await db.unmatchedDao.all(), isEmpty);
    });

    test('not when delete fails', () async {
      auth.deleteFailure = const NetworkFailure('offline');
      await expectLater(
        container.read(accountActionsProvider.notifier).deleteAccount(),
        throwsA(isA<NetworkFailure>()),
      );
      expect(await db.unmatchedDao.all(), everyKind);
    });
  });
}
