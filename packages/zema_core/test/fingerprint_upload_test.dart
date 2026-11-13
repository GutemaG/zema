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
}
