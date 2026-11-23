import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('clips.encoder');

/// A lyric layer (a transparent picture) shown in the clip from [at] (from
/// the clip's start) until the next frame's time. [scroll] is how far its
/// content sits above the previous frame's, as a part of the height: the old
/// layer scrolls up by it while this one slides in.
class ClipFrame {
  const ClipFrame(this.path, this.at, {this.scroll = 0});

  final String path;
  final Duration at;
  final double scroll;
}

/// How a new frame replaces the old one.
enum ClipMotion {
  /// The old frame scrolls up by the new one's [ClipFrame.scroll] as the new
  /// one slides in.
  scroll,

  /// A cross fade.
  fade,

  /// The old frame rises out as the new one rises in from a little below.
  rise,

  /// The old frame grows away as the new one grows in.
  zoom,

  /// The old frame fades out, then the new one fades in.
  outIn,
}

/// The band of the frame, as parts of its height, where lyrics show; they
/// fade out over [fade] at both edges.
typedef ClipWindow = ({double top, double bottom, double fade});

/// What to make: [audioUri] from [start] to [end] (none: a silent clip), with
/// [frames] in time order, the first at zero, drawn over [background],
/// written to [outPath]. Each frame comes in by [motion] over [transition],
/// centred on its time; [center] is the sung line's height, as a part of the
/// frame's, that [ClipMotion.zoom] grows around.
class ClipRequest {
  ClipRequest({
    required this.audioUri,
    required this.start,
    required this.end,
    required this.background,
    required this.frames,
    required this.outPath,
    this.window = (top: 0, bottom: 1, fade: 0),
    this.motion = ClipMotion.scroll,
    this.center = 0.5,
    this.fps = 30,
    this.transition = const Duration(milliseconds: 450),
  }) {
    if (end <= start) {
      throw ArgumentError.value(end, 'end', 'is not after start');
    }
    if (end - start > maxClipLength) {
      throw ArgumentError.value(end, 'end', 'is more than $maxClipLength in');
    }
    if (frames.isEmpty || frames.first.at != Duration.zero) {
      throw ArgumentError.value(frames, 'frames', 'must start at zero');
    }
    for (var i = 1; i < frames.length; i++) {
      if (frames[i].at < frames[i - 1].at) {
        throw ArgumentError.value(frames, 'frames', 'are not in time order');
      }
    }
  }

  final String? audioUri;
  final Duration start;
  final Duration end;
  final String background;
  final List<ClipFrame> frames;
  final ClipWindow window;
  final ClipMotion motion;
  final double center;
  final String outPath;
  final int fps;
  final Duration transition;

  Duration get length => end - start;
}

/// The longest clip that can be made.
const maxClipLength = Duration(minutes: 2);

class EncodedClip {
  const EncodedClip({
    required this.path,
    required this.width,
    required this.height,
    required this.took,
    required this.codec,
  });

  final String path;
  final int width;
  final int height;
  final Duration took;
  final String codec;
}

/// The encode was cancelled; its file is gone.
class ClipCancelled implements Exception {
  const ClipCancelled();
}

class ClipFailed implements Exception {
  const ClipFailed(this.message);

  final String message;

  @override
  String toString() => 'ClipFailed: $message';
}

/// One encode: its progress from 0 to 1, and the clip or a [ClipCancelled]
/// or [ClipFailed] error.
class ClipJob {
  ClipJob({required this.progress, required this.result, required this.cancel});

  final Stream<double> progress;
  final Future<EncodedClip> result;

  /// Stops the encode; [result] then fails with [ClipCancelled].
  final Future<void> Function() cancel;
}

/// Makes lyrics clip videos on the phone.
abstract interface class ClipEncoder {
  /// False where clips can't be made; Share clip is hidden then.
  bool get isSupported;

  ClipJob encode(ClipRequest request);

  /// Copies the clip at [path] to the gallery as [name]. Returns false if it
  /// couldn't.
  Future<bool> saveToGallery(String path, {required String name});

  /// Opens the share menu with the clip at [path] and [text]. Returns false
  /// if it couldn't.
  Future<bool> share(String path, {required String text});
}

/// Android: MediaCodec and MediaMuxer through `zema/clip`, no FFmpeg.
class AndroidClipEncoder implements ClipEncoder {
  AndroidClipEncoder([this._channel = const MethodChannel('zema/clip')]) {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  final _progress = <String, StreamController<double>>{};
  var _next = 0;

  Future<void> _onCall(MethodCall call) async {
    if (call.method != 'progress') return;
    final args = call.arguments as Map<Object?, Object?>;
    final fraction = (args['fraction'] as num?)?.toDouble();
    if (fraction != null) _progress[args['id']]?.add(fraction);
  }

  @override
  bool get isSupported => true;

  @override
  ClipJob encode(ClipRequest request) {
    final id = 'clip-${DateTime.now().microsecondsSinceEpoch}-${_next++}';
    final progress = StreamController<double>.broadcast();
    _progress[id] = progress;
    Future<EncodedClip> run() async {
      try {
        final made = await _channel.invokeMapMethod<String, Object?>('encode', {
          'id': id,
          'audioUri': request.audioUri,
          'startMs': request.start.inMilliseconds,
          'endMs': request.end.inMilliseconds,
          'background': request.background,
          'frames': [
            for (final f in request.frames)
              {'path': f.path, 'atMs': f.at.inMilliseconds, 'scroll': f.scroll},
          ],
          'window': {
            'top': request.window.top,
            'bottom': request.window.bottom,
            'fade': request.window.fade,
          },
          'motion': request.motion.name,
          'center': request.center,
          'outPath': request.outPath,
          'fps': request.fps,
          'transitionMs': request.transition.inMilliseconds,
        });
        if (made == null) throw const ClipFailed('No result');
        progress.add(1);
        return EncodedClip(
          path: made['path']! as String,
          width: made['width']! as int,
          height: made['height']! as int,
          took: Duration(milliseconds: made['millis']! as int),
          codec: made['codec']! as String,
        );
      } on PlatformException catch (e) {
        if (e.code == 'cancelled') throw const ClipCancelled();
        _log.warning('Could not make a clip: ${e.code}', e);
        throw ClipFailed(e.message ?? e.code);
      } finally {
        _progress.remove(id);
        unawaited(progress.close());
      }
    }

    return ClipJob(
      progress: progress.stream,
      result: run(),
      cancel: () => _channel.invokeMethod<void>('cancel', {'id': id}),
    );
  }

  @override
  Future<bool> saveToGallery(String path, {required String name}) async {
    try {
      await _channel.invokeMethod<String>('saveToGallery', {
        'path': path,
        'name': name,
      });
      return true;
    } on PlatformException catch (e) {
      _log.warning('Could not save a clip: ${e.code}', e);
      return false;
    }
  }

  @override
  Future<bool> share(String path, {required String text}) async {
    try {
      await _channel.invokeMethod<void>('share', {'path': path, 'text': text});
      return true;
    } on PlatformException catch (e) {
      _log.warning('Could not share a clip: ${e.code}', e);
      return false;
    }
  }
}

class UnsupportedClipEncoder implements ClipEncoder {
  const UnsupportedClipEncoder();

  @override
  bool get isSupported => false;

  @override
  ClipJob encode(ClipRequest request) => ClipJob(
    progress: const Stream.empty(),
    result: Future.error(const ClipFailed('Clips need Android')),
    cancel: () async {},
  );

  @override
  Future<bool> saveToGallery(String path, {required String name}) async =>
      false;

  @override
  Future<bool> share(String path, {required String text}) async => false;
}
