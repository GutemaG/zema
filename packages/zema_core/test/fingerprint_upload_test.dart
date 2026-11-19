import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

import '../tool/fingerprint_upload.dart';

void main() {
  test('jobs are recording-id=file', () {
    expect(parseUploadJobs(['selam-lezih-bet=/m/a=b.mp3']), [
      (recordingId: 'selam-lezih-bet', path: '/m/a=b.mp3'),
    ]);
    expect(() => parseUploadJobs(['/m/a.mp3']), throwsFormatException);
    expect(() => parseUploadJobs(['Selam=/m/a.mp3']), throwsFormatException);
    expect(() => parseUploadJobs(['selam=']), throwsFormatException);
  });

  test('the upload holds hashes, frames and the version, not audio', () {
    final body = putFingerprintBody(
      'selam',
      AudioFingerprint(
        hashes: Uint32List.fromList([7, 9]),
        frames: Uint32List.fromList([0, 4]),
        frameCount: 10,
      ),
    );
    expect(body, {
      'target': 'selam',
      'version': fingerprintVersion,
      'frame_count': 10,
      'hashes': [7, 9],
      'frames': [0, 4],
    });
  });

  test(
    'a track print upload holds the signed values and length, not audio',
    () {
      final body = putTrackPrintBody(
        'selam',
        TrackPrint(
          values: Uint32List.fromList([1, 0xffffffff]),
          duration: const Duration(seconds: 200),
        ),
      );
      expect(body, {
        'song': 'selam',
        'version': trackPrintVersion,
        'print': [1, -1],
        'duration_ms': 200000,
      });
    },
  );
}
