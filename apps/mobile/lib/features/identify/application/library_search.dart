import 'dart:isolate';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/zema_database.dart';

final _log = Logger('identify.search');

const _pageSize = 100;

/// The library's best match for an excerpt, and the excerpt's query
/// fingerprints, to look for in the catalog when the library has no match.
typedef LibraryHeard = ({
  List<AudioMatch> matches,
  List<AudioFingerprint> queries,
});
const _died = 'died';

/// Catalog recordings in the search have IDs with this prefix; library
/// files have their track ID.
const catalogSearchPrefix = 'c:';

/// A catalog recording kept on the phone: its song and length.
typedef OfflineRecording = ({String songId, Duration duration});

/// Searches the library's fingerprints and the catalog's kept on the phone
/// (intent 009 FR-4), in a worker isolate.
class LibrarySearch {
  LibrarySearch._(
    this._isolate,
    this._worker,
    this.recordingCount,
    this.catalogRecordings,
  );

  final Isolate _isolate;
  final SendPort _worker;
  final int recordingCount;

  /// The catalog recordings searched, by recording ID.
  final Map<String, OfflineRecording> catalogRecordings;

  static Future<LibrarySearch> open(ZemaDatabase db) async {
    final ready = ReceivePort();
    final isolate = await Isolate.spawn(_work, ready.sendPort);
    try {
      final worker = await ready.first as SendPort;
      final damaged = <int>[];
      var after = -1;
      while (true) {
        final rows = await db.fingerprintsDao.page(
          fingerprintVersion,
          after: after,
          limit: _pageSize,
        );
        if (rows.isEmpty) break;
        damaged.addAll(
          await _ask<List<int>>(
            isolate,
            worker,
            _AddRows([for (final row in rows) (row.trackId, row.data)]),
          ),
        );
        after = rows.last.trackId;
      }
      if (damaged.isNotEmpty) {
        _log.warning('Deleting ${damaged.length} damaged fingerprints');
        await db.fingerprintsDao.remove(damaged);
      }
      final catalog = <String, OfflineRecording>{};
      final damagedCatalog = <String>[];
      var afterId = '';
      while (true) {
        final rows = await db.fingerprintsDao.catalogPage(
          fingerprintVersion,
          after: afterId,
          limit: _pageSize,
        );
        if (rows.isEmpty) break;
        final frames = await _ask<Map<String, int>>(
          isolate,
          worker,
          _AddCatalogRows([
            for (final row in rows) (row.recordingId, row.data),
          ]),
        );
        for (final row in rows) {
          if (frames[row.recordingId] case final count?) {
            catalog[row.recordingId] = (
              songId: row.songId,
              duration: fingerprintFrameTime(count),
            );
          } else {
            damagedCatalog.add(row.recordingId);
          }
        }
        afterId = rows.last.recordingId;
      }
      if (damagedCatalog.isNotEmpty) {
        await db.fingerprintsDao.removeCatalog(damagedCatalog);
      }
      final count = await _ask<int>(isolate, worker, const _Count());
      return LibrarySearch._(isolate, worker, count, catalog);
    } catch (_) {
      isolate.kill(priority: Isolate.immediate);
      rethrow;
    }
  }

  Future<LibraryHeard> identify(Float32List pcm, int rate) =>
      _ask(_isolate, _worker, _Identify(pcm, rate));

  void close() => _isolate.kill(priority: Isolate.immediate);

  static Future<T> _ask<T>(
    Isolate isolate,
    SendPort worker,
    _Request request,
  ) async {
    final reply = ReceivePort();
    isolate.addOnExitListener(reply.sendPort, response: _died);
    worker.send((request, reply.sendPort));
    final answer = await reply.first;
    if (answer == _died) throw StateError('The search worker stopped');
    if (answer is _Failed) throw StateError(answer.message);
    return answer as T;
  }
}

sealed class _Request {
  const _Request();
}

class _AddRows extends _Request {
  const _AddRows(this.rows);

  final List<(int, Uint8List)> rows;
}

class _AddCatalogRows extends _Request {
  const _AddCatalogRows(this.rows);

  final List<(String, Uint8List)> rows;
}

class _Count extends _Request {
  const _Count();
}

class _Identify extends _Request {
  const _Identify(this.pcm, this.rate);

  final Float32List pcm;
  final int rate;
}

class _Failed {
  const _Failed(this.message);

  final String message;
}

void _work(SendPort main) {
  final index = FingerprintIndex();
  final inbox = ReceivePort();
  main.send(inbox.sendPort);
  inbox.listen((message) {
    final (request, reply) = message as (_Request, SendPort);
    try {
      reply.send(switch (request) {
        _AddRows(:final rows) => _add(index, rows),
        _AddCatalogRows(:final rows) => _addCatalog(index, rows),
        _Count() => index.recordingCount,
        _Identify(:final pcm, :final rate) => _identify(index, pcm, rate),
      });
    } catch (e) {
      reply.send(_Failed('$e'));
    }
  });
}

LibraryHeard _identify(FingerprintIndex index, Float32List pcm, int rate) {
  final queries = const Fingerprinter().queries(resampleMono(pcm, rate));
  return (matches: index.match(queries, limit: 1), queries: queries);
}

List<int> _add(FingerprintIndex index, List<(int, Uint8List)> rows) {
  final damaged = <int>[];
  for (final (id, data) in rows) {
    try {
      index.add('$id', AudioFingerprint.fromBytes(data));
    } on FingerprintFormatFailure {
      damaged.add(id);
    }
  }
  return damaged;
}

/// Adds catalog [rows]; returns the frame count of each one added.
Map<String, int> _addCatalog(
  FingerprintIndex index,
  List<(String, Uint8List)> rows,
) {
  final added = <String, int>{};
  for (final (id, data) in rows) {
    try {
      final fingerprint = AudioFingerprint.fromBytes(data);
      index.add('$catalogSearchPrefix$id', fingerprint);
      added[id] = fingerprint.frameCount;
    } on FingerprintFormatFailure {
      continue;
    }
  }
  return added;
}
