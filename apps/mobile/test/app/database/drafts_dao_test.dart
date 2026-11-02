import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

ContributionDraft titled(String title, {DraftStep step = DraftStep.lyrics}) =>
    ContributionDraft(
      song: Song(id: '', title: title, sections: const []),
      step: step,
    );

void main() {
  late ZemaDatabase db;
  final t0 = DateTime.utc(2026, 11, 2, 9);

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  test('create, get and save keep the whole draft and its times', () async {
    final dao = db.draftsDao;
    final id = await dao.create(titled('Selam'), now: t0);

    final created = (await dao.get(id))!;
    expect(created.draft, titled('Selam'));
    expect(created.createdAt, t0);
    expect(created.updatedAt, t0);

    final later = t0.add(const Duration(minutes: 5));
    final changed = titled('Selam Lezih', step: DraftStep.recording);
    expect(await dao.save(id, changed, now: later), isTrue);
    final saved = (await dao.get(id))!;
    expect(saved.draft, changed);
    expect(saved.createdAt, t0);
    expect(saved.updatedAt, later);

    final row = await db.select(db.drafts).getSingle();
    expect(row.title, 'Selam Lezih', reason: 'kept for the list');
    expect(row.step, 'recording');
    expect(row.kind, 'new_song');
  });

  test('saving a deleted draft does nothing', () async {
    final id = await db.draftsDao.create(titled('a'), now: t0);
    await db.draftsDao.remove(id);
    expect(await db.draftsDao.save(id, titled('b'), now: t0), isFalse);
    expect(await db.draftsDao.get(id), isNull);
  });

  test('the list: last changed first, unreadable drafts left out', () async {
    final dao = db.draftsDao;
    final a = await dao.create(titled('A'), now: t0);
    await dao.create(titled('B'), now: t0.add(const Duration(minutes: 1)));
    await dao.save(a, titled('A2'), now: t0.add(const Duration(minutes: 2)));
    await db
        .into(db.drafts)
        .insert(
          DraftsCompanion.insert(
            kind: 'new_song',
            step: 'lyrics',
            title: 'From a newer app',
            draft: '{"format": 99}',
            createdAt: t0,
            updatedAt: t0.add(const Duration(minutes: 3)),
          ),
        );

    final list = await dao.watchAll().first;
    expect([for (final d in list) d.draft.title], ['A2', 'B']);
    expect(await dao.titles(), ['From a newer app', 'A2', 'B']);
  });

  test('clear removes every draft', () async {
    await db.draftsDao.create(titled('a'), now: t0);
    await db.draftsDao.create(titled('b'), now: t0);
    await db.draftsDao.clear();
    expect(await db.draftsDao.watchAll().first, isEmpty);
    expect(await db.draftsDao.titles(), isEmpty);
  });

  test('times are stored as UTC', () async {
    final id = await db.draftsDao.create(
      titled('a'),
      now: DateTime(2026, 11, 2, 12),
    );
    expect((await db.draftsDao.get(id))!.updatedAt.isUtc, isTrue);
    expect(
      await (db.select(db.drafts)..where((d) => d.id.equals(id))).get(),
      hasLength(1),
    );
  });
}
