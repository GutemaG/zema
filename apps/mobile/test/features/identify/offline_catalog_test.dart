import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/identify/application/offline_catalog.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

OfflineFingerprintEntry _entry(
  String id,
  String song, {
  int hashes = 1000,
  int revision = 1,
}) => OfflineFingerprintEntry(
  recordingId: id,
  songId: song,
  revision: revision,
  hashCount: hashes,
  identified: 0,
);

class _Catalog implements AudioCatalog {
  List<OfflineFingerprintEntry> entries = [];
  final fetched = <String>[];

  @override
  Future<List<OfflineFingerprintEntry>> offlineFingerprints() async => entries;

  @override
  Future<List<CatalogFingerprint>> fingerprints(
    List<String> recordingIds,
  ) async {
    expect(recordingIds.length, lessThanOrEqualTo(20));
    fetched.addAll(recordingIds);
    return [
      for (final id in recordingIds)
        CatalogFingerprint(
          recordingId: id,
          revision: entries.firstWhere((e) => e.recordingId == id).revision,
          fingerprint: AudioFingerprint(
            hashes: Uint32List.fromList([1, 2]),
            frames: Uint32List.fromList([0, 5]),
            frameCount: 10,
          ),
        ),
    ];
  }

  @override
  Future<List<CatalogAudioMatch>> identify(
    List<AudioFingerprint> queries, {
    required String installId,
    int limit = 3,
  }) async => const [];

  @override
  Future<Set<String>> missingFingerprints(List<String> recordingIds) async =>
      const {};

  @override
  Future<FingerprintShare> shareFingerprint(
    String recordingId,
    AudioFingerprint fingerprint, {
    required String installId,
  }) async => FingerprintShare.notNeeded;
}

void main() {
  group('choosing what to keep', () {
    final entries = [
      _entry('popular', 'p', hashes: 5000000),
      _entry('lib', 'l'),
      _entry('fav', 'f'),
      _entry('other', 'o'),
    ];

    List<String> chosen(OfflineBudget budget) => [
      for (final e in chooseOffline(
        entries,
        favoriteSongs: {'f'},
        librarySongs: {'f', 'l'},
        budget: budget,
      ))
        e.recordingId,
    ];

    test('favorites, then the library, then the most identified', () {
      expect(chosen(OfflineBudget.mb100), ['fav', 'lib', 'popular', 'other']);
    });

    test('within the budget: what does not fit is left out', () {
      expect(chosen(OfflineBudget.mb25), ['fav', 'lib', 'other']);
    });

    test('library only keeps the library, whatever its size', () {
      expect(chosen(OfflineBudget.libraryOnly), ['fav', 'lib']);
    });
  });

  group('the offline index', () {
    late ZemaDatabase db;
    late _Catalog catalog;
    late OfflineSongs songs;

    setUp(() {
      db = memoryDatabase();
      catalog = _Catalog();
      songs = (favorites: <String>{}, library: {'a'});
    });
    tearDown(() => db.close());

    OfflineCatalogSync sync() => OfflineCatalogSync(
      catalog: catalog,
      fingerprints: db.fingerprintsDao,
      songs: () async => songs,
    );

    Future<Map<String, int>> kept() async => {
      for (final k in await db.fingerprintsDao.keptCatalog())
        k.recordingId: k.revision,
    };

    test('fetches only what is new or changed, and drops the rest', () async {
      catalog.entries = [
        for (var i = 0; i < 25; i++) _entry('r$i', 'a'),
        _entry('b1', 'b'),
      ];
      expect(await sync().sync(OfflineBudget.libraryOnly), 25);
      expect(catalog.fetched, hasLength(25));
      expect((await kept()).keys, isNot(contains('b1')));

      catalog
        ..fetched.clear()
        ..entries = [
          _entry('r0', 'a', revision: 2),
          for (var i = 1; i < 24; i++) _entry('r$i', 'a'),
        ];
      expect(await sync().sync(OfflineBudget.libraryOnly), 1);
      expect(catalog.fetched, ['r0']);
      final now = await kept();
      expect(now['r0'], 2);
      expect(now, hasLength(24), reason: 'r24 left the catalog');
    });

    test('a smaller budget drops what no longer fits', () async {
      songs = (favorites: <String>{}, library: <String>{});
      catalog.entries = [
        _entry('big', 'x', hashes: 5000000),
        _entry('small', 'y'),
      ];
      await sync().sync(OfflineBudget.mb100);
      expect((await kept()).keys, {'big', 'small'});
      await sync().sync(OfflineBudget.mb25);
      expect((await kept()).keys, {'small'});
      expect(await db.fingerprintsDao.watchCatalogCoverage().first, (
        songs: 1,
        bytes: AudioFingerprint(
          hashes: Uint32List.fromList([1, 2]),
          frames: Uint32List.fromList([0, 5]),
          frameCount: 10,
        ).toBytes().length,
      ));
    });
  });
}
