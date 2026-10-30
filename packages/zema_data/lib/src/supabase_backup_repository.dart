import 'package:zema_core/zema_core.dart';

import 'supabase_auth_repository.dart';

/// The signed-in user's backup in the backend's `backups` table: users read
/// only their own row, and write it through `save_backup`, which sets the
/// time on the server.
class SupabaseBackupRepository implements BackupRepository {
  SupabaseBackupRepository(this._auth);

  final SupabaseAuthRepository _auth;

  @override
  Future<DateTime?> savedAt() =>
      _auth.run('backup savedAt', (client, userId) async {
        final rows = await client
            .from('backups')
            .select('updated_at')
            .eq('user_id', userId);
        if (rows.isEmpty) return null;
        return _time(rows.first['updated_at']);
      });

  @override
  Future<StoredBackup?> fetch() =>
      _auth.run('backup fetch', (client, userId) async {
        final rows = await client
            .from('backups')
            .select('document, updated_at')
            .eq('user_id', userId);
        if (rows.isEmpty) return null;
        final row = rows.first;
        final document = row['document'];
        if (document is! Map<String, Object?>) {
          throw const BackupFormatFailure('Backup is not a JSON object');
        }
        return StoredBackup(
          document: BackupDocument.fromJson(document),
          savedAt: _time(row['updated_at']),
        );
      });

  @override
  Future<DateTime> save(BackupDocument document) => _auth.run(
    'backup save',
    (client, _) async => _time(
      await client.rpc<Object?>(
        'save_backup',
        params: {'document': document.toJson(), 'format': document.format},
      ),
    ),
  );
}

DateTime _time(Object? value) => switch (value) {
  final String time => DateTime.parse(time).toUtc(),
  _ => throw FormatException('Expected a time: $value'),
};
