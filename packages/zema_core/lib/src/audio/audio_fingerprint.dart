import 'dart:typed_data';

import '../failures.dart';

/// Version of the fingerprint method. Fingerprints of different versions are
/// never compared: a change to any constant below or to the fingerprinter
/// bumps it, and the catalog is fingerprinted again.
const int fingerprintVersion = 1;

/// The fingerprinter works on mono audio at this rate; see [resampleMono].
const int fingerprintSampleRate = 11025;

/// Samples between two spectrogram frames (about 23 ms).
const int fingerprintHop = 256;

/// Start of spectrogram [frame] in the audio.
Duration fingerprintFrameTime(int frame) => Duration(
  microseconds: (frame * fingerprintHop * 1e6 / fingerprintSampleRate).round(),
);

/// Hashes of pairs of spectral peaks, each with the frame of its first peak.
///
/// A hash describes two peaks (both frequencies and the time between them),
/// not where they are, so the same moment of a song gives the same hash
/// wherever an excerpt starts. Matching lines the frames up afterwards.
/// Holds no audio and can't be turned back into sound.
class AudioFingerprint {
  /// [hashes] and [frames] are parallel; [frames] must not go backwards.
  AudioFingerprint({
    required this.hashes,
    required this.frames,
    required this.frameCount,
    this.speed = 1,
  }) {
    if (hashes.length != frames.length) {
      throw ArgumentError('hashes and frames differ in length');
    }
  }

  /// 24-bit hashes: first peak's bin (9 bits), second peak's bin (9 bits),
  /// frames between them (6 bits).
  final Uint32List hashes;

  /// Frame of each hash's first peak.
  final Uint32List frames;

  /// Length of the audio fingerprinted, in frames.
  final int frameCount;

  /// The speed the audio was played at before fingerprinting: 1 for the
  /// audio as it came, 0.98 when it was slowed by 2% to undo a sped-up copy.
  /// Only queries use it; it isn't stored.
  final double speed;

  int get length => hashes.length;

  Duration get duration => fingerprintFrameTime(frameCount);

  /// Compact form for storage and upload: about 4 bytes per hash.
  ///
  /// Version byte, then varints for the frame count and the hash count, then
  /// per hash the frame as a varint delta from the previous one and the hash
  /// in 3 bytes.
  Uint8List toBytes() {
    final out = BytesBuilder(copy: false)..addByte(fingerprintVersion);
    _varint(out, frameCount);
    _varint(out, length);
    var previous = 0;
    for (var i = 0; i < length; i++) {
      _varint(out, frames[i] - previous);
      previous = frames[i];
      final h = hashes[i];
      out
        ..addByte(h >> 16 & 0xff)
        ..addByte(h >> 8 & 0xff)
        ..addByte(h & 0xff);
    }
    return out.takeBytes();
  }

  /// Reads [toBytes]. Throws [FingerprintFormatFailure] for another version
  /// or damaged bytes.
  factory AudioFingerprint.fromBytes(Uint8List bytes) {
    final reader = _Reader(bytes);
    final version = reader.byte();
    if (version != fingerprintVersion) {
      throw FingerprintFormatFailure(
        'Fingerprint version $version; expected $fingerprintVersion',
      );
    }
    final frameCount = reader.varint();
    final count = reader.varint();
    // Each hash takes at least 4 bytes, so a damaged count can't ask for more
    // memory than the phone has.
    if (count > reader.remaining ~/ 4) {
      throw const FingerprintFormatFailure('Fingerprint ends early');
    }
    final hashes = Uint32List(count);
    final frames = Uint32List(count);
    var frame = 0;
    for (var i = 0; i < count; i++) {
      frame += reader.varint();
      frames[i] = frame;
      hashes[i] = reader.byte() << 16 | reader.byte() << 8 | reader.byte();
    }
    if (!reader.done) {
      throw const FingerprintFormatFailure('Bytes left after the last hash');
    }
    return AudioFingerprint(
      hashes: hashes,
      frames: frames,
      frameCount: frameCount,
    );
  }

  static void _varint(BytesBuilder out, int value) {
    var v = value;
    while (v >= 0x80) {
      out.addByte(v & 0x7f | 0x80);
      v >>= 7;
    }
    out.addByte(v);
  }
}

class _Reader {
  _Reader(this._bytes);

  final Uint8List _bytes;
  var _at = 0;

  bool get done => _at == _bytes.length;

  int get remaining => _bytes.length - _at;

  int byte() {
    if (_at >= _bytes.length) {
      throw const FingerprintFormatFailure('Fingerprint ends early');
    }
    return _bytes[_at++];
  }

  int varint() {
    var value = 0;
    for (var shift = 0; shift < 35; shift += 7) {
      final b = byte();
      value |= (b & 0x7f) << shift;
      if (b < 0x80) return value;
    }
    throw const FingerprintFormatFailure('Varint too long');
  }
}

/// [pcm] (mono, at [fromRate]) at [fingerprintSampleRate].
///
/// Going down, each output sample averages the input samples it covers, which
/// keeps most sound above the new limit from folding back into the range the
/// fingerprint uses. Going up, it interpolates.
Float32List resampleMono(Float32List pcm, int fromRate) {
  if (fromRate == fingerprintSampleRate) return pcm;
  final ratio = fromRate / fingerprintSampleRate;
  final out = Float32List((pcm.length / ratio).floor());
  if (ratio < 1) {
    for (var i = 0; i < out.length; i++) {
      final p = i * ratio;
      final k = p.floor();
      final f = p - k;
      final next = k + 1 < pcm.length ? pcm[k + 1] : pcm[k];
      out[i] = pcm[k] * (1 - f) + next * f;
    }
    return out;
  }
  for (var i = 0; i < out.length; i++) {
    final from = (i * ratio).floor();
    final to = ((i + 1) * ratio).floor().clamp(from + 1, pcm.length);
    var sum = 0.0;
    for (var k = from; k < to; k++) {
      sum += pcm[k];
    }
    out[i] = sum / (to - from);
  }
  return out;
}

/// Mono from interleaved samples of [channels] channels, by averaging.
Float32List mixToMono(Float32List interleaved, int channels) {
  if (channels == 1) return interleaved;
  final out = Float32List(interleaved.length ~/ channels);
  for (var i = 0; i < out.length; i++) {
    var sum = 0.0;
    for (var c = 0; c < channels; c++) {
      sum += interleaved[i * channels + c];
    }
    out[i] = sum / channels;
  }
  return out;
}
