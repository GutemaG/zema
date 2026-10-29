import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/backend/backend_providers.dart';
import 'package:zema/features/search/application/catalog_search.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_catalog.dart';

CatalogEntry _entry(String id, String title, {String? transliteration}) =>
    CatalogEntry(
      id: id,
      title: title,
      transliteration: transliteration,
      artist: 'Choir',
      synced: true,
      version: 1,
      approvedAt: DateTime.utc(2026),
    );

CatalogMatch _match(String id, double score, {String? line}) =>
    CatalogMatch(songId: id, title: id, score: score, line: line);

void main() {
  group('CatalogTitleIndex', () {
    final index = CatalogTitleIndex([
      _entry('a', 'ቅድስት ማርያም'),
      _entry('b', 'ሰላም ለዚህ ቤት', transliteration: 'Selam Lezih Bet'),
      _entry('c', 'Amlak'),
      _entry('d', 'Selam'),
      // A word found only in the transliteration.
      _entry('e', 'ዝማሬ', transliteration: 'Zimare Dawit'),
    ]);

    test('Latin letters find an Ethiopic title', () {
      final hits = index.search('kidist');
      expect(hits.map((m) => m.songId), ['a']);
      expect(hits.single.line, isNull);
      expect(hits.single.artist, 'Choir');
    });

    test('the transliteration is searched too', () {
      expect(index.search('lezih').map((m) => m.songId), ['b']);
      expect(index.search('dawit').map((m) => m.songId), ['e']);
    });

    test('equal scores keep index order', () {
      expect(index.search('selam').map((m) => m.songId), ['b', 'd']);
    });

    test('an empty query or no match finds nothing', () {
      expect(index.search('  '), isEmpty);
      expect(index.search('zzzzqq'), isEmpty);
    });

    test('searches 5,000 songs within the keystroke budget', () {
      final big = CatalogTitleIndex([
        for (var i = 0; i < 5000; i++)
          _entry(
            's$i',
            'ቅዱስ መዝሙር ቁጥር $i',
            transliteration: 'Kidus Mezmur Kutir $i',
          ),
      ]);
      expect(big.search('kidus'), hasLength(5000));
      // < 100 ms per keystroke (NFR, with the library's 1,000 tracks timed in
      // library_search_test); the slowest of each keystroke of "kidus".
      var slowest = Duration.zero;
      for (final query in ['k', 'ki', 'kid', 'kidu', 'kidus']) {
        final watch = Stopwatch()..start();
        big.search(query);
        watch.stop();
        if (watch.elapsed > slowest) slowest = watch.elapsed;
      }
      expect(slowest, lessThan(const Duration(milliseconds: 100)));
      printOnFailure('slowest keystroke: $slowest');
    });
  });

  group('mergeCatalogMatches', () {
    test('each song once, best first', () {
      final merged = mergeCatalogMatches(
        [_match('a', 0.8), _match('b', 0.9)],
        [_match('c', 0.95, line: 'c1'), _match('a', 0.7, line: 'a1')],
      );
      expect(merged.map((m) => m.songId), ['c', 'b', 'a']);
      expect(merged.last.line, isNull); // a's title scored higher
    });

    test('a better line beats the title; the title wins a tie', () {
      final better = mergeCatalogMatches(
        [_match('a', 0.8)],
        [_match('a', 0.9, line: 'a1')],
      );
      expect(better.single.line, 'a1');
      final tie = mergeCatalogMatches(
        [_match('a', 0.9)],
        [_match('a', 0.9, line: 'a1')],
      );
      expect(tie.single.line, isNull);
    });

    test('equal scores keep the order they came in', () {
      final merged = mergeCatalogMatches(
        [_match('b', 0.9)],
        [_match('a', 0.9, line: 'a1'), _match('c', 0.9, line: 'c1')],
      );
      expect(merged.map((m) => m.songId), ['b', 'a', 'c']);
    });
  });

  group('catalogLineSearchProvider', () {
    Future<List<CatalogMatch>?> search(
      CatalogRepository? catalog,
      String query,
    ) async {
      final container = ProviderContainer(
        overrides: [catalogRepositoryProvider.overrideWithValue(catalog)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(catalogLineSearchProvider(query), (_, _) {});
      addTearDown(sub.close);
      return container.read(catalogLineSearchProvider(query).future);
    }

    test('keeps only line hits, after 300 ms', () async {
      final catalog = FakeCatalogRepository();
      catalog.searchHits['ifa'] = [
        const CatalogSearchHit(songId: 't', title: 'Ifa', score: 1),
        const CatalogSearchHit(
          songId: 'l',
          title: 'Galatoomi',
          score: 0.9,
          line: 'Ifa isaa nuuf kenne',
        ),
      ];
      final watch = Stopwatch()..start();
      final matches = await search(catalog, 'ifa');
      expect(watch.elapsed, greaterThanOrEqualTo(lineSearchDelay));
      expect(matches!.map((m) => m.songId), ['l']);
      expect(matches.single.line, 'Ifa isaa nuuf kenne');
      expect(catalog.searchCalls, ['ifa']);
    });

    test('no backend, or an empty query: null, and nothing is sent', () async {
      expect(await search(null, 'ifa'), isNull);
      final catalog = FakeCatalogRepository();
      expect(await search(catalog, '  '), isNull);
      expect(catalog.searchCalls, isEmpty);
    });

    test('a failure is thrown, not retried', () async {
      final catalog = FakeCatalogRepository()
        ..failure = const NetworkFailure('offline');
      await expectLater(search(catalog, 'ifa'), throwsA(isA<NetworkFailure>()));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(catalog.searchCalls, ['ifa']);
    });
  });
}
