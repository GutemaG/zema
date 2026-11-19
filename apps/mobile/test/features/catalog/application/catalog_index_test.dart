import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/catalog/application/catalog_index.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_catalog.dart';

const _selam = Song(id: 'selam', title: 'ሰላም', sections: []);
const _amlak = Song(id: 'amlak', title: 'Amlak', sections: []);

void main() {
  late ZemaDatabase db;
  late SharedPreferences preferences;
  late FakeCatalogRepository catalog;
  final start = DateTime.utc(2026, 10, 29, 9);

  CatalogIndexRefresher refresher({bool configured = true}) =>
      CatalogIndexRefresher(
        catalog: configured ? catalog : null,
        dao: db.catalogDao,
        preferences: preferences,
      );

  Future<List<String>> saved() async => [
    for (final e in await db.catalogDao.watchEntries().first) e.id,
  ];

  setUp(() async {
    db = ZemaDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    catalog = FakeCatalogRepository(
      entries: [catalogEntry(_selam), catalogEntry(_amlak)],
    );
  });
  tearDown(() => db.close());

  test('a missing index is fetched and saved, with the time', () async {
    final r = refresher();
    expect(r.refreshedAt, isNull);

    final result = await withClock(Clock.fixed(start), r.refresh);

    expect(result, IndexRefresh.refreshed);
    expect(await saved(), ['amlak', 'selam']);
    expect(r.refreshedAt, start);
  });

  test('under 30 minutes old it is skipped; after that it refreshes', () async {
    final r = refresher();
    await withClock(Clock.fixed(start), r.refresh);

    final soon = start.add(const Duration(minutes: 29));
    expect(await withClock(Clock.fixed(soon), r.refresh), IndexRefresh.fresh);
    expect(catalog.indexCalls, 1);

    final later = start.add(CatalogIndexRefresher.maxAge);
    expect(
      await withClock(Clock.fixed(later), r.refresh),
      IndexRefresh.refreshed,
    );
    expect(catalog.indexCalls, 2);
    expect(r.refreshedAt, later);
  });

  test('force refreshes however recent the index is', () async {
    final r = refresher();
    await withClock(Clock.fixed(start), r.refresh);
    final result = await withClock(
      Clock.fixed(start.add(const Duration(minutes: 1))),
      () => r.refresh(force: true),
    );
    expect(result, IndexRefresh.refreshed);
    expect(catalog.indexCalls, 2);
  });

  test('songs removed from the catalog drop out', () async {
    final r = refresher();
    await r.refresh();
    catalog.entries = [catalogEntry(_selam, version: 2)];

    await r.refresh(force: true);

    final entries = await db.catalogDao.watchEntries().first;
    expect([for (final e in entries) e.id], ['selam']);
    expect(entries.single.version, 2);
  });

  test('a failure keeps the old index and time, and is rethrown', () async {
    final r = refresher();
    await withClock(Clock.fixed(start), r.refresh);
    catalog.failure = const NetworkFailure('offline');

    await expectLater(r.refresh(force: true), throwsA(isA<NetworkFailure>()));
    expect(await saved(), ['amlak', 'selam']);
    expect(r.refreshedAt, start);

    // The next call tries again.
    catalog.failure = null;
    expect(await r.refresh(force: true), IndexRefresh.refreshed);
  });

  test('without a backend nothing is fetched', () async {
    final r = refresher(configured: false);
    expect(await r.refresh(force: true), IndexRefresh.notConfigured);
    expect(catalog.indexCalls, 0);
    expect(await saved(), isEmpty);
  });

  test('calls made while one runs share it', () async {
    final gate = Completer<void>();
    final slow = _SlowCatalog(catalog, gate.future);
    final r = CatalogIndexRefresher(
      catalog: slow,
      dao: db.catalogDao,
      preferences: preferences,
    );

    final first = r.refresh();
    final second = r.refresh(force: true);
    gate.complete();

    expect(await Future.wait([first, second]), [
      IndexRefresh.refreshed,
      IndexRefresh.refreshed,
    ]);
    expect(catalog.indexCalls, 1);

    // Once finished, a new call runs again.
    await r.refresh(force: true);
    expect(catalog.indexCalls, 2);
  });
}

/// Holds [index] answers until [gate] completes.
class _SlowCatalog extends FakeCatalogRepository {
  _SlowCatalog(this._inner, this._gate);

  final FakeCatalogRepository _inner;
  final Future<void> _gate;

  @override
  Future<List<CatalogEntry>> index() async {
    await _gate;
    return _inner.index();
  }
}
