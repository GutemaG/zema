import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

const _rate = fingerprintSampleRate;
const _fp = Fingerprinter();

/// A made-up song: notes of 0.2–0.5 s, each a tone with two overtones, over
/// quiet noise. Every [seed] gives a different song.
Float32List _song(int seed, double seconds) {
  final random = math.Random(seed);
  final out = Float32List((seconds * _rate).round());
  var at = 0;
  while (at < out.length) {
    final length = ((0.2 + random.nextDouble() * 0.3) * _rate).round();
    final base = 150 + random.nextDouble() * 1000;
    for (var i = 0; i < length && at + i < out.length; i++) {
      final t = i / _rate;
      final envelope = math.min(1, i / 200) * math.exp(-3 * t);
      out[at + i] =
          0.3 *
          envelope *
          (math.sin(2 * math.pi * base * t) +
              0.5 * math.sin(2 * math.pi * base * 2.01 * t) +
              0.3 * math.sin(2 * math.pi * base * 3.02 * t));
    }
    at += length;
  }
  for (var i = 0; i < out.length; i++) {
    out[i] += (random.nextDouble() - 0.5) * 0.002;
  }
  return out;
}

Float32List _cut(Float32List pcm, double start, double seconds) =>
    Float32List.sublistView(
      pcm,
      (start * _rate).round(),
      math.min(pcm.length, ((start + seconds) * _rate).round()),
    );

Float32List _join(List<Float32List> parts) {
  final out = Float32List(parts.fold(0, (n, p) => n + p.length));
  var at = 0;
  for (final p in parts) {
    out.setAll(at, p);
    at += p.length;
  }
  return out;
}

/// [pcm] with white noise added at [snrDb].
Float32List _noisy(Float32List pcm, double snrDb, int seed) {
  final random = math.Random(seed);
  var power = 0.0;
  for (final v in pcm) {
    power += v * v;
  }
  final level = math.sqrt(power / pcm.length) / math.pow(10, snrDb / 20);
  return Float32List.fromList([
    for (final v in pcm)
      v + (random.nextDouble() * 2 - 1) * level * math.sqrt(3),
  ]);
}

double _seconds(Duration d) => d.inMicroseconds / 1e6;

void main() {
  final songs = {for (var i = 0; i < 6; i++) 'rec-$i': _song(i, 40)};
  final catalog = FingerprintIndex();
  final offline = FingerprintIndex();
  setUpAll(() {
    songs.forEach((id, pcm) {
      catalog.add(id, _fp.fingerprint(pcm));
      offline.add(
        id,
        _fp.fingerprint(pcm, density: FingerprintDensity.offline),
      );
    });
  });

  group('Fingerprinter', () {
    test('the same audio gives the same fingerprint', () {
      final a = _fp.fingerprint(songs['rec-0']!);
      final b = _fp.fingerprint(Float32List.fromList(songs['rec-0']!));
      expect(a.hashes, b.hashes);
      expect(a.frames, b.frames);
    });

    test('hashes fit in 24 bits and frames never go backwards', () {
      final f = _fp.fingerprint(songs['rec-1']!);
      expect(f.length, greaterThan(1000));
      expect(f.hashes.every((h) => h < 1 << 24), isTrue);
      for (var i = 1; i < f.length; i++) {
        expect(f.frames[i], greaterThanOrEqualTo(f.frames[i - 1]));
      }
    });

    test('silence gives no hashes, even with faint dither', () {
      expect(_fp.fingerprint(Float32List(_rate * 5)).length, 0);
      final random = math.Random(3);
      final dither = Float32List.fromList([
        for (var i = 0; i < _rate * 5; i++) (random.nextDouble() - 0.5) * 2e-5,
      ]);
      expect(_fp.fingerprint(dither).length, 0);
    });

    test('audio shorter than one window gives an empty fingerprint', () {
      final f = _fp.fingerprint(Float32List(500));
      expect(f.length, 0);
      expect(f.frameCount, 0);
    });

    test('indexes keep fewer hashes than queries', () {
      final pcm = songs['rec-2']!;
      final query = _fp.fingerprint(pcm, density: FingerprintDensity.query);
      final cat = _fp.fingerprint(pcm);
      final off = _fp.fingerprint(pcm, density: FingerprintDensity.offline);
      expect(cat.length, lessThan(query.length));
      expect(off.length, lessThan(cat.length));
    });

    test('every pair an index keeps is also in the query', () {
      final pcm = songs['rec-3']!;
      final query = _fp.fingerprint(pcm, density: FingerprintDensity.query);
      final pairs = {
        for (var i = 0; i < query.length; i++)
          (query.hashes[i], query.frames[i]),
      };
      final cat = _fp.fingerprint(pcm);
      for (var i = 0; i < cat.length; i++) {
        expect(pairs, contains((cat.hashes[i], cat.frames[i])));
      }
    });

    test('queries are made at each query speed', () {
      final qs = _fp.queries(_cut(songs['rec-0']!, 10, 5));
      expect(qs.map((q) => q.speed), querySpeeds);
    });
  });

  group('AudioFingerprint bytes', () {
    test('round-trip', () {
      final f = _fp.fingerprint(songs['rec-4']!);
      final back = AudioFingerprint.fromBytes(f.toBytes());
      expect(back.hashes, f.hashes);
      expect(back.frames, f.frames);
      expect(back.frameCount, f.frameCount);
    });

    test('about 4 bytes a hash', () {
      final f = _fp.fingerprint(songs['rec-4']!);
      expect(f.toBytes().length, lessThan(f.length * 5));
    });

    test('another version or damaged bytes are refused', () {
      final bytes = _fp.fingerprint(songs['rec-4']!).toBytes();
      expect(
        () => AudioFingerprint.fromBytes(
          Uint8List.fromList([99, ...bytes.skip(1)]),
        ),
        throwsA(isA<FingerprintFormatFailure>()),
      );
      expect(
        () => AudioFingerprint.fromBytes(Uint8List.sublistView(bytes, 0, 50)),
        throwsA(isA<FingerprintFormatFailure>()),
      );
      // A hash count far beyond the bytes there are.
      expect(
        () => AudioFingerprint.fromBytes(
          Uint8List.fromList([fingerprintVersion, 1, 0xff, 0xff, 0xff, 0x7f]),
        ),
        throwsA(isA<FingerprintFormatFailure>()),
      );
    });
  });

  group('resampleMono and mixToMono', () {
    test(
      '44.1 kHz becomes a quarter as many samples; a tone keeps its pitch',
      () {
        const from = 44100;
        final tone = Float32List.fromList([
          for (var i = 0; i < from; i++) math.sin(2 * math.pi * 440 * i / from),
        ]);
        final out = resampleMono(tone, from);
        expect(out.length, _rate);
        var crossings = 0;
        for (var i = 1; i < out.length; i++) {
          if (out[i - 1] < 0 && out[i] >= 0) crossings++;
        }
        expect(crossings, closeTo(440, 2));
      },
    );

    test('the fingerprint rate is returned as is', () {
      final pcm = Float32List(10);
      expect(identical(resampleMono(pcm, _rate), pcm), isTrue);
    });

    test('stereo is averaged', () {
      expect(mixToMono(Float32List.fromList([1, 0, 0.5, 0.5]), 2), [0.5, 0.5]);
    });
  });

  group('FingerprintIndex.match', () {
    test('a 5 s excerpt from anywhere finds its recording and position', () {
      for (final id in songs.keys) {
        for (final start in [0.0, 7.3, 18.0, 33.9]) {
          final matches = catalog.match(
            _fp.queries(_cut(songs[id]!, start, 5)),
          );
          expect(matches.first.recordingId, id, reason: '$id at $start');
          expect(_seconds(matches.first.position), closeTo(start, 0.05));
          expect(matches.first.playbackSpeed, 1);
          expect(matches.first.score, greaterThanOrEqualTo(minimumMatchScore));
        }
      }
    });

    test('a song that is not in the index finds nothing', () {
      for (var seed = 100; seed < 110; seed++) {
        final other = _song(seed, 12);
        expect(
          catalog.match(_fp.queries(other)),
          isEmpty,
          reason: 'seed $seed',
        );
      }
    });

    test('silence finds nothing', () {
      expect(catalog.match(_fp.queries(Float32List(_rate * 8))), isEmpty);
    });

    test('noise at 5 dB still finds the recording', () {
      final clip = _noisy(_cut(songs['rec-2']!, 12, 8), 5, 1);
      final m = catalog.match(_fp.queries(clip)).first;
      expect(m.recordingId, 'rec-2');
      expect(_seconds(m.position), closeTo(12, 0.05));
    });

    test('a copy sped up by 2% is found, with its speed', () {
      final fast = changeSpeed(songs['rec-5']!, 1.02);
      // 15 s into the fast copy is 15.3 s into the recording.
      final m = catalog.match(_fp.queries(_cut(fast, 15, 6))).first;
      expect(m.recordingId, 'rec-5');
      expect(m.playbackSpeed, closeTo(1.02, 0.001));
      expect(_seconds(m.position), closeTo(15.3, 0.1));
    });

    test('the offline index finds a 10 s excerpt', () {
      for (final id in songs.keys) {
        final m = offline.match(_fp.queries(_cut(songs[id]!, 20, 10)));
        expect(m.first.recordingId, id);
        expect(_seconds(m.first.position), closeTo(20, 0.05));
      }
    });

    test(
      'audio that starts before the recording gives a negative position',
      () {
        final withIntro = _join([_song(50, 3), _cut(songs['rec-1']!, 0, 6)]);
        final m = catalog.match(_fp.queries(withIntro)).first;
        expect(m.recordingId, 'rec-1');
        expect(_seconds(m.position), closeTo(-3, 0.05));
      },
    );

    test('a chorus that repeats is flagged as an ambiguous position', () {
      final chorus = _song(60, 8);
      final song = _join([
        _song(61, 10),
        chorus,
        _song(62, 10),
        chorus,
        _song(63, 5),
      ]);
      final index = FingerprintIndex()..add('repeats', _fp.fingerprint(song));
      final m = index.match(_fp.queries(_cut(chorus, 1, 5))).first;
      expect(m.recordingId, 'repeats');
      expect(m.ambiguousPosition, isTrue);
      expect(_seconds(m.position), anyOf(closeTo(11, 0.05), closeTo(29, 0.05)));

      // An excerpt mostly past the chorus settles it. (One that is still
      // 3 s of chorus stays flagged: the rule leans to listening longer.)
      final past = index.match(_fp.queries(_cut(song, 35, 6))).first;
      expect(past.ambiguousPosition, isFalse);
      expect(_seconds(past.position), closeTo(35, 0.05));
    });

    test('limit caps the number of matches', () {
      final index = FingerprintIndex()
        ..add('a', _fp.fingerprint(songs['rec-0']!))
        ..add('b', _fp.fingerprint(songs['rec-0']!));
      final q = _fp.queries(_cut(songs['rec-0']!, 5, 5));
      expect(index.match(q), hasLength(2));
      expect(index.match(q, limit: 1), hasLength(1));
    });
  });
}
