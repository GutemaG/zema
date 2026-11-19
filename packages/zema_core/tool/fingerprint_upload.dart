import 'package:zema_core/zema_core.dart';

/// A recording to fingerprint: its catalog ID and the audio file on this
/// computer.
typedef UploadJob = ({String recordingId, String path});

final _slug = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// Reads `recording-id=path/to/file.mp3` arguments. Throws [FormatException]
/// naming the first bad one.
List<UploadJob> parseUploadJobs(List<String> args) => [
  for (final arg in args)
    switch (arg.indexOf('=')) {
      final i
          when i > 0 &&
              _slug.hasMatch(arg.substring(0, i)) &&
              i < arg.length - 1 =>
        (recordingId: arg.substring(0, i), path: arg.substring(i + 1)),
      _ => throw FormatException('Expected recording-id=file, got "$arg"'),
    },
];

/// The body of `put_fingerprint` for [recordingId]: hashes only, no audio.
Map<String, Object> putFingerprintBody(
  String recordingId,
  AudioFingerprint fingerprint,
) => {
  'target': recordingId,
  'version': fingerprintVersion,
  'frame_count': fingerprint.frameCount,
  'hashes': fingerprint.hashes.toList(),
  'frames': fingerprint.frames.toList(),
};

/// The body of `put_track_print` for [songId]: the print only, no audio.
Map<String, Object> putTrackPrintBody(String songId, TrackPrint print) => {
  'song': songId,
  'version': trackPrintVersion,
  'print': printValuesSigned(print),
  'duration_ms': print.duration.inMilliseconds,
};
