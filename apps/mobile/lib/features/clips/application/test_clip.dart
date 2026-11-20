import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../lyrics/application/track_lyrics.dart';
import '../data/clip_encoder.dart';
import 'clip_timeline.dart';

final clipEncoderProvider = Provider<ClipEncoder>(
  (ref) => Platform.isAndroid
      ? AndroidClipEncoder()
      : const UnsupportedClipEncoder(),
);

/// The size frames are painted at; the encoder scales them down if it must.
const clipFrameSize = ui.Size(1080, 1920);

/// A 60 s test clip of [track] from its first sung line, saved to the
/// gallery, to time the encoder on a real phone (bolt 065). Plain frames;
/// the real look comes with the clip editor.
Future<({EncodedClip clip, bool saved})> makeTestClip(
  ProviderContainer ref,
  Track track, {
  void Function(double)? onProgress,
}) async {
  final lyrics = await ref.read(trackLyricsProvider(track.id).future);
  final engine = lyrics?.synced?.engine;
  final timed =
      lyrics != null &&
      engine != null &&
      engine.lineCount == lyrics.lines.length;
  final shift = timed ? ref.read(lyricsShiftProvider(lyrics)) : Duration.zero;
  final texts = timed
      ? [for (final sung in lyrics.lines) sung.line.text]
      : const <String>[];
  final starts = timed
      ? [for (var i = 0; i < engine.lineCount; i++) engine.startOf(i) + shift]
      : const <Duration>[];
  var start = starts.isEmpty
      ? Duration.zero
      : starts.first - const Duration(seconds: 1);
  if (start < Duration.zero) start = Duration.zero;
  var end = start + const Duration(seconds: 60);
  if (end > track.duration && track.duration > Duration.zero) {
    end = track.duration;
  }

  final folder = Directory(
    p.join(
      (await getTemporaryDirectory()).path,
      'clips',
      '${DateTime.now().millisecondsSinceEpoch}',
    ),
  )..createSync(recursive: true);
  try {
    final times = clipFrameTimes(starts, start, end);
    final frames = <ClipFrame>[];
    for (final (i, t) in times.indexed) {
      final line = t.line;
      final next = line == null ? 0 : line + 1;
      final png = await _paint(
        title: track.title,
        artist: track.artist,
        current: line == null ? '' : texts[line],
        next: next < texts.length ? texts[next] : '',
      );
      final file = File(p.join(folder.path, 'frame-$i.png'));
      await file.writeAsBytes(png);
      frames.add(ClipFrame(file.path, t.at));
    }
    final out = p.join(folder.path, 'clip.mp4');
    final job = ref
        .read(clipEncoderProvider)
        .encode(
          ClipRequest(
            audioUri: track.uri,
            start: start,
            end: end,
            frames: frames,
            outPath: out,
          ),
        );
    final listening = job.progress.listen(onProgress);
    try {
      final clip = await job.result;
      final saved = await ref
          .read(clipEncoderProvider)
          .saveToGallery(
            clip.path,
            name: 'Zema test ${DateTime.now().millisecondsSinceEpoch}.mp4',
          );
      return (clip: clip, saved: saved);
    } finally {
      await listening.cancel();
    }
  } finally {
    folder.deleteSync(recursive: true);
  }
}

Future<List<int>> _paint({
  required String title,
  required String? artist,
  required String current,
  required String next,
}) async {
  const colors = ZemaColors.nightVigil;
  const size = clipFrameSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(Offset.zero & size, Paint()..color = colors.bg);

  void text(String value, double y, double fontSize, Color color) {
    if (value.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color, fontSize: fontSize, height: 1.3),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 160);
    painter.paint(canvas, Offset((size.width - painter.width) / 2, y));
    painter.dispose();
  }

  text(title, 180, 52, colors.text);
  text(artist ?? '', 260, 40, colors.muted);
  text(current, 820, 76, colors.primaryText);
  text(next, 1120, 56, colors.faint);
  text('Zema', size.height - 160, 36, colors.primary);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  picture.dispose();
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
