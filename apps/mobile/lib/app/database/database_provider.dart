import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'zema_database.dart';

/// The app's database, opened on first use and closed with the scope.
/// Tests override it with an in-memory database.
final databaseProvider = Provider<ZemaDatabase>((ref) {
  final database = ZemaDatabase.open();
  ref.onDispose(database.close);
  return database;
});
