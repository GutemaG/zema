import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tool/seed_sql.dart';

const _lrc = '[ti:Song]\n[00:01]one\n[00:02]two\n';

void main() {
  group('buildSeed', () {
    test('loads every good entry and lists the bad ones', () {
      final index = jsonEncode({
        'songs': [
          {'id': 'good', 'file': 'good.lrc'},
          {'id': 'missing', 'file': 'missing.lrc'},
          {'id': 'empty', 'file': 'empty.lrc'},
          {'file': 'good.lrc'},
          'not an object',
          {'id': 'draft', 'file': 'good.lrc', 'status': 'draft'},
          {'id': 'odd', 'file': 'good.lrc', 'status': 'published'},
          {'id': 'good', 'file': 'good.lrc'},
        ],
      });
      final seed = buildSeed(
        index,
        (file) => switch (file) {
          'good.lrc' => _lrc,
          'empty.lrc' => '[ti:Empty]',
          _ => null,
        },
      );
      expect(
        [for (final (s, status) in seed.songs) '${s.song.id}:$status'],
        ['good:approved', 'draft:draft'],
      );
      expect(seed.problems, [
        'missing: missing.lrc not found',
        startsWith('empty: '),
        startsWith('entry 4: '),
        'entry 5: not an object',
        'odd: unknown status published',
        'good: listed twice',
      ]);
    });

    test('a broken index loads nothing and says why', () {
      expect(
        buildSeed('{', (_) => null).problems.single,
        startsWith('index.json'),
      );
      expect(buildSeed('{}', (_) => null).problems, [
        'index.json: no "songs" list',
      ]);
    });

    test('SQL quotes are escaped', () {
      final seed = buildSeed(
        jsonEncode({
          'songs': [
            {'id': 'quote', 'file': 'q.lrc'},
          ],
        }),
        (_) => "[ti:It's]\n[00:01]don't\n",
      );
      expect(seed.sql, contains("It''s"));
      expect(seed.sql, isNot(contains("It's")));
    });
  });

  test('the committed seed and its test are up to date', () {
    final root = Directory.current.uri.resolve('../../');
    final folder = root.resolve('$seedFolder/');
    final seed = buildSeed(
      File.fromUri(folder.resolve('index.json')).readAsStringSync(),
      (file) => File.fromUri(folder.resolve(file)).readAsStringSync(),
    );
    expect(seed.problems, isEmpty);
    expect(
      File.fromUri(root.resolve(seedSqlPath)).readAsStringSync(),
      seed.sql,
      reason: 'Run dart run tool/generate_seed_sql.dart',
    );
    expect(
      File.fromUri(root.resolve(seedTestPath)).readAsStringSync(),
      seed.testSql,
      reason: 'Run dart run tool/generate_seed_sql.dart',
    );
  });
}
