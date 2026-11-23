import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/clips/application/clip_timeline.dart';
import 'package:zema/features/clips/data/clip_encoder.dart';

const _s = Duration(seconds: 1);

ClipRequest _request({
  Duration start = Duration.zero,
  Duration end = const Duration(seconds: 60),
  List<ClipFrame> frames = const [ClipFrame('a.png', Duration.zero)],
}) => ClipRequest(
  audioUri: 'content://media/1',
  start: start,
  end: end,
  background: 'bg.png',
  frames: frames,
  outPath: 'out.mp4',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('clipFrameTimes', () {
    final starts = [_s * 2, _s * 5, _s * 9, _s * 70];

    test('the line sung at the start, then each line starting inside', () {
      expect(clipFrameTimes(starts, _s * 3, _s * 63), [
        (line: 0, at: Duration.zero),
        (line: 1, at: _s * 2),
        (line: 2, at: _s * 6),
      ]);
    });

    test('before the first line there is no line', () {
      expect(clipFrameTimes(starts, Duration.zero, _s * 6), [
        (line: null, at: Duration.zero),
        (line: 0, at: _s * 2),
        (line: 1, at: _s * 5),
      ]);
    });

    test('a line starting exactly at the start is the first frame', () {
      expect(clipFrameTimes(starts, _s * 5, _s * 9), [
        (line: 1, at: Duration.zero),
      ]);
    });

    test('plain lyrics: one frame', () {
      expect(clipFrameTimes(const [], _s, _s * 10), [
        (line: null, at: Duration.zero),
      ]);
    });
  });

  group('ClipRequest', () {
    test('needs an end after the start, at most 2 minutes in', () {
      expect(() => _request(end: Duration.zero), throwsArgumentError);
      expect(
        () => _request(end: maxClipLength + const Duration(milliseconds: 1)),
        throwsArgumentError,
      );
      expect(_request(end: maxClipLength).length, maxClipLength);
    });

    test('needs frames in order, the first at zero', () {
      expect(() => _request(frames: const []), throwsArgumentError);
      expect(
        () => _request(frames: const [ClipFrame('a.png', _s)]),
        throwsArgumentError,
      );
      expect(
        () => _request(
          frames: const [
            ClipFrame('a.png', Duration.zero),
            ClipFrame('b.png', Duration(seconds: 4)),
            ClipFrame('c.png', Duration(seconds: 2)),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('AndroidClipEncoder', () {
    const channel = MethodChannel('zema/clip');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<MethodCall> calls;
    late Completer<Object?> answer;

    setUp(() {
      calls = [];
      answer = Completer();
      messenger.setMockMethodCallHandler(channel, (call) {
        calls.add(call);
        return call.method == 'encode' ? answer.future : Future.value();
      });
    });
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    Future<void> progress(String id, double fraction) =>
        messenger.handlePlatformMessage(
          'zema/clip',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('progress', {'id': id, 'fraction': fraction}),
          ),
          (_) {},
        );

    test('sends the request, reports progress and the clip', () async {
      final encoder = AndroidClipEncoder();
      final job = encoder.encode(
        _request(
          start: _s * 3,
          end: _s * 63,
          frames: const [
            ClipFrame('a.png', Duration.zero),
            ClipFrame('b.png', Duration(milliseconds: 2500), scroll: 0.1),
          ],
        ),
      );
      final seen = <double>[];
      job.progress.listen(seen.add);
      await pumpEventQueue();
      final args = calls.single.arguments as Map<Object?, Object?>;
      expect(args['startMs'], 3000);
      expect(args['endMs'], 63000);
      expect(args['fps'], 30);
      expect(args['transitionMs'], 450);
      expect(args['background'], 'bg.png');
      expect(args['window'], {'top': 0, 'bottom': 1, 'fade': 0});
      expect((args['motion'], args['center']), ('scroll', 0.5));
      expect(args['frames'], [
        {'path': 'a.png', 'atMs': 0, 'scroll': 0},
        {'path': 'b.png', 'atMs': 2500, 'scroll': 0.1},
      ]);

      await progress(args['id']! as String, 0.5);
      await progress('another', 0.9);
      answer.complete({
        'path': 'out.mp4',
        'width': 720,
        'height': 1280,
        'millis': 21400,
        'codec': 'c2.hw.avc.encoder',
      });
      final clip = await job.result;
      await pumpEventQueue();
      expect(clip.width, 720);
      expect(clip.took, const Duration(milliseconds: 21400));
      expect(seen, [0.5, 1]);
    });

    test('cancel stops that encode and fails with ClipCancelled', () async {
      final job = AndroidClipEncoder().encode(_request());
      final failed = expectLater(job.result, throwsA(isA<ClipCancelled>()));
      await pumpEventQueue();
      await job.cancel();
      final id = (calls.first.arguments as Map<Object?, Object?>)['id'];
      expect(calls.last.method, 'cancel');
      expect((calls.last.arguments as Map<Object?, Object?>)['id'], id);
      answer.completeError(PlatformException(code: 'cancelled'));
      await failed;
    });

    test('a native failure is a ClipFailed', () async {
      final job = AndroidClipEncoder().encode(_request());
      final failed = expectLater(job.result, throwsA(isA<ClipFailed>()));
      answer.completeError(
        PlatformException(code: 'encode_failed', message: 'No H.264 encoder'),
      );
      await failed;
    });
  });
}
