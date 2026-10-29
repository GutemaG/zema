import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

CatalogEntry _entry(String id, {int version = 1, String? title}) =>
    CatalogEntry(
      id: id,
      title: title ?? id.toUpperCase(),
      transliteration: '$id-latin',
      artist: 'Artist',
      album: 'Album',
      synced: id != 'plain',
      version: version,
      approvedAt: DateTime.utc(2026, 10, 29, 8, 15),
    );

void main() {
  late ZemaDatabase db;

  setUp(() => db = ZemaDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('starts empty', () async {
    expect(await db.catalogDao.count(), 0);
    expect(await db.catalogDao.watchEntries().first, isEmpty);
  });

  test('replaceAll stores every field and reads entries back by ID', () async {
    final entries = [_entry('selam'), _entry('amlak'), _entry('plain')];
    await db.catalogDao.replaceAll(entries);

    final read = await db.catalogDao.watchEntries().first;
    expect([for (final e in read) e.id], ['amlak', 'plain', 'selam']);
    expect(read.last, _entry('selam'));
    expect(read[1].synced, isFalse);
    expect(read.last.approvedAt.isUtc, isTrue);
  });

  test('replaceAll removes, updates and adds in one go', () async {
    await db.catalogDao.replaceAll([_entry('a'), _entry('b'), _entry('c')]);
    await db.catalogDao.replaceAll([
      _entry('b', version: 2, title: 'B two'),
      _entry('d'),
    ]);

    final read = await db.catalogDao.watchEntries().first;
    expect([for (final e in read) e.id], ['b', 'd']);
    expect(read.first.version, 2);
    expect(read.first.title, 'B two');
    expect(await db.catalogDao.count(), 2);
  });

  test('an empty catalog empties the index', () async {
    await db.catalogDao.replaceAll([_entry('a')]);
    await db.catalogDao.replaceAll(const []);
    expect(await db.catalogDao.count(), 0);
  });

  test('watchEntries emits after each replace', () async {
    final emitted = <List<String>>[];
    final subscription = db.catalogDao.watchEntries().listen(
      (entries) => emitted.add([for (final e in entries) e.id]),
    );
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    await db.catalogDao.replaceAll([_entry('a')]);
    await pumpEventQueue();
    await db.catalogDao.replaceAll([_entry('b')]);
    await pumpEventQueue();

    expect(emitted, [
      <String>[],
      ['a'],
      ['b'],
    ]);
  });
}
