import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/library_dao.dart';
import 'library_scanner.dart';

final _log = Logger('library.repository');

/// What one sync changed, for the UI and the log.
class LibrarySyncResult {
  const LibrarySyncResult({
    required this.scanned,
    required this.added,
    required this.updated,
    required this.missing,
    required this.elapsed,
  });

  /// Files the scanner reported (before any filtering).
  final int scanned;
  final int added;
  final int updated;
  final int missing;
  final Duration elapsed;
}

/// The local library: the only code that talks to both the scanner and the
/// database.
class LibraryRepository {
  LibraryRepository(this._scanner, this._dao);

  final LibraryScanner _scanner;
  final LibraryDao _dao;

  /// Tracks to show, updated whenever the database changes.
  Stream<List<Track>> watchTracks({required Duration minDuration}) =>
      _dao.watchVisibleTracks(minDuration: minDuration);

  /// Hides the folder at [path] and everything below it from every list.
  Future<void> hideFolder(String path) => _dao.hideFolder(path);

  Future<void> unhideFolder(String path) => _dao.unhideFolder(path);

  /// Hides one song from every list.
  Future<void> hideTrack(int trackId) => _dao.hideTrack(trackId);

  Future<void> unhideTrack(int trackId) => _dao.unhideTrack(trackId);

  /// Scans the device and applies the differences in one transaction. If
  /// anything fails, the stored library stays as it was.
  ///
  /// Throws [PermissionFailure], [ScanFailure] or [DatabaseFailure].
  Future<LibrarySyncResult> sync() async {
    final stopwatch = Stopwatch()..start();
    final scan = await _scanner.scan();
    final TrackReconciliation changes;
    try {
      changes = reconcileTracks(stored: await _dao.allTracks(), scan: scan);
      if (!changes.isEmpty) {
        await _dao.applyReconciliation(changes);
      }
    } on ZemaFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure('Saving the scan failed', cause: e);
    }
    stopwatch.stop();
    final result = LibrarySyncResult(
      scanned: scan.length,
      added: changes.added.length,
      updated: changes.updated.length,
      missing: changes.newlyMissing.length,
      elapsed: stopwatch.elapsed,
    );
    _log.info(
      'Library synced: ${result.scanned} files, +${result.added} '
      '~${result.updated} -${result.missing} '
      '(${changes.moved.length} moved, ${changes.returned.length} returned) '
      'in ${result.elapsed.inMilliseconds} ms',
    );
    return result;
  }
}
