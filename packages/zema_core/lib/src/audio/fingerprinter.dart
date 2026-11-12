import 'dart:math' as math;
import 'dart:typed_data';

import 'audio_fingerprint.dart';

/// How many hashes a fingerprint keeps.
///
/// Indexes keep fewer than queries: every pair an index keeps is also made by
/// the query (same peaks, more pairs each), so one query matches both, and
/// the offline index stays small. Measured in the 009 spike (requirements.md).
enum FingerprintDensity {
  /// An excerpt to identify: about 185 hashes a second.
  query(peaksPerSecond: 20, pairsPerPeak: 10),

  /// The server's index: about 100 hashes a second, ~170 KB per 5 minutes.
  catalog(peaksPerSecond: 20, pairsPerPeak: 5),

  /// The index kept on the phone: about 20 hashes a second.
  offline(peaksPerSecond: 10, pairsPerPeak: 2);

  const FingerprintDensity({
    required this.peaksPerSecond,
    required this.pairsPerPeak,
  });

  final int peaksPerSecond;
  final int pairsPerPeak;
}

/// Speeds a query is also tried at, to find copies that were sped up or
/// slowed down (common in re-uploads; it moves every frequency, so the
/// hashes change).
const List<double> querySpeeds = [1, 0.98, 0.99, 1.01, 1.02];

/// Turns audio into an [AudioFingerprint].
///
/// 1. Spectrogram: 1,024-sample windows every [fingerprintHop] samples.
/// 2. Peaks: points louder than everything within ±6 frames and ±12 bins,
///    between ~100 Hz and 4 kHz, and not in silence; the strongest
///    [FingerprintDensity.peaksPerSecond] in each second.
/// 3. Hashes: each peak paired with the next few peaks up to 63 frames
///    (~1.5 s) later.
class Fingerprinter {
  const Fingerprinter();

  static const _size = 1024;
  static const _bins = _size ~/ 2;
  static const _lowBin = 10; // ~108 Hz
  static const _highBin = 372; // ~4 kHz
  static const _frameReach = 6;
  static const _binReach = 12;
  static const _maxFrameGap = 63;
  static const _maxBinGap = 127;

  /// Log power below this is silence; no peaks there.
  static const _silence = -4.0;

  /// Frames in a second, for the peak budget.
  static final _framesPerSecond = (fingerprintSampleRate / fingerprintHop)
      .round();

  /// Fingerprint of [pcm]: mono samples in -1…1 at [fingerprintSampleRate].
  AudioFingerprint fingerprint(
    Float32List pcm, {
    FingerprintDensity density = FingerprintDensity.catalog,
    double speed = 1,
  }) {
    final frames = pcm.length < _size
        ? 0
        : (pcm.length - _size) ~/ fingerprintHop + 1;
    final peaks = _peaks(pcm, frames, density.peaksPerSecond);
    return _pair(peaks, density.pairsPerPeak, frames, speed);
  }

  /// A query fingerprint of [pcm] at each of [querySpeeds].
  List<AudioFingerprint> queries(Float32List pcm) => [
    for (final speed in querySpeeds)
      fingerprint(
        speed == 1 ? pcm : changeSpeed(pcm, speed),
        density: FingerprintDensity.query,
        speed: speed,
      ),
  ];

  /// Bins any peak test reads: up to [_binReach] above the highest peak bin.
  static const _usedBins = _highBin + _binReach;

  /// Log power spectra of the frames at [frame] into [a] and, when there is
  /// one, [frame] + 1 into [b], for the bins below [_usedBins].
  ///
  /// Both go through one complex FFT: the first frame as the real part, the
  /// second as the imaginary part. As both are real, their spectra separate
  /// again from the result's symmetric halves.
  static void _spectra(
    Float32List pcm,
    int frames,
    int frame,
    Float32List a,
    Float32List b,
    Float64List re,
    Float64List im,
  ) {
    final start = frame * fingerprintHop;
    final second = frame + 1 < frames;
    for (var i = 0; i < _size; i++) {
      re[i] = pcm[start + i] * _window[i];
      im[i] = second ? pcm[start + fingerprintHop + i] * _window[i] : 0;
    }
    _fft(re, im);
    for (var k = 0; k < _usedBins; k++) {
      final m = k == 0 ? 0 : _size - k;
      final sumRe = re[k] + re[m];
      final diffIm = im[k] - im[m];
      final sumIm = im[k] + im[m];
      final diffRe = re[k] - re[m];
      a[k] = math.log((sumRe * sumRe + diffIm * diffIm) / 4 + 1e-9);
      b[k] = math.log((sumIm * sumIm + diffRe * diffRe) / 4 + 1e-9);
    }
  }

  /// The peaks of [frames] frames of [pcm], in frame then bin order.
  ///
  /// One pass, holding only the frames a peak test needs (±[_frameReach])
  /// in a ring, so memory doesn't grow with the audio. Peaks are ranked
  /// against each bin's average over the whole audio, so they are kept as
  /// candidates (a few per frame) until the average is known.
  List<_Peak> _peaks(Float32List pcm, int frames, int perSecond) {
    final re = Float64List(_size);
    final im = Float64List(_size);
    // Frames t - reach … t + reach, plus the one computed with the last.
    const span = 2 * _frameReach + 2;
    final ring = List.generate(span, (_) => Float32List(_bins));
    // Each bin's average over the audio, so the per-second choice favours
    // peaks that stand out over steady bass and hum.
    final mean = Float64List(_bins);
    final seconds = <List<_Peak>>[];

    var computed = 0;
    for (var t = 0; t < frames; t++) {
      // Frames up to t + reach are in the ring.
      while (computed < frames && computed <= t + _frameReach) {
        final a = ring[computed % span];
        final b = ring[(computed + 1) % span];
        _spectra(pcm, frames, computed, a, b, re, im);
        for (var k = 0; k < _usedBins; k++) {
          mean[k] += a[k];
        }
        if (computed + 1 < frames) {
          for (var k = 0; k < _usedBins; k++) {
            mean[k] += b[k];
          }
        }
        computed += 2;
      }
      final current = ring[t % span];
      for (var f = _lowBin; f < _highBin; f++) {
        final v = current[f];
        if (v < _silence || !_isLocalMax(ring, frames, t, f, v)) continue;
        final second = t ~/ _framesPerSecond;
        while (seconds.length <= second) {
          seconds.add([]);
        }
        seconds[second].add(_Peak(t, f, v));
      }
    }
    for (var k = 0; k < _usedBins; k++) {
      mean[k] /= math.max(1, frames);
    }

    final kept = <_Peak>[];
    for (final candidates in seconds) {
      final ranked = [
        for (final p in candidates)
          _Peak(p.frame, p.bin, p.strength - mean[p.bin]),
      ]..sort((a, b) => b.strength.compareTo(a.strength));
      kept.addAll(ranked.take(perSecond));
    }
    kept.sort(
      (a, b) => a.frame != b.frame
          ? a.frame.compareTo(b.frame)
          : a.bin.compareTo(b.bin),
    );
    return kept;
  }

  /// Whether [v] at ([t], [f]) is above every other point near it. Ties
  /// don't count, so flat areas give no peaks. [ring] holds frame `tt` at
  /// `tt % ring.length` for every frame within reach of [t].
  static bool _isLocalMax(
    List<Float32List> ring,
    int frames,
    int t,
    int f,
    double v,
  ) {
    final from = math.max(0, t - _frameReach);
    final to = math.min(frames - 1, t + _frameReach);
    final lo = math.max(0, f - _binReach);
    final hi = math.min(_bins - 1, f + _binReach);
    for (var tt = from; tt <= to; tt++) {
      final row = ring[tt % ring.length];
      for (var ff = lo; ff <= hi; ff++) {
        if ((tt != t || ff != f) && row[ff] >= v) return false;
      }
    }
    return true;
  }

  AudioFingerprint _pair(
    List<_Peak> peaks,
    int perPeak,
    int frameCount,
    double speed,
  ) {
    final hashes = <int>[];
    final frames = <int>[];
    for (var i = 0; i < peaks.length; i++) {
      final a = peaks[i];
      var made = 0;
      for (var j = i + 1; j < peaks.length && made < perPeak; j++) {
        final b = peaks[j];
        final gap = b.frame - a.frame;
        if (gap == 0) continue;
        if (gap > _maxFrameGap) break;
        if ((b.bin - a.bin).abs() > _maxBinGap) continue;
        hashes.add(a.bin << 15 | b.bin << 6 | gap);
        frames.add(a.frame);
        made++;
      }
    }
    return AudioFingerprint(
      hashes: Uint32List.fromList(hashes),
      frames: Uint32List.fromList(frames),
      frameCount: frameCount,
      speed: speed,
    );
  }

  static final Float64List _window = Float64List.fromList([
    for (var i = 0; i < _size; i++)
      0.5 - 0.5 * math.cos(2 * math.pi * i / (_size - 1)),
  ]);
  static final Float64List _cos = Float64List.fromList([
    for (var i = 0; i < _bins; i++) math.cos(2 * math.pi * i / _size),
  ]);
  static final Float64List _sin = Float64List.fromList([
    for (var i = 0; i < _bins; i++) math.sin(2 * math.pi * i / _size),
  ]);
  static final Int32List _reversed = Int32List.fromList([
    for (var i = 0; i < _size; i++) _reverseBits(i),
  ]);

  static int _reverseBits(int i) {
    var r = 0;
    for (var b = 0, v = i; b < 10; b++, v >>= 1) {
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

class _Peak {
  const _Peak(this.frame, this.bin, this.strength);

  final int frame;
  final int bin;
  final double strength;
}

/// [pcm] played at [speed] (pitch moves with it), by interpolation: 1.02 is
/// 2% faster and shorter.
Float32List changeSpeed(Float32List pcm, double speed) {
  final out = Float32List(math.max(0, (pcm.length / speed).floor() - 1));
  for (var i = 0; i < out.length; i++) {
    final p = i * speed;
    final k = p.floor();
    final f = p - k;
    out[i] = pcm[k] * (1 - f) + pcm[math.min(k + 1, pcm.length - 1)] * f;
  }
  return out;
}
