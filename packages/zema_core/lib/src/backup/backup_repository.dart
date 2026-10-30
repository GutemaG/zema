import '../failures.dart';
import 'backup_document.dart';

/// The signed-in user's backup on the server and when it was saved.
class StoredBackup {
  const StoredBackup({required this.document, required this.savedAt});

  final BackupDocument document;

  /// The server's time of the save.
  final DateTime savedAt;
}

/// The signed-in user's one backup on the server. Every call needs a
/// signed-in user ([AuthFailure] otherwise); [NetworkFailure] when the
/// server can't be reached.
abstract interface class BackupRepository {
  /// When the backup was last saved, without downloading it; null when
  /// there is none.
  Future<DateTime?> savedAt();

  /// The backup, or null when there is none. Throws [BackupFormatFailure]
  /// when it can't be read, e.g. a newer app wrote it.
  Future<StoredBackup?> fetch();

  /// Saves [document], replacing the previous backup, and returns the
  /// server's time of the save.
  Future<DateTime> save(BackupDocument document);
}
