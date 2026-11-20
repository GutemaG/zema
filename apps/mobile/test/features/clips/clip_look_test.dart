import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/clips/application/clip_look.dart';
import 'package:zema/features/clips/application/clip_timeline.dart';

const _s = Duration(seconds: 1);

Future<ui.Image> _decode(List<int> png) async {
  final codec = await ui.instantiateImageCodec(
    png is Uint8List ? png : Uint8List.fromList(png),
  );
  return (await codec.getNextFrame()).image;
}

void main() {
  group('defaultClipRange', () {
    final starts = [_s * 12, _s * 20, _s * 31];

    test('from a second before the first line, for 60 s', () {
      expect(defaultClipRange(starts, _s * 240), (
        start: _s * 11,
        end: _s * 71,
      ));
    });

    test('from the line being sung when the track is playing', () {
      expect(defaultClipRange(starts, _s * 240, position: _s * 25), (
        start: _s * 20,
        end: _s * 80,
      ));
    });

    test('near the end it moves back to keep 60 s', () {
      expect(defaultClipRange(starts, _s * 80, position: _s * 70), (
        start: _s * 20,
        end: _s * 80,
      ));
    });

    test('a short track is clipped whole', () {
      expect(defaultClipRange(const [], _s * 45), (
        start: Duration.zero,
        end: _s * 45,
      ));
    });
  });

  group('range editing', () {
    final starts = [_s * 12, _s * 20, _s * 31];

    test('a handle snaps to a line start within 2 s', () {
      expect(snapToLine(starts, _s * 19), _s * 20);
      expect(snapToLine(starts, _s * 25), _s * 25);
    });

    test('steps go line by line, or a second without lines', () {
      expect(stepToLine(starts, _s * 20, forward: true), _s * 31);
      expect(stepToLine(starts, _s * 20, forward: false), _s * 12);
      expect(stepToLine(const [], _s * 20, forward: true), _s * 21);
    });

    test('the range stays 5 s to 2 min inside the track', () {
      expect(clampClipRange(_s * 58, _s * 60, _s * 200, movedStart: true), (
        start: _s * 58,
        end: _s * 63,
      ));
      expect(clampClipRange(_s * 10, _s * 190, _s * 200, movedStart: false), (
        start: _s * 70,
        end: _s * 190,
      ));
      expect(clampClipRange(_s * 198, _s * 210, _s * 200, movedStart: true), (
        start: _s * 195,
        end: _s * 200,
      ));
    });
  });

  testWidgets('frames are 1080×1920 and rows stack in order', (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
          .drawColor(const ui.Color(0xFF884422), ui.BlendMode.src);
      final cover = await recorder.endRecording().toImage(300, 300);
      final layout = ClipLyricsLayout([
        '',
        'ባይተዋር አረገኝ',
        'ባይተዋር አረገኝ ናፍቆትሽ ' * 6,
        '',
        'ፍቅር',
      ]);
      expect(layout.rows[0], '•  •  •');
      for (var i = 1; i < layout.rows.length; i++) {
        expect(layout.scroll(i - 1, i), greaterThan(0));
      }
      final layer = await _decode(await paintClipLyrics(layout, 2));
      expect((layer.width, layer.height), (1080, 1920));
      layer.dispose();
      for (final scene in [
        ClipScene(title: 'ባይተዋር አረገኝ', artist: 'Alemayehu Hirpo', cover: cover),
        ClipScene(title: 'Song', look: const ClipLook(mark: false)),
      ]) {
        final background = await _decode(await scene.background());
        expect((background.width, background.height), (1080, 1920));
        background.dispose();
        final preview = await _decode(
          await paintClipPreview(scene, layout, 1, scale: 0.5),
        );
        expect((preview.width, preview.height), (540, 960));
        preview.dispose();
        scene.dispose();
      }
    });
  });
}
