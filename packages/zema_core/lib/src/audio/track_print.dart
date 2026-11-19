import 'dart:math' as math;
import 'dart:typed_data';

import '../failures.dart';
import 'audio_fingerprint.dart';

/// Version of the track print method. Prints of different versions are
/// never compared; a change to any constant below bumps it.
const int trackPrintVersion = 1;

/// The audio a print covers: the start of the file.
const Duration trackPrintLength = Duration(seconds: 110);

/// Samples (at [trackPrintSampleRate]) between two print values.
const int trackPrintHop = 256;

/// The rate the printer works at: half of [fingerprintSampleRate].
const double trackPrintSampleRate = fingerprintSampleRate / 2;

/// How far two prints are shifted against each other when compared.
const Duration trackPrintMaxShift = Duration(seconds: 2);

/// The least audio two prints must share to be compared.
const Duration trackPrintMinOverlap = Duration(seconds: 30);

/// The time between two print values at [hop].
Duration trackPrintFrame([int hop = trackPrintHop]) =>
    Duration(microseconds: (hop * 1e6 / trackPrintSampleRate).round());

/// A small print of the start of a whole file, to find other copies of the
/// same recording (re-encoded, at another bitrate, trimmed a little).
///
/// One 32-bit value per frame: bit m says whether the energy difference
/// between bands m and m+1 grew since the frame before (Haitsma and
/// Kalker's method, as in Chromaprint's family). Holds no audio.
class TrackPrint {
  TrackPrint({required this.values, required this.duration});

  final Uint32List values;

  /// The whole file's length, not just the printed part.
  final Duration duration;

  /// Version byte, duration in milliseconds and value count as varints,
  /// then each value in 4 bytes, little-endian: about 9.5 KB.
  Uint8List toBytes() {
    final out = BytesBuilder(copy: false)..addByte(trackPrintVersion);
    _varint(out, duration.inMilliseconds);
    _varint(out, values.length);
    final data = ByteData(values.length * 4);
    for (var i = 0; i < values.length; i++) {
      data.setUint32(i * 4, values[i], Endian.little);
    }
    out.add(data.buffer.asUint8List());
    return out.takeBytes();
  }

  /// Reads [toBytes]. Throws [FingerprintFormatFailure] for another version
  /// or damaged bytes.
  factory TrackPrint.fromBytes(Uint8List bytes) {
    var at = 0;
    int byte() {
      if (at >= bytes.length) {
        throw const FingerprintFormatFailure('Track print ends early');
      }
      return bytes[at++];
    }

    int varint() {
      var value = 0;
      for (var shift = 0; shift < 35; shift += 7) {
        final b = byte();
        value |= (b & 0x7f) << shift;
        if (b < 0x80) return value;
      }
      throw const FingerprintFormatFailure('Track print number too long');
    }

    final version = byte();
    if (version != trackPrintVersion) {
      throw FingerprintFormatFailure(
        'Track print version $version; expected $trackPrintVersion',
      );
    }
    final ms = varint();
    final count = varint();
    if (bytes.length - at != count * 4) {
      throw const FingerprintFormatFailure('Track print has the wrong size');
    }
    final data = ByteData.sublistView(bytes, at);
    return TrackPrint(
      values: Uint32List.fromList([
        for (var i = 0; i < count; i++) data.getUint32(i * 4, Endian.little),
      ]),
      duration: Duration(milliseconds: ms),
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

/// Turns audio into a [TrackPrint].
///
/// 1. Low-pass and halve the audio to [trackPrintSampleRate]; keep the
///    first [trackPrintLength].
/// 2. 2,048-sample Hann windows every [hop] samples; energy in 33 bands
///    spaced evenly in pitch from 300 to 2,000 Hz.
/// 3. One value per frame after the first, from the band differences.
class TrackPrinter {
  /// Only [trackPrintHop] makes prints that can be stored or shared; other
  /// [hop]s are for trying settings out.
  const TrackPrinter({this.hop = trackPrintHop});

  final int hop;

  static const _size = 2048;
  static const _bands = 33;
  static const _lowHz = 300.0;
  static const _highHz = 2000.0;

  /// Print of [pcm]: mono samples in -1…1 at [fingerprintSampleRate].
  /// [duration] is the whole file's, when [pcm] holds only its start.
  TrackPrint print(Float32List pcm, {Duration? duration}) {
    final audio = _halve(pcm);
    final frames = audio.length < _size ? 0 : (audio.length - _size) ~/ hop + 1;
    final values = Uint32List(math.max(0, frames - 1));
    final re = Float64List(_size);
    final im = Float64List(_size);
    final energy = Float64List(frames * _bands);
    // Two frames per FFT: frame f as the real part, f + 1 as the imaginary
    // part. Both are real, so their spectra separate again from the
    // result's symmetric halves.
    for (var f = 0; f < frames; f += 2) {
      final second = f + 1 < frames;
      final start = f * hop;
      for (var i = 0; i < _size; i++) {
        re[i] = audio[start + i] * _window[i];
        im[i] = second ? audio[start + hop + i] * _window[i] : 0;
      }
      _fft(re, im);
      for (var b = 0; b < _bands; b++) {
        var ea = 0.0, eb = 0.0;
        for (var k = _edges[b]; k < _edges[b + 1]; k++) {
          final m = _size - k;
          final sumRe = re[k] + re[m], diffRe = re[k] - re[m];
          final sumIm = im[k] + im[m], diffIm = im[k] - im[m];
          ea += sumRe * sumRe + diffIm * diffIm;
          eb += sumIm * sumIm + diffRe * diffRe;
        }
        energy[f * _bands + b] = ea;
        if (second) energy[(f + 1) * _bands + b] = eb;
      }
    }
    for (var f = 1; f < frames; f++) {
      final now = f * _bands, before = now - _bands;
      var bits = 0;
      for (var m = 0; m < 32; m++) {
        final d =
            energy[now + m] -
            energy[now + m + 1] -
            (energy[before + m] - energy[before + m + 1]);
        if (d > 0) bits |= 1 << m;
      }
      values[f - 1] = bits;
    }
    return TrackPrint(
      values: values,
      duration:
          duration ??
          Duration(
            microseconds: (pcm.length * 1e6 / fingerprintSampleRate).round(),
          ),
    );
  }

  /// Taps of a 31-tap windowed-sinc low-pass at a quarter of the input rate,
  /// so nothing above the new Nyquist folds back into the bands.
  static final Float64List _taps = () {
    const n = 31;
    final taps = Float64List(n);
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      final x = i - (n - 1) / 2;
      final sinc = x == 0 ? 1.0 : math.sin(math.pi * x / 2) / (math.pi * x / 2);
      final hann = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
      sum += taps[i] = sinc * hann;
    }
    for (var i = 0; i < n; i++) {
      taps[i] /= sum;
    }
    return taps;
  }();

  static Float32List _halve(Float32List pcm) {
    final limit = math.min(
      pcm.length,
      (trackPrintLength.inSeconds * fingerprintSampleRate).round(),
    );
    final out = Float32List(limit ~/ 2);
    const half = 15;
    for (var j = 0; j < out.length; j++) {
      final c = 2 * j;
      var s = 0.0;
      for (var t = 0; t < _taps.length; t++) {
        final i = c + t - half;
        if (i >= 0 && i < limit) s += pcm[i] * _taps[t];
      }
      out[j] = s;
    }
    return out;
  }

  /// FFT bins where each band starts; band b is [_edges] b … b + 1.
  static final List<int> _edges = [
    for (var b = 0; b <= _bands; b++)
      (_lowHz *
              math.pow(_highHz / _lowHz, b / _bands) *
              _size /
              trackPrintSampleRate)
          .round(),
  ];

  static final Float64List _window = Float64List.fromList([
    for (var i = 0; i < _size; i++)
      0.5 - 0.5 * math.cos(2 * math.pi * i / (_size - 1)),
  ]);
  static final Float64List _cos = Float64List.fromList([
    for (var i = 0; i < _size ~/ 2; i++) math.cos(2 * math.pi * i / _size),
  ]);
  static final Float64List _sin = Float64List.fromList([
    for (var i = 0; i < _size ~/ 2; i++) math.sin(2 * math.pi * i / _size),
  ]);
  static final Int32List _reversed = Int32List.fromList([
    for (var i = 0; i < _size; i++) _reverseBits(i),
  ]);

  static int _reverseBits(int i) {
    var r = 0;
    for (var b = 0, v = i; b < 11; b++, v >>= 1) {
      r = r << 1 | v & 1;
    }
    return r;
  }

  /// In-place radix-2 FFT of [_size] points.
  static void _fft(Float64List re, Float64List im) {
    for (var i = 0; i < _size; i++) {
      final j = _reversed[i];
      if (j > i) {
        var t = re[i];
        re[i] = re[j];
        re[j] = t;
        t = im[i];
        im[i] = im[j];
        im[j] = t;
      }
    }
    for (var span = 2; span <= _size; span <<= 1) {
      final half = span >> 1;
      final step = _size ~/ span;
      for (var start = 0; start < _size; start += span) {
        for (var k = 0; k < half; k++) {
          final wr = _cos[k * step];
          final wi = -_sin[k * step];
          final a = start + k;
          final b = a + half;
          final xr = re[b] * wr - im[b] * wi;
          final xi = re[b] * wi + im[b] * wr;
          re[b] = re[a] - xr;
          im[b] = im[a] - xi;
          re[a] += xr;
          im[a] += xi;
        }
      }
    }
  }
}

/// How far apart two prints are: the share of differing bits (0 the same,
/// about 0.5 unrelated) at the [shift] where they line up best, in values
/// of [b] after [a]. Null when they can't overlap by [trackPrintMinOverlap]
/// within [trackPrintMaxShift].
typedef PrintDistance = ({double bits, int shift});

/// [PrintDistance] of [a] and [b], made at [hop].
PrintDistance? printDistance(
  TrackPrint a,
  TrackPrint b, {
  int hop = trackPrintHop,
}) {
  final frame = trackPrintFrame(hop).inMicroseconds;
  final reach = (trackPrintMaxShift.inMicroseconds / frame).ceil();
  final minimum = (trackPrintMinOverlap.inMicroseconds / frame).ceil();
  final x = a.values, y = b.values;
  PrintDistance? best;
  for (var shift = -reach; shift <= reach; shift++) {
    final from = math.max(0, -shift);
    final to = math.min(x.length, y.length - shift);
    if (to - from < minimum) continue;
    var diff = 0;
    for (var i = from; i < to; i++) {
      final v = x[i] ^ y[i + shift];
      diff += _ones[v & 0xffff] + _ones[v >> 16];
    }
    final bits = diff / (32 * (to - from));
    if (best == null || bits < best.bits) best = (bits: bits, shift: shift);
  }
  return best;
}

/// Prints at most this far apart ([PrintDistance.bits]) are the same
/// recording. On the owner's 98 files (bolt 059) copies were at most 17.5 %
/// apart (re-encodes, starts cut by up to 2 s) and different files at least
/// 48.6 %.
const double trackPrintMatch = 0.30;

/// Number of bits a print key keeps: the top ones of a value.
const int trackPrintKeyBits = 20;

/// Every how many values the server keeps a key of a stored print
/// (`track_print_keys`); a lookup sends all of its own.
const int trackPrintKeyStride = 16;

/// The keys to find [print] by in an index: the top [trackPrintKeyBits]
/// bits of every [stride]-th value, without repeats, skipping silence
/// (value 0), which every print has. A copy of the same recording shares
/// some of them exactly, so an index only has to compare prints that share
/// keys. As the server's `track_print_keys`.
List<int> printKeys(TrackPrint print, {int stride = 1}) {
  final keys = <int>{};
  for (var i = 0; i < print.values.length; i += stride) {
    final v = print.values[i];
    if (v != 0) keys.add(v >> (32 - trackPrintKeyBits));
  }
  return keys.toList();
}

/// [print]'s values as signed 32-bit integers, as the server stores them
/// (Postgres has no unsigned integer).
List<int> printValuesSigned(TrackPrint print) => [
  for (final v in print.values) v >= 0x80000000 ? v - 0x100000000 : v,
];

final Uint8List _ones = () {
  final t = Uint8List(1 << 16);
  for (var i = 1; i < t.length; i++) {
    t[i] = t[i >> 1] + (i & 1);
  }
  return t;
}();
