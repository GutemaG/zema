import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/player/data/player_snapshot.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';

List<Track> _tracks(int count) => [
  for (var i = 1; i <= count; i++)
    Track.fromScan(i, scannedAudio(100 + i, '/m/$i.mp3', title: 'Song $i')),
];

void main() {
  late FakeAudioBackend backend;
  late ZemaAudioHandler handler;

  setUp(() {
    backend = FakeAudioBackend();
    handler = fakeAudioHandler(backend);
  });

  PlayerSnapshot snap() => handler.snapshot;
  String? currentTitle() => snap().current?.title;

  group('ZemaAudioHandler', () {
    test('starts empty and idle', () {
      expect(snap().hasTrack, isFalse);
      expect(handler.mediaItem.value, isNull);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
    });

    test('plays a list from the chosen track', () async {
      final tracks = _tracks(3);

      await handler.playTracks(tracks, start: 1);

      await pumpEventQueue();

      expect(currentTitle(), 'Song 2');
      expect(snap().playing, isTrue);
      expect(snap().queue, tracks);
      expect(backend.loaded, [tracks[1].uri]);
    });

    test('ignores an empty list', () async {
      await handler.playTracks(const []);
      await pumpEventQueue();

      expect(snap().hasTrack, isFalse);
      expect(backend.loaded, isEmpty);
    });

    test('tells the system what is playing', () async {
      await handler.playTracks(_tracks(2));
      await pumpEventQueue();

      final item = handler.mediaItem.value!;
      expect(item.id, '1');
      expect(item.title, 'Song 1');
      expect(
        item.artUri.toString(),
        'content://media/external/audio/media/101',
      );
      expect(item.extras?['loadThumbnailUri'], 'true');
      final state = handler.playbackState.value;
      expect(state.playing, isTrue);
      expect(state.controls, contains(MediaControl.pause));
      expect(state.queueIndex, 0);
      expect(state.processingState, AudioProcessingState.ready);
    });

    test('pause and play', () async {
      await handler.playTracks(_tracks(1));
      await pumpEventQueue();

      await handler.pause();

      await pumpEventQueue();
      expect(snap().playing, isFalse);
      expect(handler.playbackState.value.controls, contains(MediaControl.play));

      await handler.play();

      await pumpEventQueue();
      expect(snap().playing, isTrue);
    });

    test('next keeps playing and stops at the end with repeat off', () async {
      await handler.playTracks(_tracks(2));
      await pumpEventQueue();

      await handler.skipToNext();

      await pumpEventQueue();
      expect(currentTitle(), 'Song 2');
      expect(snap().playing, isTrue);

      await handler.skipToNext();

      await pumpEventQueue();
      expect(currentTitle(), 'Song 2');
      expect(backend.loaded, hasLength(2));
    });

    test('next while paused stays paused', () async {
      await handler.playTracks(_tracks(2));
      await pumpEventQueue();
      await handler.pause();
      await pumpEventQueue();

      await handler.skipToNext();

      await pumpEventQueue();

      expect(currentTitle(), 'Song 2');
      expect(snap().playing, isFalse);
    });

    test('previous restarts the track after 3 s, else goes back', () async {
      await handler.playTracks(_tracks(3), start: 1);
      await pumpEventQueue();
      backend.advanceTo(const Duration(seconds: 10));
      await pumpEventQueue();

      await handler.skipToPrevious();

      await pumpEventQueue();
      expect(currentTitle(), 'Song 2');
      expect(backend.position, Duration.zero);

      await handler.skipToPrevious();

      await pumpEventQueue();
      expect(currentTitle(), 'Song 1');
    });

    test('moves on when a track ends', () async {
      await handler.playTracks(_tracks(2));
      await pumpEventQueue();

      backend.finishTrack();
      await pumpEventQueue();

      expect(currentTitle(), 'Song 2');
      expect(snap().playing, isTrue);
    });

    test('stops at the end of the queue with repeat off', () async {
      await handler.playTracks(_tracks(1));
      await pumpEventQueue();

      backend.finishTrack();
      await pumpEventQueue();

      expect(currentTitle(), 'Song 1');
      expect(snap().playing, isFalse);
      expect(backend.position, Duration.zero);
    });

    test('repeat all starts over and repeat one replays', () async {
      await handler.playTracks(_tracks(2), start: 1);
      await pumpEventQueue();

      await handler.setRepeatMode(AudioServiceRepeatMode.all);

      await pumpEventQueue();
      expect(snap().repeat, QueueRepeat.all);
      backend.finishTrack();
      await pumpEventQueue();
      expect(currentTitle(), 'Song 1');

      await handler.setRepeatMode(AudioServiceRepeatMode.one);

      await pumpEventQueue();
      backend.advanceTo(const Duration(seconds: 50));
      await pumpEventQueue();
      backend.finishTrack();
      await pumpEventQueue();
      expect(currentTitle(), 'Song 1');
      expect(backend.position, Duration.zero);
      expect(snap().playing, isTrue);
    });

    test('shuffle keeps the current track and can be turned off', () async {
      final tracks = _tracks(10);
      await handler.playTracks(tracks, start: 4);
      await pumpEventQueue();

      await handler.setShuffleMode(AudioServiceShuffleMode.all);

      await pumpEventQueue();
      expect(snap().shuffle, isTrue);
      expect(currentTitle(), 'Song 5');
      expect(snap().index, 0);
      expect(snap().queue.toSet(), tracks.toSet());

      await handler.setShuffleMode(AudioServiceShuffleMode.none);

      await pumpEventQueue();
      expect(snap().queue, tracks);
      expect(currentTitle(), 'Song 5');
    });

    test('playing shuffled starts with the chosen track', () async {
      await handler.playTracks(_tracks(5), start: 3, shuffle: true);
      await pumpEventQueue();

      expect(currentTitle(), 'Song 4');
      expect(snap().shuffle, isTrue);
    });

    test('skips an unplayable file, reports it and plays the next', () async {
      final tracks = _tracks(3);
      backend.unplayable.add(tracks[0].uri);
      final skipped = <Track>[];
      handler.unplayable.listen(skipped.add);

      await handler.playTracks(tracks);
      await pumpEventQueue();

      expect(skipped, [tracks[0]]);
      expect(currentTitle(), 'Song 2');
      expect(snap().playing, isTrue);
    });

    test('clears the queue when nothing in it can be played', () async {
      final tracks = _tracks(2);
      backend.unplayable.addAll(tracks.map((t) => t.uri));
      final skipped = <Track>[];
      handler.unplayable.listen(skipped.add);

      await handler.playTracks(tracks);
      await pumpEventQueue();

      expect(skipped, tracks);
      expect(snap().hasTrack, isFalse);
      expect(handler.mediaItem.value, isNull);
      expect(backend.playing, isFalse);
    });

    test('tries each track only once around a repeating queue', () async {
      final tracks = _tracks(3);
      backend.unplayable.addAll(tracks.map((t) => t.uri));
      await handler.setRepeatMode(AudioServiceRepeatMode.all);
      await pumpEventQueue();

      await handler.playTracks(tracks);

      await pumpEventQueue();

      expect(backend.loaded, hasLength(3));
    });

    test('restore loads paused at the saved position', () async {
      final tracks = _tracks(3);

      await handler.restore(
        tracks,
        index: 2,
        position: const Duration(seconds: 42),
        repeat: QueueRepeat.all,
      );

      expect(currentTitle(), 'Song 3');
      expect(snap().playing, isFalse);
      expect(snap().repeat, QueueRepeat.all);
      expect(snap().shuffle, isFalse);
      expect(backend.position, const Duration(seconds: 42));
    });

    test('play after the queue finished plays from the start', () async {
      await handler.playTracks(_tracks(1));
      await pumpEventQueue();
      backend.finishTrack();
      await pumpEventQueue();
      expect(snap().playing, isFalse);

      await handler.play();

      await pumpEventQueue();

      expect(snap().playing, isTrue);
      expect(backend.position, Duration.zero);
    });

    test('skipToQueueItem plays that item and ignores bad indexes', () async {
      await handler.playTracks(_tracks(3));
      await pumpEventQueue();

      await handler.skipToQueueItem(2);

      await pumpEventQueue();
      expect(currentTitle(), 'Song 3');

      await handler.skipToQueueItem(7);

      await pumpEventQueue();
      expect(currentTitle(), 'Song 3');
    });

    test('uses the duration the backend reports', () async {
      backend.duration = const Duration(seconds: 123);

      await handler.playTracks(_tracks(1));

      await pumpEventQueue();

      expect(snap().duration, const Duration(seconds: 123));
      expect(handler.mediaItem.value?.duration, const Duration(seconds: 123));
    });

    test('stop stops the backend', () async {
      await handler.playTracks(_tracks(1));
      await pumpEventQueue();

      await handler.stop();

      await pumpEventQueue();

      expect(backend.playing, isFalse);
    });
  });

  group('Editing the queue', () {
    setUp(() async {
      await handler.playTracks(_tracks(4), start: 1);
      await pumpEventQueue();
    });

    List<String> titles() => [for (final t in snap().queue) t.title];

    test('every entry has its own key, even a song queued twice', () async {
      expect(snap().queueKeys, hasLength(4));
      expect(snap().queueKeys.toSet(), hasLength(4));
    });

    test('move changes the order and keeps the current song', () async {
      await handler.moveQueueItem(3, 0);

      expect(titles(), ['Song 4', 'Song 1', 'Song 2', 'Song 3']);
      expect(currentTitle(), 'Song 2');
      expect(snap().index, 2);
      expect(backend.loaded, hasLength(1), reason: 'nothing reloads');
    });

    test('remove and restore an upcoming song', () async {
      final keys = snap().queueKeys;

      final removal = await handler.removeQueueEntry(2);
      expect(titles(), ['Song 1', 'Song 2', 'Song 4']);

      await handler.restoreQueueItem(removal!);
      expect(titles(), ['Song 1', 'Song 2', 'Song 3', 'Song 4']);
      expect(snap().queueKeys, keys);
      expect(currentTitle(), 'Song 2');
    });

    test('the current song cannot be removed', () async {
      expect(await handler.removeQueueEntry(1), isNull);
      expect(titles(), hasLength(4));
    });

    test('clear upcoming keeps what played and the current song', () async {
      await handler.clearUpcoming();

      expect(titles(), ['Song 1', 'Song 2']);
      expect(currentTitle(), 'Song 2');
      expect(snap().playing, isTrue);
    });
  });

  group('Play next and add to queue', () {
    List<String> titles() => [for (final t in snap().queue) t.title];
    final extra = Track.fromScan(
      9,
      scannedAudio(109, '/m/9.mp3', title: 'Extra'),
    );

    test('play next goes right after the current song', () async {
      await handler.playTracks(_tracks(3), start: 1);
      await pumpEventQueue();

      await handler.playNext([extra]);

      expect(titles(), ['Song 1', 'Song 2', 'Extra', 'Song 3']);
      expect(currentTitle(), 'Song 2');
      expect(backend.loaded, hasLength(1), reason: 'nothing reloads');
    });

    test('add to queue goes to the end', () async {
      await handler.playTracks(_tracks(3), start: 1);
      await pumpEventQueue();

      await handler.addToQueue([extra]);

      expect(titles(), ['Song 1', 'Song 2', 'Song 3', 'Extra']);
      expect(currentTitle(), 'Song 2');
    });

    test('with nothing queued, the song is loaded paused', () async {
      await handler.addToQueue([extra]);
      await pumpEventQueue();

      expect(titles(), ['Extra']);
      expect(currentTitle(), 'Extra');
      expect(backend.loaded, [extra.uri]);
      expect(snap().playing, isFalse);
    });

    test('with nothing queued, play next also loads it paused', () async {
      await handler.playNext([extra]);
      await pumpEventQueue();

      expect(currentTitle(), 'Extra');
      expect(snap().playing, isFalse);
    });
  });
}
