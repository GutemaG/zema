import 'dart:io';

import 'search_sql.dart';

/// Writes the SQL search rules and their parity test (see search_sql.dart).
/// Run from packages/zema_core: `dart run tool/generate_search_sql.dart`.
void main() {
  final root = Directory.current.uri.resolve('../../');
  File.fromUri(root.resolve(migrationPath)).writeAsStringSync(searchRulesSql());
  File.fromUri(root.resolve(parityTestPath)).writeAsStringSync(parityTestSql());
  stdout.writeln('Wrote $migrationPath and $parityTestPath');
}
