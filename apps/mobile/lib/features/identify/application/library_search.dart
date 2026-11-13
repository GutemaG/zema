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

class LibrarySearch {
  LibrarySearch._(this._isolate, this._worker, this.recordingCount);

  final Isolate _isolate;
  final SendPort _worker;
  final int recordingCount;

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
      final count = await _ask<int>(isolate, worker, const _Count());
      return LibrarySearch._(isolate, worker, count);
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
