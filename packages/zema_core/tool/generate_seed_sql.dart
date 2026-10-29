import 'dart:io';

import 'seed_sql.dart';

/// Writes backend/supabase/seed.sql and its test from backend/seed/ (see
/// seed_sql.dart). Run from packages/zema_core:
/// `dart run tool/generate_seed_sql.dart`.
void main() {
  final root = Directory.current.uri.resolve('../../');
  final folder = root.resolve('$seedFolder/');
  final seed = buildSeed(
    File.fromUri(folder.resolve('index.json')).readAsStringSync(),
    (file) {
      final f = File.fromUri(folder.resolve(file));
      return f.existsSync() ? f.readAsStringSync() : null;
    },
  );
  File.fromUri(root.resolve(seedSqlPath)).writeAsStringSync(seed.sql);
  File.fromUri(root.resolve(seedTestPath)).writeAsStringSync(seed.testSql);
  stdout.writeln('Seeded ${seed.songs.length} songs into $seedSqlPath');
  for (final problem in seed.problems) {
    stderr.writeln('Skipped $problem');
  }
}
