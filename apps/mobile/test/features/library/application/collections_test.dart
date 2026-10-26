import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/collections_dao.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/library/application/favorites.dart';
import 'package:zema/features/library/application/library_providers.dart';
import 'package:zema/features/library/application/playlists.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

Track _track(int id, {String? album, String? albumArtist, int seconds = 60}) =>
    Track.fromScan(
      id,
      scannedAudio(
        id,
        '/m/$id.mp3',
        title: 'S$id',
        album: album,
        albumArtist: albumArtist,
        durationMs: seconds * 1000,
      ),
    );

Playlist _playlist(List<int> stored, List<Track> visible, {String? name}) =>
    Playlist.of(
      StoredPlaylist(
        id: 1,
        name: name ?? 'P',
        description: null,
        trackIds: stored,
      ),
      {for (final t in visible) t.id: t},
    );

void main() {
  group('Playlist', () {
    test('lists only visible songs but remembers all of them', () {
      final playlist = _playlist(
        [3, 9, 1],
        [_track(1, seconds: 30), _track(3, seconds: 90)],
      );

      expect([for (final t in playlist.tracks) t.id], [3, 1]);
      expect(playlist.storedIds, [3, 9, 1]);
      expect(playlist.contains(9), isTrue);
      expect(playlist.contains(2), isFalse);
      expect(playlist.duration, const Duration(minutes: 2));
    });

    test('collage: four albums give four covers, fewer give one', () {
      final four = [
        _track(1, album: 'A'),
        _track(2, album: 'A'),
        _track(3, album: 'B'),
        _track(4),
        _track(5, album: 'C'),
        _track(6, album: 'C', albumArtist: 'Other'),
        _track(7, album: 'D'),
      ];
      expect(
        [
          for (final t in _playlist([for (final t in four) t.id], four).covers)
            t.id,
        ],
        [1, 3, 4, 5],
      );

      // A, A, B and no album: three albums.
      final three = four.sublist(0, 4);
      expect(
        [
          for (final t in _playlist([
            for (final t in three) t.id,
          ], three).covers)
            t.id,
        ],
        [1],
      );
      expect(_playlist([], []).covers, isEmpty);
    });
  });

  group('checkPlaylistName', () {
    final playlists = [_playlist([], [], name: 'Kidase')];

    test('requires a name that is more than spaces', () {
      expect(checkPlaylistName('', playlists), PlaylistNameProblem.empty);
      expect(checkPlaylistName('   ', playlists), PlaylistNameProblem.empty);
    });

    test('rejects a taken name in any letter case', () {
      expect(
        checkPlaylistName(' KIDASE ', playlists),
        PlaylistNameProblem.duplicate,
      );
      expect(checkPlaylistName('Kidase 2', playlists), isNull);
    });

    test('a playlist may keep its own name when renamed', () {
      expect(checkPlaylistName('kidase', playlists, editing: 1), isNull);
    });
  });

  group('providers', () {
    late ZemaDatabase db;
    late ProviderContainer container;
    late List<int> ids;

    setUp(() async {
      db = memoryDatabase();
      final files = [for (var i = 1; i <= 4; i++) scannedAudio(i, '/m/$i.mp3')];
      await db.libraryDao.applyReconciliation(
        reconcileTracks(stored: const [], scan: files),
      );
      final tracks = await db.libraryDao.allTracks();
      ids = [for (final t in tracks) t.id];
      // Track 4 is hidden (or missing): not in the visible list.
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          libraryTracksProvider.overrideWith(
            (ref) => Stream.value(tracks.sublist(0, 3)),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    Future<T> read<T>(Provider<AsyncValue<T>> provider) async {
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      while (!container.read(provider).hasValue) {
        await Future<void>.delayed(Duration.zero);
      }
      return container.read(provider).requireValue;
    }

    test('favorites: visible ones newest first; hearts for all', () async {
      final dao = db.collectionsDao;
      await dao.addFavorite(ids[0], at: DateTime.utc(2026, 1, 1));
      await dao.addFavorite(ids[3], at: DateTime.utc(2026, 1, 2));
      await dao.addFavorite(ids[2], at: DateTime.utc(2026, 1, 3));

      final favorites = await read(favoritesProvider);
      expect([for (final t in favorites) t.id], [ids[2], ids[0]]);
      expect(container.read(isFavoriteProvider(ids[3])), isTrue);
      expect(container.read(isFavoriteProvider(ids[1])), isFalse);
    });

    test('favorites: remove returns an undo that restores the place', () async {
      final dao = db.collectionsDao;
      await dao.addFavorite(ids[0], at: DateTime.utc(2026, 1, 1));
      await dao.addFavorite(ids[1], at: DateTime.utc(2026, 1, 2));
      final controller = container.read(favoritesControllerProvider);

      final undo = await controller.remove(ids[0]);
      expect(await controller.remove(ids[0]), isNull);
      await controller.set(ids[2], favorite: true);
      await undo!();

      final rows = await dao.watchFavorites().first;
      expect([for (final r in rows) r.trackId], [ids[2], ids[1], ids[0]]);
    });

    test('playlists: by name, with hidden songs kept in place', () async {
      final controller = container.read(playlistsControllerProvider);
      final b = await controller.create('b list');
      final a = await controller.create('A list');
      await controller.add(b, [ids[0], ids[3], ids[1], ids[2]]);

      final all = await read(playlistsProvider);
      expect([for (final p in all) p.id], [a, b]);
      final playlist = all.last;
      expect([for (final t in playlist.tracks) t.id], [ids[0], ids[1], ids[2]]);

      // Move the first visible song to the end.
      await controller.reorder(playlist, [ids[1], ids[2], ids[0]]);
      final stored = (await db.collectionsDao.watchPlaylists().first)
          .singleWhere((p) => p.id == b)
          .trackIds;
      expect(stored, [ids[1], ids[3], ids[2], ids[0]]);

      Future<List<int>> entriesOfA() async =>
          (await db.collectionsDao.watchPlaylists().first)
              .singleWhere((p) => p.id == a)
              .trackIds;
      await controller.toggle(all.first, ids[0]);
      expect(await entriesOfA(), [ids[0]]);
      // Toggling again (the playlist now holds the song) removes it.
      final withSong = Playlist(
        id: a,
        name: 'A list',
        description: null,
        tracks: const [],
        storedIds: [ids[0]],
      );
      await controller.toggle(withSong, ids[0]);
      expect(await entriesOfA(), isEmpty);
    });
  });
}
