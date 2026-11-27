import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../app/theme/clip_colors.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_typography.dart';
import '../data/clip_encoder.dart';
import 'clip_look_choices.dart';

export 'clip_look_choices.dart';

/// The size frames are painted at; the encoder scales them down if it must.
const clipFrameSize = ui.Size(1080, 1920);

/// Where the lyrics show; they fade out at its edges as they scroll.
const ClipWindow clipWindow = (top: 0.2, bottom: 0.97, fade: 0.1);

/// What every frame of one clip shares: the background, header and mark.
/// [title], [artist] and [album] are the names to show (edits applied);
/// [photo], [albumPicture] and [artistPicture] are the [look]'s pictures,
/// decoded.
class ClipScene {
  ClipScene({
    required this.title,
    this.artist,
    this.album,
    this.cover,
    this.photo,
    this.albumPicture,
    this.artistPicture,
    this.look = const ClipLook(),
  });

  final String title;
  final String? artist;
  final String? album;
  final ui.Image? cover;
  final ui.Image? photo;
  final ui.Image? albumPicture;
  final ui.Image? artistPicture;
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

const _gap = 56.0;
const _note = '•  •  •';
const _dim = 0.36;

/// Decodes picture bytes at most [width] wide, or null if they aren't a
/// picture.
Future<ui.Image?> decodeClipCover(Uint8List bytes, {int width = 720}) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  } on Exception {
    return null;
  }
}

/// The lyric rows of a clip laid out once, top to bottom, so every frame
/// draws them in the same places. An empty row shows a note.
/// [translits] go with [rows] and show below them when the [look] says so.
class ClipLyricsLayout {
  ClipLyricsLayout(
    List<String> rows, {
    List<String?> translits = const [],
    this.look = const ClipLook(),
  }) : rows = [for (final r in rows) r.trim().isEmpty ? _note : r.trim()],
       translits = [
         for (var i = 0; i < rows.length; i++)
           look.transliteration &&
                   i < translits.length &&
                   rows[i].trim().isNotEmpty &&
                   (translits[i]?.trim().isNotEmpty ?? false)
               ? translits[i]!.trim()
               : null,
       ] {
    for (final (i, row) in this.rows.indexed) {
      final size = row == _note
          ? 72.0 * look.textSize.scale
          : _fittedSize(this, i);
      final painter = _rowPainter(this, i, size, bright: true);
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
  final List<String?> translits;
  final ClipLook look;
  final sizes = <double>[];
  final heights = <double>[];
  final centers = <double>[];

  /// The row number for a still page: every row bright, the block centred.
  static const page = -1;

  /// How far row [to] sits below row [from], as a part of the frame height.
  double scroll(int from, int to) =>
      (centers[to] - centers[from]) / clipFrameSize.height;
}

/// A transparent layer with [row] bright at the focus and the rows around it
/// dimmed, or only [row] for [ClipLyricsStyle.line] (or, for
/// [ClipLyricsLayout.page], all rows bright), as PNG at [scale] of its size.
Future<Uint8List> paintClipLyrics(
  ClipLyricsLayout layout,
  int row, {
  double scale = 1,
}) async {
  final recorder = ui.PictureRecorder();
  _drawLyrics(Canvas(recorder)..scale(scale), layout, row);
  return _png(await _toImage(recorder, scale: scale));
}

/// The scene's background, header and mark as PNG at [scale] of its size.
Future<Uint8List> paintClipBackground(
  ClipScene scene, {
  double scale = 1,
}) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..scale(scale)
    ..drawImage(
      await scene._image(),
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );
  return _png(await _toImage(recorder, scale: scale));
}

/// How long one line takes to give way to the next.
Duration clipTransition(ClipMotion motion) => motion == ClipMotion.outIn
    ? const Duration(milliseconds: 600)
    : const Duration(milliseconds: 450);

/// One lyric layer's place in a change: its [alpha], how far it is moved up
/// as a part of the height, and its [scale] around the sung line.
typedef ClipLayerMove = ({double alpha, double shift, double scale});

/// The old and new layers' moves at [linear] (0 to 1) through a change by
/// [motion]; [scroll] is how far the new layer's content sits below the
/// old's. The encoder draws the same moves.
(ClipLayerMove, ClipLayerMove) clipMoves(
  ClipMotion motion,
  double linear, {
  double scroll = 0,
}) {
  double ease(double x) => x * x * (3 - 2 * x);
  const rise = 0.04;
  final m = ease(linear.clamp(0, 1));
  return switch (motion) {
    ClipMotion.scroll => (
      (alpha: 1 - m, shift: m * scroll, scale: 1),
      (alpha: m, shift: -(1 - m) * scroll, scale: 1),
    ),
    ClipMotion.fade => (
      (alpha: 1 - m, shift: 0, scale: 1),
      (alpha: m, shift: 0, scale: 1),
    ),
    ClipMotion.rise => (
      (alpha: 1 - m, shift: m * rise, scale: 1),
      (alpha: m, shift: -(1 - m) * rise, scale: 1),
    ),
    ClipMotion.zoom => (
      (alpha: 1 - m, shift: 0, scale: 1 + 0.12 * m),
      (alpha: m, shift: 0, scale: 0.85 + 0.15 * m),
    ),
    ClipMotion.outIn => () {
      final out = ease((2 * linear).clamp(0, 1));
      final back = ease((2 * linear - 1).clamp(0, 1));
      return (
        (alpha: 1 - out, shift: out * rise / 2, scale: 1.0),
        (alpha: back, shift: -(1 - back) * rise / 2, scale: 1.0),
      );
    }(),
  };
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
  final base = await _paintBase(scene, size);
  final dim = await _readableDim(base, scene.look);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawPicture(base);
  if (dim > 0) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _colors.shadow.withValues(alpha: dim),
    );
  }
  base.dispose();
  _drawHeader(canvas, size, scene);
  if (scene.look.mark) _drawMark(canvas, size);
  return _toImage(recorder);
}

/// The background fill alone, before dimming.
Future<ui.Picture> _paintBase(ClipScene scene, ui.Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final area = Offset.zero & size;
  final picture = switch (scene.look.background) {
    ClipBackground.photo => scene.photo ?? scene.cover,
    ClipBackground.cover => scene.cover,
    _ => null,
  };
  if (picture != null) {
    canvas
      ..drawRect(area, Paint()..color = _colors.bg)
      ..drawImageRect(
        picture,
        _coverCrop(picture, size.aspectRatio),
        scene.look.background == ClipBackground.cover
            ? area.inflate(120)
            : area,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..imageFilter = scene.look.background == ClipBackground.cover
              ? ui.ImageFilter.blur(
                  sigmaX: 48,
                  sigmaY: 48,
                  tileMode: TileMode.clamp,
                )
              : null,
      );
  } else if (scene.look.background == ClipBackground.color) {
    canvas.drawRect(area, Paint()..color = clipPlainColors[scene.look.color]);
  } else {
    final (light, dark) = await _tones(scene);
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
            [
              Color.lerp(light, _colors.text, 0.12)!,
              light.withValues(alpha: 0),
            ],
          ),
      );
  }
  return recorder.endRecording();
}

/// The look's dim, raised until its text colour has at least 4.5:1
/// contrast against the lyrics band's average.
Future<double> _readableDim(ui.Picture base, ClipLook look) async {
  const w = 27, h = 48;
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..scale(w / clipFrameSize.width, h / clipFrameSize.height)
    ..drawPicture(base);
  final picture = recorder.endRecording();
  final small = await picture.toImage(w, h);
  picture.dispose();
  final data = await small.toByteData();
  small.dispose();
  final from = (h * clipWindow.top).floor();
  final to = (h * clipWindow.bottom).ceil().clamp(0, h);
  final text = clipTextColors[look.textColor].computeLuminance();
  double linear(int c, double scale) {
    final v = c / 255 * scale;
    return v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  double luminance(double dim) {
    var sum = 0.0;
    var n = 0;
    for (var y = from; y < to; y++) {
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        sum +=
            0.2126 * linear(data!.getUint8(i), 1 - dim) +
            0.7152 * linear(data.getUint8(i + 1), 1 - dim) +
            0.0722 * linear(data.getUint8(i + 2), 1 - dim);
        n++;
      }
    }
    return n == 0 ? 0 : sum / n;
  }

  var dim = look.effectiveDim;
  while (dim < 0.9 && (text + 0.05) / (luminance(dim) + 0.05) < 4.5) {
    dim += 0.05;
  }
  return dim;
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

void _drawHeader(Canvas canvas, ui.Size size, ClipScene scene) {
  final look = scene.look;
  var left = _side;
  final album = scene.albumPicture ?? scene.cover;
  final names = [
    if (look.showTitle && scene.title.trim().isNotEmpty)
      (scene.title.trim(), _style(46, FontWeight.w600, _colors.text), 2),
    if (look.showArtist && (scene.artist?.trim().isNotEmpty ?? false))
      (
        scene.artist!.trim(),
        _style(36, FontWeight.w400, _colors.text.withValues(alpha: 0.75)),
        1,
      ),
    if (look.showAlbum && (scene.album?.trim().isNotEmpty ?? false))
      (
        scene.album!.trim(),
        _style(32, FontWeight.w400, _colors.text.withValues(alpha: 0.6)),
        1,
      ),
  ];
  if (album != null) {
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, _top, _coverSize, _coverSize),
      const Radius.circular(24),
    );
    _drawPicture(canvas, album, box);
    left += _coverSize + 24;
  } else if (names.isNotEmpty) {
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, _top, _coverSize, _coverSize),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      box,
      Paint()..color = _colors.text.withValues(alpha: 0.16),
    );
    final letter = String.fromCharCode(names.first.$1.runes.first);
    final painter = _text(
      letter,
      _style(64, FontWeight.w600, _colors.text, height: 1),
      width: _coverSize,
    );
    painter
      ..paint(
        canvas,
        Offset(
          left + (_coverSize - painter.width) / 2,
          _top + (_coverSize - painter.height) / 2,
        ),
      )
      ..dispose();
    left += _coverSize + 24;
  }
  final artist = scene.artistPicture;
  if (artist != null) {
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, _top, _coverSize, _coverSize),
      const Radius.circular(_coverSize / 2),
    );
    _drawPicture(canvas, artist, box);
    left += _coverSize + 24;
  }
  if (names.isEmpty) return;
  left += 8;
  final width = size.width - left - _side;
  if (width < 160) return;
  final painters = [
    for (final (value, style, lines) in names)
      _text(value, style, width: width, maxLines: lines, align: TextAlign.left),
  ];
  final height =
      painters.fold(0.0, (h, p) => h + p.height) + 6 * (painters.length - 1);
  var y = _top + (_coverSize - height) / 2;
  if (y < _top - 24) y = _top - 24;
  for (final painter in painters) {
    painter.paint(canvas, Offset(left, y));
    y += painter.height + 6;
    painter.dispose();
  }
}

void _drawPicture(Canvas canvas, ui.Image picture, RRect box) {
  canvas
    ..save()
    ..clipRRect(box)
    ..drawImageRect(
      picture,
      _coverCrop(picture, 1),
      box.outerRect,
      Paint()..filterQuality = FilterQuality.medium,
    )
    ..restore();
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

/// The largest size from 84 down to 60 (times the text size) at which row
/// [i] fits in 3 lines.
double _fittedSize(ClipLyricsLayout layout, int i) {
  final scale = layout.look.textSize.scale;
  final max = 3 + (layout.translits[i] == null ? 0 : 2);
  for (var size = 84.0 * scale; size > 60 * scale; size -= 6 * scale) {
    final painter = _rowPainter(layout, i, size, bright: true);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    if (lines <= max) return size;
  }
  return 60 * scale;
}

TextPainter _rowPainter(
  ClipLyricsLayout layout,
  int i,
  double size, {
  required bool bright,
}) {
  final row = layout.rows[i];
  final note = row == _note;
  final base = note ? _colors.primary : clipTextColors[layout.look.textColor];
  final color = bright ? base : base.withValues(alpha: _dim);
  final shadows = bright
      ? [Shadow(blurRadius: 24, color: _colors.bg.withValues(alpha: 0.35))]
      : null;
  final translit = layout.translits[i];
  return TextPainter(
    text: TextSpan(
      text: row,
      style: _style(
        size,
        note ? FontWeight.w400 : FontWeight.w700,
        color,
        shadows: shadows,
      ),
      children: [
        if (translit != null)
          TextSpan(
            text: '\n$translit',
            style: _style(
              size * 0.55,
              FontWeight.w500,
              color.withValues(alpha: color.a * 0.8),
              shadows: shadows,
            ),
          ),
      ],
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: note ? null : 6,
    ellipsis: note ? null : '…',
  )..layout(maxWidth: _lyricsWidth(layout.look.position));
}

/// How wide lyric rows wrap centred at [position]'s x: as wide as the
/// frame allows on both sides.
double _lyricsWidth(ClipTextPosition position) =>
    2 * clipFrameSize.width * math.min(position.x, 1 - position.x) - 2 * _side;

void _drawLyrics(Canvas canvas, ClipLyricsLayout layout, int row) {
  const size = clipFrameSize;
  if (layout.rows.isEmpty) return;
  final page = row == ClipLyricsLayout.page;
  final offset = page
      ? size.height * layout.look.position.focus -
            (layout.centers.last + layout.heights.last / 2) / 2
      : size.height * layout.look.position.focus - layout.centers[row];
  final alone = !page && layout.look.style == ClipLyricsStyle.line;
  for (var k = 0; k < layout.rows.length; k++) {
    if (alone && k != row) continue;
    final top = layout.centers[k] - layout.heights[k] / 2 + offset;
    if (top > size.height) break;
    if (top + layout.heights[k] < 0) continue;
    final painter = _rowPainter(
      layout,
      k,
      layout.sizes[k],
      bright: page || k == row,
    );
    painter
      ..paint(
        canvas,
        Offset(size.width * layout.look.position.x - painter.width / 2, top),
      )
      ..dispose();
  }
}
