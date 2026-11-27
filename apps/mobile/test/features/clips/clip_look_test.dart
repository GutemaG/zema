import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/features/clips/application/clip_look.dart';
import 'package:zema/features/clips/data/clip_encoder.dart';
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
          await paintClipBackground(scene, scale: 0.5),
        );
        expect((preview.width, preview.height), (540, 960));
        preview.dispose();
        scene.dispose();
      }
    });
  });

  group('ClipLook', () {
    test('defaults: song colours, no dim, 40 % behind pictures', () {
      const look = ClipLook();
      expect(look.background, ClipBackground.song);
      expect(look.effectiveDim, 0);
      expect(look.copyWith(background: ClipBackground.cover).effectiveDim, 0.4);
      expect(
        (look.showTitle, look.showArtist, look.showAlbum),
        (true, true, false),
      );
    });

    test('keeps choices but not photos or edited names', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await const ClipLook(
        background: ClipBackground.photo,
        photo: '/p.jpg',
        dim: 0.3,
        textSize: ClipTextSize.large,
        textColor: 2,
        position: ClipTextPosition.top,
        showAlbum: true,
        title: 'Edited',
        artistPicture: '/a.jpg',
        mark: false,
        style: ClipLyricsStyle.line,
        animation: ClipLineAnimation.zoom,
      ).save(prefs);
      final back = ClipLook.fromPrefs(prefs);
      expect(back.background, ClipBackground.song);
      expect(back.photo, isNull);
      expect(back.dim, 0.3);
      expect(back.textSize, ClipTextSize.large);
      expect(back.textColor, 2);
      expect(back.position, ClipTextPosition.top);
      expect(back.showAlbum, isTrue);
      expect(back.title, isNull);
      expect(back.artistPicture, isNull);
      expect(back.mark, isFalse);
      expect(back.motion, ClipMotion.zoom);
    });

    test('keeps a dragged position, within its limits', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await ClipLook(position: ClipTextPosition(0.35, 0.7)).save(prefs);
      expect(ClipLook.fromPrefs(prefs).position, ClipTextPosition(0.35, 0.7));
      expect(
        ClipTextPosition.center.moved(-1, 1),
        ClipTextPosition(ClipTextPosition.minX, ClipTextPosition.maxFocus),
      );
    });

    test('reads the preset names kept before positions were free', () async {
      SharedPreferences.setMockInitialValues({
        ClipLook.prefsKey: '{"position": "bottom"}',
      });
      expect(
        ClipLook.fromPrefs(await SharedPreferences.getInstance()).position,
        ClipTextPosition.bottom,
      );
    });

    test('bad saved choices fall back to the defaults', () async {
      SharedPreferences.setMockInitialValues({
        ClipLook.prefsKey: '{"textColor": 99, "dim": "x", "background": 3}',
      });
      final back = ClipLook.fromPrefs(await SharedPreferences.getInstance());
      expect(back.textColor, 0);
      expect(back.dim, isNull);
      expect(back.background, ClipBackground.song);
      SharedPreferences.setMockInitialValues({ClipLook.prefsKey: 'not json'});
      expect(
        ClipLook.fromPrefs(await SharedPreferences.getInstance()).background,
        ClipBackground.song,
      );
    });
  });

  testWidgets('a bright background is dimmed until the text reads', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
          .drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
      final white = await recorder.endRecording().toImage(64, 64);
      final scene = ClipScene(
        title: 'Song',
        cover: white,
        look: const ClipLook(background: ClipBackground.photo, dim: 0),
      );
      final image = await _decode(await scene.background());
      final pixel = (await image.toByteData())!;
      const at = (1500 * 1080 + 540) * 4;
      expect(pixel.getUint8(at), inInclusiveRange(80, 120));
      image.dispose();
      scene.dispose();
    });
  });

  testWidgets('transliterations make rows taller when shown', (tester) async {
    await tester.runAsync(() async {
      const rows = ['', 'ፍቅር'];
      const translits = [null, 'fikir'];
      final plain = ClipLyricsLayout(rows, translits: translits);
      final shown = ClipLyricsLayout(
        rows,
        translits: translits,
        look: const ClipLook(transliteration: true),
      );
      expect(plain.translits[1], isNull);
      expect(shown.translits[1], 'fikir');
      expect(shown.heights[1], greaterThan(plain.heights[1]));
    });
  });

  test('one line at a time moves by its animation; scrolling scrolls', () {
    const look = ClipLook();
    expect(look.motion, ClipMotion.scroll);
    expect(look.copyWith(style: ClipLyricsStyle.line).motion, ClipMotion.rise);
  });

  test('every motion ends with only the new line, in place', () {
    for (final motion in ClipMotion.values) {
      final (old, next) = clipMoves(motion, 1, scroll: 0.1);
      expect(old.alpha, 0, reason: '$motion');
      expect(next, (alpha: 1.0, shift: 0.0, scale: 1.0), reason: '$motion');
      final (start, _) = clipMoves(motion, 0, scroll: 0.1);
      expect(start, (alpha: 1.0, shift: 0.0, scale: 1.0), reason: '$motion');
    }
  });

  testWidgets('one line at a time paints only the sung line', (tester) async {
    await tester.runAsync(() async {
      Future<int> inkRows(ClipLook look) async {
        final layout = ClipLyricsLayout(const [
          'ባይተዋር አረገኝ',
          'ባዶ ቤት ታቅፌ',
          'ፍቅር',
        ], look: look);
        final image = await _decode(await paintClipLyrics(layout, 1));
        final data = (await image.toByteData())!;
        var rows = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x += 8) {
            if (data.getUint8((y * image.width + x) * 4 + 3) > 40) {
              rows++;
              break;
            }
          }
        }
        image.dispose();
        return rows;
      }

      final scroll = await inkRows(const ClipLook());
      final line = await inkRows(const ClipLook(style: ClipLyricsStyle.line));
      expect(line, greaterThan(0));
      expect(line, lessThan(scroll / 2));
    });
  });

  testWidgets('a still page centres all its lines on the text position', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final position in [
        ...ClipTextPosition.presets,
        ClipTextPosition(0.5, 0.8),
      ]) {
        final layout = ClipLyricsLayout(const [
          'ባይተዋር አረገኝ',
          'ባዶ ቤት ታቅፌ',
          'ፍቅር',
        ], look: ClipLook(position: position));
        final image = await _decode(
          await paintClipLyrics(layout, ClipLyricsLayout.page),
        );
        final data = (await image.toByteData())!;
        int? first;
        var last = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x += 8) {
            if (data.getUint8((y * image.width + x) * 4 + 3) > 200) {
              first ??= y;
              last = y;
              break;
            }
          }
        }
        expect(first, isNotNull);
        final middle = (first! + last) / 2 / image.height;
        expect(middle, closeTo(position.focus, 0.03));
        image.dispose();
      }
    });
  });

  testWidgets('lyrics moved to one side stay on the frame', (tester) async {
    await tester.runAsync(() async {
      final position = ClipTextPosition(ClipTextPosition.minX, 0.42);
      final layout = ClipLyricsLayout(const [
        'ባይተዋር አረገኝ ባዶ ቤት ታቅፌ ፍቅር',
      ], look: ClipLook(position: position));
      final image = await _decode(
        await paintClipLyrics(layout, ClipLyricsLayout.page),
      );
      final data = (await image.toByteData())!;
      int? left;
      var right = 0;
      for (var x = 0; x < image.width; x++) {
        for (var y = 0; y < image.height; y += 4) {
          if (data.getUint8((y * image.width + x) * 4 + 3) > 200) {
            left ??= x;
            right = x;
            break;
          }
        }
      }
      expect(left, greaterThan(0));
      expect((left! + right) / 2 / image.width, closeTo(position.x, 0.03));
      image.dispose();
    });
  });
}
