import 'dart:io';

import 'package:test/test.dart';

import '../../tool/search_sql.dart';

/// The server's search rules are generated from this package; this fails if
/// someone changed the rule tables (or the generator) without running
/// `dart run tool/generate_search_sql.dart`.
void main() {
  final root = Directory.current.uri.resolve('../../');

  test('the generated SQL search rules are up to date', () {
    expect(
      File.fromUri(root.resolve(migrationPath)).readAsStringSync(),
      searchRulesSql(),
      reason: 'Run dart run tool/generate_search_sql.dart',
    );
  });

  test('the generated search parity test is up to date', () {
    expect(
      File.fromUri(root.resolve(parityTestPath)).readAsStringSync(),
      parityTestSql(),
      reason: 'Run dart run tool/generate_search_sql.dart',
    );
  });

  test('the parity searches cover hits, lines, spellings and misses', () {
    expect(expectedSearch('kidist'), expectedSearch('ቅድስት'));
    expect(expectedSearch('jaallatee').single.$2, 'Waaqayyo nu jaallatee');
    expect(expectedSearch('xyz'), isEmpty);
  });
}
