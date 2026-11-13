import 'dart:async';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/database/catalog_dao.dart';
import '../../../app/database/database_provider.dart';
import '../../../app/database/identified_dao.dart';
import '../../../app/preferences_provider.dart';
import '../../catalog/application/report_sender.dart';

final _log = Logger('identify.pending');

/// How long an excerpt heard offline waits to be looked up.
const pendingLookupMaxAge = Duration(days: 30);

/// [queries] (one excerpt at each of `querySpeeds`) as bytes: per query a
/// 4-byte length, then its [AudioFingerprint.toBytes].
Uint8List encodeQueries(List<AudioFingerprint> queries) {
  final out = BytesBuilder(copy: false);
  for (final query in queries) {
    final bytes = query.toBytes();
    out
      ..add((ByteData(4)..setUint32(0, bytes.length)).buffer.asUint8List())
      ..add(bytes);
  }
  return out.takeBytes();
}

/// Reads [encodeQueries], giving each query its speed back. Throws
/// [FingerprintFormatFailure] for damaged bytes.
List<AudioFingerprint> decodeQueries(Uint8List bytes) {
  final queries = <AudioFingerprint>[];
  var at = 0;
  while (at < bytes.length) {
    if (at + 4 > bytes.length) {
      throw const FingerprintFormatFailure('Queries end early');
    }
    final length = ByteData.sublistView(bytes, at, at + 4).getUint32(0);
    at += 4;
    if (at + length > bytes.length) {
      throw const FingerprintFormatFailure('Queries end early');
    }
    final read = AudioFingerprint.fromBytes(
      Uint8List.sublistView(bytes, at, at + length),
    );
    at += length;
    queries.add(
      AudioFingerprint(
        hashes: read.hashes,
        frames: read.frames,
        frameCount: read.frameCount,
        speed: queries.length < querySpeeds.length
            ? querySpeeds[queries.length]
            : 1,
      ),
    );
  }
  return queries;
}

/// Looks up excerpts heard offline once the catalog can be reached; a song
/// found goes into History at the time it was heard.
class PendingLookupSender {
  PendingLookupSender({
    required this._catalog,
    required this._history,
    required this._index,
    required this._installId,
    required this._onFound,
  });

  final AudioCatalog? _catalog;
  final IdentifiedDao _history;
  final CatalogDao _index;
  final String Function() _installId;
  final void Function(CatalogEntry song) _onFound;
  Future<void>? _flushing;

  Future<void> flush() => _flushing ??= _flush().whenComplete(() {
    _flushing = null;
  });

  Future<void> _flush() async {
    final catalog = _catalog;
    if (catalog == null) return;
    for (final row in await _history.pending()) {
      if (clock.now().difference(row.heardAt) > pendingLookupMaxAge) {
        await _history.removePending(row.id);
        continue;
      }
      final List<CatalogAudioMatch> matches;
      try {
        matches = await catalog.identify(
          decodeQueries(row.queries),
          installId: _installId(),
          limit: 1,
        );
      } on NetworkFailure catch (e) {
        _log.info('Pending lookups wait: offline', e);
        return;
      } on RateLimitFailure catch (e) {
        _log.info('Pending lookups wait: daily limit', e);
        return;
      } on ZemaFailure catch (e) {
        _log.warning('Dropped a pending lookup', e);
        await _history.removePending(row.id);
        continue;
      }
      if (matches.firstOrNull case final best?) {
        final song = await _index.entry(best.songId);
        if (song != null) {
          await _history.add(row.heardAt, songId: song.id);
          _onFound(song);
        }
      }
      await _history.removePending(row.id);
    }
  }
}

/// Songs found after the phone came back online, for an in-app notice.
final lateMatchesProvider = Provider<StreamController<CatalogEntry>>((ref) {
  final events = StreamController<CatalogEntry>.broadcast();
  ref.onDispose(events.close);
  return events;
});

final lateMatchFoundProvider = StreamProvider<CatalogEntry>(
  (ref) => ref.watch(lateMatchesProvider).stream,
);

final pendingLookupSenderProvider = Provider<PendingLookupSender>((ref) {
  final db = ref.watch(databaseProvider);
  final preferences = ref.watch(sharedPreferencesProvider);
  final found = ref.watch(lateMatchesProvider);
  return PendingLookupSender(
    catalog: ref.watch(audioCatalogProvider),
    history: db.identifiedDao,
    index: db.catalogDao,
    installId: () => installId(preferences),
    onFound: found.add,
  );
});

/// Sends waiting lookups when Zema starts and each time it comes back to the
/// front.
final pendingLookupFlushProvider = Provider<void>((ref) {
  void flush() => unawaited(
    ref
        .read(pendingLookupSenderProvider)
        .flush()
        .catchError((Object e) => _log.warning('Pending lookups failed', e)),
  );
  flush();
  final lifecycle = AppLifecycleListener(onResume: flush);
  ref.onDispose(lifecycle.dispose);
});
