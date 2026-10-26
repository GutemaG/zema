import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/preferences_provider.dart';
import '../../settings/application/settings_controller.dart';
import '../data/audio_backend.dart';
import '../data/player_persistence.dart';
import '../data/player_snapshot.dart';
import '../data/sleep_timer.dart';
import '../data/zema_audio_handler.dart';

final _log = Logger('player.session');

/// The player started in `main()` with `AudioService.init`. Tests override it
/// with a handler over a fake backend.
final audioHandlerProvider = Provider<ZemaAudioHandler>(
  (ref) => throw UnimplementedError(
    'audioHandlerProvider must be overridden with the handler returned by '
    'AudioService.init (see main.dart).',
  ),
);

/// What the player is doing; [PlayerSnapshot.empty] before anything loads.
final playerStateProvider = StreamProvider<PlayerSnapshot>(
  (ref) => ref.watch(audioHandlerProvider).snapshots,
);

/// The current track's position, updated while playing.
final positionProvider = StreamProvider<Duration>(
  (ref) => ref.watch(audioHandlerProvider).positions,
);

/// The track that is loaded (playing or paused), or null.
final currentTrackProvider = Provider<Track?>(
  (ref) => ref.watch(playerStateProvider).value?.current,
);

/// The running sleep timer, or null.
final sleepTimerProvider = Provider<SleepTimer?>(
  (ref) => ref.watch(playerStateProvider).value?.sleepTimer,
);

/// A track that was skipped because it couldn't be played.
///
/// Each skip is a new object (no `==` override), so the same track failing
/// twice is reported twice.
class SkippedTrack {
  SkippedTrack(this.track);

  final Track track;
}

/// Tracks that were skipped because they couldn't be played.
final unplayableTrackProvider = StreamProvider<SkippedTrack>(
  (ref) => ref.watch(audioHandlerProvider).unplayable.map(SkippedTrack.new),
);

final playerControllerProvider = Provider<PlayerController>(
  (ref) => PlayerController(ref.watch(audioHandlerProvider)),
);

/// The commands the UI sends to the player.
class PlayerController {
  const PlayerController(this._handler);

  final ZemaAudioHandler _handler;

  /// Plays [tracks] from [start]; with [shuffle], that track first and the
  /// rest shuffled.
  Future<void> playList(
    List<Track> tracks, {
    int start = 0,
    bool shuffle = false,
  }) => _handler.playTracks(tracks, start: start, shuffle: shuffle);

  /// Plays [tracks] shuffled, starting from a random one.
  Future<void> shuffleList(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    await playList(
      tracks,
      start: Random().nextInt(tracks.length),
      shuffle: true,
    );
  }

  Future<void> togglePlay() =>
      _handler.snapshot.playing ? _handler.pause() : _handler.play();

  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> next() => _handler.skipToNext();
  Future<void> previous() => _handler.skipToPrevious();

  Future<void> toggleShuffle() => _handler.setShuffleMode(
    _handler.snapshot.shuffle
        ? AudioServiceShuffleMode.none
        : AudioServiceShuffleMode.all,
  );

  /// Plays the queue entry at [index] (in play order).
  Future<void> playQueueItem(int index) => _handler.skipToQueueItem(index);

  Future<void> moveInQueue(int from, int to) =>
      _handler.moveQueueItem(from, to);

  /// Removes the queue entry at [index]. Returns a function that puts it
  /// back, or null when nothing was removed (the current track).
  Future<Future<void> Function()?> removeFromQueue(int index) async {
    final removal = await _handler.removeQueueEntry(index);
    if (removal == null) return null;
    return () => _handler.restoreQueueItem(removal);
  }

  Future<void> clearUpcoming() => _handler.clearUpcoming();

  /// Queues [track] right after the current one.
  Future<void> playNext(Track track) => _handler.playNext([track]);

  /// Queues [track] at the end.
  Future<void> addToQueue(Track track) => _handler.addToQueue([track]);

  /// Queues [tracks] at the end, in order.
  Future<void> addAllToQueue(List<Track> tracks) => _handler.addToQueue(tracks);

  void setSleepTimer(Duration after) => _handler.setSleepTimer(after);
  void sleepAtEndOfTrack() => _handler.sleepAtEndOfTrack();
  void cancelSleepTimer() => _handler.cancelSleepTimer();

  /// Off → all → one → off.
  Future<void> cycleRepeat() =>
      _handler.setRepeatMode(switch (_handler.snapshot.repeat) {
        QueueRepeat.off => AudioServiceRepeatMode.all,
        QueueRepeat.all => AudioServiceRepeatMode.one,
        QueueRepeat.one => AudioServiceRepeatMode.none,
      });
}

final playerPersistenceProvider = Provider<PlayerPersistence>(
  (ref) => PlayerPersistence(ref.watch(sharedPreferencesProvider)),
);

/// How often the position is saved while playing.
const autosaveInterval = Duration(seconds: 10);

/// Restores the last queue (paused) when the app starts, then saves the
/// queue on every pause and every [autosaveInterval] while playing. Kept
/// alive by the app shell.
final playerSessionProvider = Provider<void>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final persistence = ref.watch(playerPersistenceProvider);
  var restored = false;
  var wasPlaying = false;

  Future<void> save() async {
    final snapshot = handler.snapshot;
    if (!snapshot.hasTrack) return;
    await persistence.save(
      queue: snapshot.queue,
      index: snapshot.index,
      position: handler.position,
      repeat: snapshot.repeat,
    );
  }

  Future<void> restore() async {
    try {
      final saved = persistence.load();
      if (saved == null || handler.snapshot.hasTrack) return;
      final dao = ref.read(databaseProvider).libraryDao;
      final tracks = await dao.tracksByIds(saved.trackIds);
      if (tracks.isEmpty || handler.snapshot.hasTrack) return;
      // If the saved track is gone, continue with the next one that exists.
      final savedId = saved.trackIds[saved.index];
      var index = tracks.indexWhere((t) => t.id == savedId);
      final position = index < 0 ? Duration.zero : saved.position;
      if (index < 0) {
        final later = saved.trackIds.skip(saved.index + 1).toSet();
        index = tracks.indexWhere((t) => later.contains(t.id));
        if (index < 0) index = 0;
      }
      await handler.restore(
        tracks,
        index: index,
        position: position,
        repeat: saved.repeat,
      );
    } catch (e, stack) {
      _log.warning('Could not restore the last queue', e, stack);
    } finally {
      restored = true;
    }
  }

  final subscription = handler.snapshots.listen((snapshot) {
    if (restored && wasPlaying && !snapshot.playing) unawaited(save());
    wasPlaying = snapshot.playing;
  });
  final timer = Timer.periodic(autosaveInterval, (_) {
    if (restored && handler.snapshot.playing) unawaited(save());
  });
  ref.onDispose(() {
    unawaited(subscription.cancel());
    timer.cancel();
  });
  unawaited(restore());
});

/// Settings → Playback, as the player takes them.
final playbackOptionsProvider = Provider<PlaybackOptions>((ref) {
  final settings = ref.watch(settingsProvider);
  return PlaybackOptions(
    pauseOnUnplug: settings.pauseOnUnplug,
    duckOnInterruption: settings.duckOnInterruption,
    gapless: settings.gapless,
  );
});

/// Sends [playbackOptionsProvider] to the player at start and on every
/// change. Kept alive by the app shell.
final playbackOptionsSyncProvider = Provider<void>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  ref.listen(
    playbackOptionsProvider,
    (_, options) => unawaited(handler.setOptions(options)),
    fireImmediately: true,
  );
});
