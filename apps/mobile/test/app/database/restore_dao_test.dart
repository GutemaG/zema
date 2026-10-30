import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/features/account/application/restore.dart';
import 'package:zema/features/settings/application/settings_bootstrap.dart';
import 'package:zema/features/settings/application/settings_controller.dart';
import 'package:zema/features/settings/data/app_settings.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

void main() {
  late ZemaDatabase db;

  setUp(() => db = memoryDatabase());

  Future<int> track(
    String path, {
    String? title,
    String? artist,
    int ms = 200000,
  }) {
    final name = fileNameOf(path);
    return db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            mediaStoreId: path.hashCode,
            uri: 'content://$path',
            path: path,
            folder: path.substring(0, path.lastIndexOf('/')),
            title: title ?? name.substring(0, name.lastIndexOf('.')),
            artist: Value(artist),
            durationMs: ms,
            sizeBytes: 1,
            dateAdded: DateTime.utc(2026),
          ),
        );
  }

  TrackIdentity id(
    String file, {
    String? title,
    String? artist,
    int ms = 200000,
  }) => TrackIdentity(
    title: title ?? file.substring(0, file.lastIndexOf('.')),
    artist: artist,
    durationMs: ms,
    fileName: file,
  );

  final created = DateTime.utc(2026, 10, 30);
  final now = DateTime.utc(2026, 11, 1);

  Future<Set<int>> favoriteIds() async => {
    for (final row in await db.select(db.favorites).get()) row.trackId,
  };

  Future<List<int>> entries(int playlist) async => [
    for (final row
        in await (db.select(db.playlistEntries)
              ..where((e) => e.playlistId.equals(playlist))
              ..orderBy([(e) => OrderingTerm.asc(e.position)]))
            .get())
      row.trackId,
  ];

  group('favorites', () {
    test(
      'added with their dates; existing ones kept; missing reported',
      () async {
        final a = await track('/new/Music/a.mp3');
        final b = await track('/new/Music/b.mp3');
        final local = await track('/new/Music/local.mp3');
        await db.collectionsDao.addFavorite(local, at: DateTime.utc(2025));
        await db.collectionsDao.addFavorite(b, at: DateTime.utc(2025, 6));

        final report = await db.restoreDao.merge(
          BackupDocument(
            createdAt: created,
            favorites: [
              BackupFavorite(
                track: id('a.mp3'),
                addedAt: DateTime.utc(2026, 1),
              ),
              BackupFavorite(
                track: id('b.mp3'),
                addedAt: DateTime.utc(2026, 2),
              ),
              BackupFavorite(
                track: id('gone.mp3'),
                addedAt: DateTime.utc(2026, 3),
              ),
            ],
          ),
          now: now,
        );

        expect(await favoriteIds(), {a, b, local});
        expect(report.favoritesAdded, 1);
        final rowA = await (db.select(
          db.favorites,
        )..where((f) => f.trackId.equals(a))).getSingle();
        expect(rowA.addedAt, DateTime.utc(2026, 1));
        final rowB = await (db.select(
          db.favorites,
        )..where((f) => f.trackId.equals(b))).getSingle();
        expect(rowB.addedAt, DateTime.utc(2025, 6), reason: 'kept as it was');
        expect(report.notFound, [
          UnmatchedEntry.favorite(
            id('gone.mp3'),
            addedAt: DateTime.utc(2026, 3),
          ),
        ]);
      },
    );

    test('renamed files are found by title and artist', () async {
      final renamed = await track(
        '/new/Download/Mahmoud Ahmed - Tizita.mp3',
        title: 'Tizita',
        artist: 'Mahmoud Ahmed',
        ms: 241000,
      );
      await db.restoreDao.merge(
        BackupDocument(
          createdAt: created,
          favorites: [
            BackupFavorite(
              track: id(
                'Tizita.mp3',
                title: 'Tizita',
                artist: 'Mahmoud Ahmed',
                ms: 240500,
              ),
              addedAt: created,
            ),
          ],
        ),
      );
      expect(await favoriteIds(), {renamed});
    });
  });

  group('playlists', () {
    test('a new one is created in order, with its description', () async {
      final a = await track('/m/a.mp3');
      final b = await track('/m/b.mp3');

      final report = await db.restoreDao.merge(
        BackupDocument(
          createdAt: created,
          playlists: [
            BackupPlaylist(
              name: 'Morning',
              description: 'Slow ones',
              createdAt: DateTime.utc(2025, 12),
              tracks: [id('b.mp3'), id('gone.mp3'), id('a.mp3')],
            ),
          ],
        ),
        now: now,
      );

      final row = await db.select(db.playlists).getSingle();
      expect(row.name, 'Morning');
      expect(row.description, 'Slow ones');
      expect(row.createdAt, DateTime.utc(2025, 12));
      expect(await entries(row.id), [b, a]);
      expect(report.playlistsCreated, 1);
      expect(report.playlistSongsAdded, 2);
      expect(report.notFound, [
        UnmatchedEntry.playlist(
          id('gone.mp3'),
          playlist: 'Morning',
          position: 1,
        ),
      ]);
    });

    test(
      'the same name (any case) gets its missing songs at the end',
      () async {
        final a = await track('/m/a.mp3');
        final b = await track('/m/b.mp3');
        final c = await track('/m/c.mp3');
        final local = await track('/m/local.mp3');
        final playlist = await db.collectionsDao.createPlaylist('Morning');
        await db.collectionsDao.addToPlaylist(playlist, [local, b]);

        final report = await db.restoreDao.merge(
          BackupDocument(
            createdAt: created,
            playlists: [
              BackupPlaylist(
                name: 'MORNING ',
                tracks: [id('a.mp3'), id('b.mp3'), id('c.mp3'), id('a.mp3')],
              ),
            ],
          ),
        );

        expect(await db.select(db.playlists).get(), hasLength(1));
        expect(await entries(playlist), [local, b, a, c]);
        expect(report.playlistsCreated, 0);
        expect(report.playlistSongsAdded, 2);
        final row = await db.select(db.playlists).getSingle();
        expect(row.name, 'Morning', reason: 'the local name is kept');
      },
    );
  });

  group('lyrics choices', () {
    test(
      'added where none was made by hand; automatic ones replaced',
      () async {
        final auto = await track('/m/auto.mp3');
        final none = await track('/m/none.mp3');
        final mine = await track('/m/mine.mp3');
        await db.lyricsLinksDao.replaceAutomatic({auto: 'song-auto'});
        await db.lyricsLinksDao.setManual(mine, 'song-mine');

        final report = await db.restoreDao.merge(
          BackupDocument(
            createdAt: created,
            lyricsChoices: [
              BackupLyricsChoice(track: id('auto.mp3'), songId: 'song-1'),
              BackupLyricsChoice(track: id('none.mp3')),
              BackupLyricsChoice(track: id('mine.mp3'), songId: 'song-2'),
            ],
          ),
        );

        final links = {
          for (final row in await db.select(db.lyricsLinks).get())
            row.trackId: (row.songId, row.manual),
        };
        expect(links[auto], ('song-1', true));
        expect(links[none], (null, true), reason: '"no lyrics" restored');
        expect(links[mine], (
          'song-mine',
          true,
        ), reason: 'the phone\'s choice wins');
        expect(report.lyricsChoicesAdded, 2);
      },
    );
  });

  group('hidden', () {
    test(
      'folders map to this phone\'s, parents included; songs by match',
      () async {
        await track('/storage/emulated/0/Recordings/Calls/a.m4a');
        await track('/storage/1A2B-3C4D/WhatsApp/Media/b.opus');
        final memo = await track('/storage/emulated/0/Music/memo.m4a');

        final report = await db.restoreDao.merge(
          BackupDocument(
            createdAt: created,
            hiddenFolders: const ['Recordings', 'WhatsApp', 'Not Here'],
            hiddenTracks: [id('memo.m4a'), id('gone.m4a')],
          ),
        );

        final folders = {
          for (final row in await db.select(db.hiddenFolders).get()) row.path,
        };
        expect(folders, {
          '/storage/emulated/0/Recordings',
          '/storage/1A2B-3C4D/WhatsApp',
          '/storage/emulated/0/Not Here',
        });
        final hidden = await db.select(db.hiddenTracks).get();
        expect(hidden.single.trackId, memo);
        expect(report.hiddenAdded, 4);
        expect(report.notFound, [UnmatchedEntry.hiddenTrack(id('gone.m4a'))]);
      },
    );
  });

  test(
    'keepUnmatched gets the entries not found, inside the transaction',
    () async {
      List<UnmatchedEntry>? kept;
      await db.restoreDao.merge(
        BackupDocument(
          createdAt: created,
          favorites: [BackupFavorite(track: id('gone.mp3'), addedAt: created)],
        ),
        keepUnmatched: (notFound) async => kept = notFound,
      );
      expect(kept, hasLength(1));
    },
  );

  test('an error midway changes nothing', () async {
    final a = await track('/m/a.mp3');
    final document = BackupDocument(
      createdAt: created,
      favorites: [BackupFavorite(track: id('a.mp3'), addedAt: created)],
      playlists: [
        BackupPlaylist(name: 'P', tracks: [id('a.mp3')]),
      ],
      lyricsChoices: [BackupLyricsChoice(track: id('a.mp3'), songId: 's')],
      hiddenFolders: const ['m'],
      hiddenTracks: [id('a.mp3')],
    );

    await expectLater(
      db.restoreDao.merge(
        document,
        keepUnmatched: (_) => throw StateError('disk full'),
      ),
      throwsStateError,
    );

    expect(await db.select(db.favorites).get(), isEmpty);
    expect(await db.select(db.playlists).get(), isEmpty);
    expect(await db.select(db.playlistEntries).get(), isEmpty);
    expect(await db.select(db.lyricsLinks).get(), isEmpty);
    expect(await db.select(db.hiddenFolders).get(), isEmpty);
    expect(await db.select(db.hiddenTracks).get(), isEmpty);
    expect(a, isPositive);
  });

  test(
    'restoring the same backup twice adds nothing the second time',
    () async {
      await track('/m/a.mp3');
      final document = BackupDocument(
        createdAt: created,
        favorites: [BackupFavorite(track: id('a.mp3'), addedAt: created)],
        playlists: [
          BackupPlaylist(name: 'P', tracks: [id('a.mp3')]),
        ],
      );
      await db.restoreDao.merge(document);
      final again = await db.restoreDao.merge(document);
      expect(again.favoritesAdded, 0);
      expect(again.playlistsCreated, 0);
      expect(again.playlistSongsAdded, 0);
    },
  );

  group('BackupRestorer', () {
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

    test('merges the library, then applies the backup\'s settings', () async {
      await track('/m/a.mp3');
      await container
          .read(backupRestorerProvider)
          .restore(
            BackupDocument(
              createdAt: created,
              favorites: [BackupFavorite(track: id('a.mp3'), addedAt: created)],
              settings: const {
                'palette': 'wine',
                'gapless': false,
                'language': 'am',
              },
            ),
          );

      expect(await favoriteIds(), hasLength(1));
      final settings = container.read(settingsProvider);
      expect(settings.palette, ZemaPalette.wine);
      expect(settings.gapless, isFalse);
      expect(settings.languageCode, 'am');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('paletteId'), 'wine', reason: 'saved too');
    });

    test('a failed merge applies no settings', () async {
      await expectLater(
        container
            .read(backupRestorerProvider)
            .restore(
              BackupDocument(
                createdAt: created,
                settings: const {'gapless': false},
              ),
              keepUnmatched: (_) => throw StateError('disk full'),
            ),
        throwsStateError,
      );
      expect(container.read(settingsProvider), const AppSettings());
    });
  });
}
