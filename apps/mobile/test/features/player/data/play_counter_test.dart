import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/player/data/play_counter.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

Track _track(int id, {int seconds = 180}) => Track.fromScan(
  id,
  scannedAudio(id, '/m/$id.mp3', durationMs: seconds * 1000),
);

void main() {
  late DateTime now;
  late List<Track> counted;
  late PlayCounter counter;

  /// Runs [body] with the counter's clock at [now].
  void run(void Function() body) => withClock(Clock(() => now), body);

  void wait(int seconds) => now = now.add(Duration(seconds: seconds));

  setUp(() {
    now = DateTime.utc(2026, 10, 26, 12);
    counted = [];
    counter = PlayCounter(onCounted: counted.add);
  });

  test('counts once 30 s have been heard, and only once', () {
    final song = _track(1);
    run(() {
      counter
        ..start(song)
        ..setPlaying(true);
      wait(29);
      counter.tick();
      expect(counted, isEmpty);

      wait(1);
      counter.tick();
      expect(counted, [song]);

      wait(60);
      counter
        ..tick()
        ..completed();
      expect(counted, [song]);
    });
  });

  test('time paused does not count', () {
    final song = _track(1);
    run(() {
      counter
        ..start(song)
        ..setPlaying(true);
      wait(20);
      counter.setPlaying(false);
      wait(600);
      counter.tick();
      expect(counted, isEmpty);

      counter.setPlaying(true);
      wait(9);
      counter.tick();
      expect(counted, isEmpty);
      wait(1);
      counter.tick();
      expect(counted, [song]);
    });
  });

  test('pausing past 30 s counts at the pause', () {
    final song = _track(1);
    run(() {
      counter
        ..start(song)
        ..setPlaying(true);
      wait(31);
      counter.setPlaying(false);
      expect(counted, [song]);
    });
  });

  test('seeking back within a play does not count it again', () {
    final song = _track(1);
    run(() {
      counter
        ..start(song)
        ..setPlaying(true);
      wait(40);
      counter.tick();
      // A seek: the backend buffers, then plays on from the new position.
      counter.setPlaying(false);
      counter.setPlaying(true);
      wait(40);
      counter.tick();
      expect(counted, [song]);
    });
  });

  test('seeking forward does not count as listening', () {
    final song = _track(1);
    run(() {
      counter
        ..start(song)
        ..setPlaying(true);
      wait(5);
      // Jumped to near the end; the jump itself takes no time.
      counter
        ..setPlaying(false)
        ..setPlaying(true);
      wait(5);
      counter.completed();
      expect(counted, isEmpty);
    });
  });

  test('a song shorter than 30 s counts after its full length', () {
    final short = _track(1, seconds: 12);
    run(() {
      counter
        ..start(short)
        ..setPlaying(true);
      wait(11);
      counter.tick();
      expect(counted, isEmpty);
      wait(1);
      counter.tick();
      expect(counted, [short]);
    });
  });

  test('a short song counts at its end even if the last update was early', () {
    final short = _track(1, seconds: 12);
    run(() {
      counter
        ..start(short)
        ..setPlaying(true);
      wait(3);
      counter.completed();
      expect(counted, [short]);
    });
  });

  test('a long song reaching its end early (seeked) does not count', () {
    final song = _track(1);
    run(() {
      counter
        ..start(song)
        ..setPlaying(true);
      wait(10);
      counter.completed();
      expect(counted, isEmpty);
    });
  });

  test('a new play (next song or repeat one) can count again', () {
    final a = _track(1);
    final b = _track(2);
    run(() {
      counter
        ..start(a)
        ..setPlaying(true);
      wait(30);
      counter.tick();
      // The next song starts while still playing.
      counter.start(b);
      wait(30);
      counter.tick();
      // Repeat one: the same song again.
      counter.start(b);
      wait(30);
      counter.tick();
    });
    expect(counted, [a, b, b]);
  });

  test('a song skipped before 30 s does not count', () {
    final a = _track(1);
    final b = _track(2);
    run(() {
      counter
        ..start(a)
        ..setPlaying(true);
      wait(20);
      counter.start(b);
      wait(15);
      counter.tick();
    });
    expect(counted, isEmpty);
  });

  test('stop ends the play without counting', () {
    final song = _track(1);
    run(() {
      counter
        ..start(song)
        ..setPlaying(true);
      wait(20);
      counter.stop();
      wait(20);
      counter
        ..tick()
        ..completed();
    });
    expect(counted, isEmpty);
  });
}
