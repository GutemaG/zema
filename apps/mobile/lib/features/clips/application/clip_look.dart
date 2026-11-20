import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../app/theme/clip_colors.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_typography.dart';
import '../data/clip_encoder.dart';

/// The size frames are painted at; the encoder scales them down if it must.
const clipFrameSize = ui.Size(1080, 1920);

/// Where the lyrics show; they fade out at its edges as they scroll.
const ClipWindow clipWindow = (top: 0.2, bottom: 0.97, fade: 0.1);

/// The user's choices for a clip's look. Bolt 068 adds the rest.
class ClipLook {
  const ClipLook({this.mark = true});

  /// Whether the small Zema mark shows in the top corner.
  final bool mark;
}

/// What every frame of one clip shares: the background, header and mark.
class ClipScene {
  ClipScene({
    required this.title,
    this.artist,
    this.cover,
    this.look = const ClipLook(),
  });

  final String title;
  final String? artist;
  final ui.Image? cover;
  final ClipLook look;

  ui.Image? _background;

  Future<ui.Image> _image() async =>
      _background ??= await _paintBackground(this, clipFrameSize);

  /// The background as PNG.
  Future<Uint8List> background() async => _png(await _image(), keep: true);

  void dispose() {
    _background?.dispose();
    _background = null;
  }
}

const _colors = ZemaColors.nightVigil;
const _side = 80.0;
const _coverSize = 132.0;
const _top = 200.0;

/// Where the line being sung sits, as a part of the height.
const _focus = 0.42;
const _gap = 56.0;
const _note = '•  •  •';
const _dim = 0.36;

/// Decodes cover art bytes, or null if they aren't a picture.
Future<ui.Image?> decodeClipCover(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 720);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  } on Exception {
    return null;
  }
}

/// The lyric rows of a clip laid out once, top to bottom, so every frame
/// draws them in the same places. An empty row shows a note.
class ClipLyricsLayout {
  ClipLyricsLayout(List<String> rows)
    : rows = [for (final r in rows) r.trim().isEmpty ? _note : r.trim()] {
    final width = clipFrameSize.width - 2 * _side;
    for (final row in this.rows) {
      final size = row == _note ? 72.0 : _fittedSize(row, width);
      final painter = _rowPainter(row, size, bright: true);
      sizes.add(size);
      heights.add(painter.height);
      painter.dispose();
      centers.add(
        centers.isEmpty
            ? heights.last / 2
            : centers.last +
                  heights[heights.length - 2] / 2 +
                  _gap +
                  heights.last / 2,
      );
    }
  }

  final List<String> rows;
  final sizes = <double>[];
  final heights = <double>[];
  final centers = <double>[];

  /// How far row [to] sits below row [from], as a part of the frame height.
  double scroll(int from, int to) =>
      (centers[to] - centers[from]) / clipFrameSize.height;
}

/// A transparent layer with [row] bright at the focus and the rows around it
/// dimmed, as PNG.
Future<Uint8List> paintClipLyrics(ClipLyricsLayout layout, int row) async {
  final recorder = ui.PictureRecorder();
  _drawLyrics(Canvas(recorder), layout, row);
  return _png(await _toImage(recorder));
}

/// The whole frame with [row] at the focus, as the video shows it, as PNG
/// at [scale] of its size.
Future<Uint8List> paintClipPreview(
  ClipScene scene,
  ClipLyricsLayout layout,
  int row, {
  double scale = 1,
}) async {
  const size = clipFrameSize;
  final area = Offset.zero & size;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..scale(scale)
    ..drawImage(
      await scene._image(),
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    )
    ..saveLayer(area, Paint());
  _drawLyrics(canvas, layout, row);
  const w = clipWindow;
  final clear = _colors.bg.withValues(alpha: 0);
  canvas
    ..drawRect(
      area,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [clear, clear, _colors.bg, _colors.bg, clear, clear],
          [0, w.top, w.top + w.fade, w.bottom - w.fade, w.bottom, 1],
        ),
    )
    ..restore();
  return _png(await _toImage(recorder, scale: scale));
}

Future<ui.Image> _toImage(
  ui.PictureRecorder recorder, {
  double scale = 1,
}) async {
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (clipFrameSize.width * scale).round(),
    (clipFrameSize.height * scale).round(),
  );
  picture.dispose();
  return image;
}

Future<Uint8List> _png(ui.Image image, {bool keep = false}) async {
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    if (!keep) image.dispose();
  }
}

/// The background's two tones: from the cover's main colour, else one of
/// [clipGradients] picked by the title.
Future<(Color, Color)> _tones(ClipScene scene) async {
  final cover = scene.cover;
  if (cover == null) {
    final hash = scene.title.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0xFFFF);
    return clipGradients[hash % clipGradients.length];
  }
  const n = 16;
  const side = 16.0;
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    cover,
    Offset.zero & Size(cover.width.toDouble(), cover.height.toDouble()),
    const Rect.fromLTWH(0, 0, side, side),
    Paint()..filterQuality = FilterQuality.medium,
  );
  final picture = recorder.endRecording();
  final small = await picture.toImage(n, n);
  picture.dispose();
  final data = await small.toByteData();
  small.dispose();
  var r = 0.0, g = 0.0, b = 0.0, total = 0.0;
  for (var i = 0; i + 3 < data!.lengthInBytes; i += 4) {
    final color = Color.fromARGB(
      255,
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
    final hsv = HSVColor.fromColor(color);
    final weight = 0.05 + hsv.saturation * hsv.value;
    r += color.r * weight;
    g += color.g * weight;
    b += color.b * weight;
    total += weight;
  }
  final main = HSLColor.fromColor(
    Color.from(alpha: 1, red: r / total, green: g / total, blue: b / total),
  );
  final saturation = main.saturation.clamp(0.25, 0.6);
  return (
    main.withSaturation(saturation).withLightness(0.3).toColor(),
    main.withSaturation(saturation).withLightness(0.1).toColor(),
  );
}

/// The parts that don't change: background, header and mark.
Future<ui.Image> _paintBackground(ClipScene scene, ui.Size size) async {
  final (light, dark) = await _tones(scene);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final area = Offset.zero & size;
  canvas
    ..drawRect(
      area,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width * 0.4, size.height),
          [light, dark],
        ),
    )
    ..drawRect(
      area,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.15, size.height * 0.1),
          size.width,
          [Color.lerp(light, _colors.text, 0.12)!, light.withValues(alpha: 0)],
        ),
    );
  _drawHeader(canvas, size, scene, light);
  if (scene.look.mark) _drawMark(canvas, size);
  return _toImage(recorder);
}

/// The middle of [cover] with the frame's [aspect].
Rect _coverCrop(ui.Image cover, double aspect) {
  final w = cover.width.toDouble();
  final h = cover.height.toDouble();
  if (w / h > aspect) {
    final width = h * aspect;
    return Rect.fromLTWH((w - width) / 2, 0, width, h);
  }
  final height = w / aspect;
  return Rect.fromLTWH(0, (h - height) / 2, w, height);
}

TextStyle _style(
  double size,
  FontWeight weight,
  Color color, {
  double height = 1.3,
  List<Shadow>? shadows,
}) => TextStyle(
  fontFamily: ZemaTypography.latinFamily,
  fontFamilyFallback: ZemaTypography.fallback,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  shadows: shadows,
);

TextPainter _text(
  String value,
  TextStyle style, {
  required double width,
  int? maxLines,
  TextAlign align = TextAlign.center,
}) => TextPainter(
  text: TextSpan(text: value, style: style),
  textAlign: align,
  textDirection: TextDirection.ltr,
  maxLines: maxLines,
  ellipsis: maxLines == null ? null : '…',
)..layout(maxWidth: width);

void _drawHeader(Canvas canvas, ui.Size size, ClipScene scene, Color tone) {
  final box = RRect.fromRectAndRadius(
    const Rect.fromLTWH(_side, _top, _coverSize, _coverSize),
    const Radius.circular(24),
  );
  final cover = scene.cover;
  if (cover != null) {
    canvas
      ..save()
      ..clipRRect(box)
      ..drawImageRect(
        cover,
        _coverCrop(cover, 1),
        box.outerRect,
        Paint()..filterQuality = FilterQuality.medium,
      )
      ..restore();
  } else {
    canvas.drawRRect(
      box,
      Paint()..color = Color.lerp(tone, _colors.text, 0.18)!,
    );
    final letter = scene.title.trim().isEmpty
        ? '•'
        : String.fromCharCode(scene.title.trim().runes.first);
    final painter = _text(
      letter,
      _style(64, FontWeight.w600, _colors.text, height: 1),
      width: _coverSize,
    );
    painter
      ..paint(
        canvas,
        Offset(
          _side + (_coverSize - painter.width) / 2,
          _top + (_coverSize - painter.height) / 2,
        ),
      )
      ..dispose();
  }
  const left = _side + _coverSize + 32;
  final width = size.width - left - _side;
  final title = _text(
    scene.title,
    _style(46, FontWeight.w600, _colors.text),
    width: width,
    maxLines: 2,
    align: TextAlign.left,
  );
  final artist = scene.artist == null || scene.artist!.trim().isEmpty
      ? null
      : _text(
          scene.artist!,
          _style(36, FontWeight.w400, _colors.text.withValues(alpha: 0.72)),
          width: width,
          maxLines: 1,
          align: TextAlign.left,
        );
  final height = title.height + (artist == null ? 0 : 8 + artist.height);
  var y = _top + (_coverSize - height) / 2;
  if (y < _top - 20) y = _top - 20;
  title.paint(canvas, Offset(left, y));
  artist?.paint(canvas, Offset(left, y + title.height + 8));
  title.dispose();
  artist?.dispose();
}

void _drawMark(Canvas canvas, ui.Size size) {
  final painter = _text(
    'ዜ Zema',
    _style(34, FontWeight.w600, _colors.text.withValues(alpha: 0.8)),
    width: 400,
  );
  painter
    ..paint(canvas, Offset(size.width - _side - painter.width, 90))
    ..dispose();
}

/// The largest size from 84 down to 60 at which [value] fits in 3 lines.
double _fittedSize(String value, double width) {
  for (var size = 84.0; size > 60; size -= 6) {
    final painter = _rowPainter(value, size, bright: true);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    if (lines <= 3) return size;
  }
  return 60;
}

TextPainter _rowPainter(String row, double size, {required bool bright}) {
  final base = row == _note ? _colors.primary : _colors.text;
  return _text(
    row,
    _style(
      size,
      row == _note ? FontWeight.w400 : FontWeight.w700,
      bright ? base : base.withValues(alpha: _dim),
      shadows: bright
          ? [Shadow(blurRadius: 24, color: _colors.bg.withValues(alpha: 0.35))]
          : null,
    ),
    width: clipFrameSize.width - 2 * _side,
    maxLines: row == _note ? null : 4,
  );
}

void _drawLyrics(Canvas canvas, ClipLyricsLayout layout, int row) {
  const size = clipFrameSize;
  final offset = size.height * _focus - layout.centers[row];
  for (var k = 0; k < layout.rows.length; k++) {
    final top = layout.centers[k] - layout.heights[k] / 2 + offset;
    if (top > size.height) break;
    if (top + layout.heights[k] < 0) continue;
    final painter = _rowPainter(
      layout.rows[k],
      layout.sizes[k],
      bright: k == row,
    );
    painter
      ..paint(canvas, Offset((size.width - painter.width) / 2, top))
      ..dispose();
  }
}
