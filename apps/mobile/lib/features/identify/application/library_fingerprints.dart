import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/database/zema_database.dart';
import '../../library/application/library_providers.dart';
import '../data/audio_decoder.dart';

final _log = Logger('identify.library');

/// How the preparation went on this phone, for Listen's details.
class FingerprintTimings {
  const FingerprintTimings({
    this.songs = 0,
    this.decoding = Duration.zero,
    this.fingerprinting = Duration.zero,
    this.codecs = const {},
    this.device,
    this.workers = decodeWorkers,
  });

  /// Songs timed in this run.
  final int songs;

  /// Totals over [songs].
  final Duration decoding;
  final Duration fingerprinting;
  final Set<String> codecs;
  final DecodeDevice? device;

  /// Songs prepared at the same time on this phone.
  final int workers;

  Duration get decodingEach => songs == 0 ? Duration.zero : decoding ~/ songs;
  Duration get fingerprintingEach =>
      songs == 0 ? Duration.zero : fingerprinting ~/ songs;

  FingerprintTimings add(DecodedAudio audio, Duration fingerprinted) =>
      FingerprintTimings(
        songs: songs + 1,
        decoding: decoding + audio.took,
        fingerprinting: fingerprinting + fingerprinted,
        codecs: {...codecs, if (audio.codec.isNotEmpty) audio.codec},
        device: device,
        workers: workers,
      );
}

/// How many library songs Listen can identify.
class LibraryFingerprintsState {
  const LibraryFingerprintsState({
    this.ready = 0,
    this.unreadable = 0,
    this.total = 0,
    this.running = false,
    this.left,
    this.timings = const FingerprintTimings(),
  });

  /// Songs with an up-to-date fingerprint.
  final int ready;

  /// Songs that couldn't be read since Zema started.
  final int unreadable;
  final int total;

  /// Fingerprinting is under way.
  final bool running;

  /// About how long the rest will take, once a few songs give a pace.
  final Duration? left;

  final FingerprintTimings timings;

  bool get done => ready + unreadable >= total;
}

/// The pause between two songs' fingerprints.
const songPause = Duration(milliseconds: 100);

final libraryFingerprintsProvider =
    NotifierProvider<LibraryFingerprints, LibraryFingerprintsState>(
      LibraryFingerprints.new,
    );

/// Fingerprints the library's songs, [decodeWorkers] at a time, at the
/// offline density
/// (intent 009 FR-4/FR-8). A song is done again when its file size or the
/// fingerprint version changes.
class LibraryFingerprints extends Notifier<LibraryFingerprintsState> {
  var _running = false;
  var _disposed = false;

  /// The sizes of files that couldn't be read, by track ID. Kept only until
  /// Zema closes, as the cause may pass: the next run tries them again.
  final _unreadable = <int, int>{};

  bool _isUnreadable(Track track) => _unreadable[track.id] == track.sizeBytes;

  @override
  LibraryFingerprintsState build() {
    ref.onDispose(() => _disposed = true);
    ref.listen(libraryTracksProvider, (_, _) => unawaited(_count()));
    unawaited(_count());
    return const LibraryFingerprintsState();
  }

  ZemaDatabase get _db => ref.read(databaseProvider);

  Future<List<Track>> _tracks() async =>
      (await ref.read(libraryTracksProvider.future))
          .where((t) => !t.missing)
          .toList();

  Future<List<Track>> _pending(List<Track> tracks) async {
    final done = await _db.fingerprintsDao.sizes(fingerprintVersion);
    return [
      for (final t in tracks)
        if (done[t.id] != t.sizeBytes && !_isUnreadable(t)) t,
    ];
  }

  Future<void> _count() async {
    final tracks = await _tracks();
    final pending = await _pending(tracks);
    if (_disposed) return;
    final unreadable = tracks.where(_isUnreadable).length;
    state = LibraryFingerprintsState(
      ready: tracks.length - pending.length - unreadable,
      unreadable: unreadable,
      total: tracks.length,
      running: _running,
      timings: state.timings,
    );
  }

  /// Fingerprints every song that needs it. Returns at once when already
  /// running.
  Future<void> start() async {
    if (_running) return;
    _running = true;
    try {
      final tracks = await _tracks();
      final pending = await _pending(tracks);
      var unreadable = tracks.where(_isUnreadable).length;
      var ready = tracks.length - pending.length - unreadable;
      state = LibraryFingerprintsState(
        ready: ready,
        unreadable: unreadable,
        total: tracks.length,
        running: pending.isNotEmpty,
      );
      final decoder = ref.read(audioDecoderProvider);
      final device = await decoder.device();
      // Leave a core for the app itself.
      final workers = device == null
          ? decodeWorkers
          : (device.cores - 1).clamp(1, decodeWorkers);
      var timings = FingerprintTimings(device: device, workers: workers);
      if (_disposed) return;
      state = LibraryFingerprintsState(
        ready: ready,
        unreadable: unreadable,
        total: tracks.length,
        running: pending.isNotEmpty,
        timings: timings,
      );
      final queue = pending.iterator;
      final clock = Stopwatch()..start();
      var doneHere = 0;
      Future<void> worker() async {
        while (!_disposed && queue.moveNext()) {
          final track = queue.current;
          var read = false;
          try {
            final audio = await decoder.decode(track.uri);
            if (audio != null) {
              final watch = Stopwatch()..start();
              final bytes = await _fingerprint(audio.pcm16);
              timings = timings.add(audio, watch.elapsed);
              await _db.fingerprintsDao.put(
                track.id,
                version: fingerprintVersion,
                sizeBytes: track.sizeBytes,
                data: bytes,
              );
              read = true;
            }
          } catch (e, s) {
            _log.warning('Could not fingerprint track ${track.id}', e, s);
          }
          if (_disposed) return;
          if (read) {
            _unreadable.remove(track.id);
            ready++;
          } else {
            _unreadable[track.id] = track.sizeBytes;
            unreadable++;
          }
          doneHere++;
          final remaining = tracks.length - ready - unreadable;
          state = LibraryFingerprintsState(
            ready: ready,
            unreadable: unreadable,
            total: tracks.length,
            running: true,
            left: doneHere < workers
                ? null
                : clock.elapsed * remaining ~/ doneHere,
            timings: timings,
          );
          // A breather between songs, so the phone isn't flat out the whole
          // time.
          await Future<void>.delayed(songPause);
        }
      }

      await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    } catch (e, s) {
      _log.warning('Fingerprinting the library stopped', e, s);
    } finally {
      _running = false;
      if (!_disposed) await _count();
    }
  }
}

/// The offline fingerprint of [pcm16] as bytes, off the UI isolate. The
/// samples are moved there, not copied, and only made into floats there.
Future<Uint8List> _fingerprint(Uint8List pcm16) {
  final moved = TransferableTypedData.fromList([pcm16]);
  return Isolate.run(
    () => const Fingerprinter()
        .fingerprint(
          pcm16ToFloat(moved.materialize().asUint8List()),
          density: FingerprintDensity.offline,
        )
        .toBytes(),
  );
}
