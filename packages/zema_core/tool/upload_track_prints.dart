import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:zema_core/zema_core.dart';

import 'fingerprint_upload.dart';

/// Makes track prints of catalog songs from audio files on this computer and
/// publishes only the prints (intent 013). Needs ffmpeg on the PATH.
///
/// Run from packages/zema_core:
/// `SUPABASE_SERVICE_ROLE_KEY=... dart run tool/upload_track_prints.dart
/// selam-lezih-bet=~/Music/selam.mp3 ...`
///
/// SUPABASE_URL defaults to the local backend. Audio is decoded in memory and
/// never written or sent anywhere.
Future<void> main(List<String> args) async {
  final List<UploadJob> jobs;
  try {
    jobs = parseUploadJobs(args);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exitCode = 64;
    return;
  }
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (jobs.isEmpty || key == null || key.isEmpty) {
    stderr.writeln(
      'Usage: SUPABASE_SERVICE_ROLE_KEY=... dart run '
      'tool/upload_track_prints.dart song-id=file ...',
    );
    exitCode = 64;
    return;
  }
  final base = Uri.parse(
    Platform.environment['SUPABASE_URL'] ?? 'http://127.0.0.1:54321',
  );
  final endpoint = base.resolve('/rest/v1/rpc/put_track_print');
  final client = HttpClient();
  const printer = TrackPrinter();
  try {
    for (final job in jobs) {
      final pcm = await _decode(job.path);
      final print = printer.print(pcm);
      final request = await client.postUrl(endpoint);
      request.headers
        ..contentType = ContentType.json
        ..set('apikey', key)
        ..set('Authorization', 'Bearer $key');
      request.write(jsonEncode(putTrackPrintBody(job.recordingId, print)));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 300) {
        stderr.writeln('${job.recordingId}: ${response.statusCode} $body');
        exitCode = 1;
      } else {
        stdout.writeln(
          '${job.recordingId}: $body, ${print.values.length} values, '
          '${print.duration.inSeconds} s',
        );
      }
    }
  } finally {
    client.close();
  }
}

Future<Float32List> _decode(String path) async {
  final result = await Process.run('ffmpeg', [
    '-v',
    'error',
    '-i',
    path,
    '-vn',
    '-ac',
    '1',
    '-ar',
    '$fingerprintSampleRate',
    '-f',
    's16le',
    'pipe:1',
  ], stdoutEncoding: null);
  if (result.exitCode != 0) {
    throw StateError('ffmpeg failed on $path: ${result.stderr}');
  }
  final bytes = Uint8List.fromList(result.stdout as List<int>);
  final samples = bytes.buffer.asInt16List(0, bytes.length ~/ 2);
  return Float32List.fromList([for (final s in samples) s / 32768]);
}
