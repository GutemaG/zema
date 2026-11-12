// Tries the audio fingerprint on real songs. Needs ffmpeg on the PATH.
//
//   dart run tool/fingerprint_eval.dart <music folder>
//       Indexes every song, then identifies excerpts of each one: lengths,
//       positions, simulated microphone conditions, songs left out.
//   dart run tool/fingerprint_eval.dart <music folder> --explain <song> <start s> [<length s>]
//       Shows one excerpt step by step: peaks, hashes, votes per recording.
//   dart run tool/fingerprint_eval.dart <music folder> --identify <recording>
//       Identifies any recording (e.g. a phone voice memo of a speaker)
//       against the folder, every 3 s along it.
//
// Audio is decoded in memory and never written anywhere.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:zema_core/zema_core.dart';

const _fp = Fingerprinter();
const _rate = fingerprintSampleRate;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'usage: fingerprint_eval.dart <music folder> [--explain <song> <start> [len] | --identify <file>]',
    );
    exit(64);
  }
  final files =
      Directory(args[0])
          .listSync()
          .whereType<File>()
          .where(
            (f) => RegExp(
              r'\.(mp3|m4a|aac|ogg|opus|flac|wav)$',
              caseSensitive: false,
            ).hasMatch(f.path),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final songs = <String, Float32List>{};
  for (final f in files) {
    songs[_name(f.path)] = await _decode(f.path);
  }
  print(
    '${songs.length} songs, ${(songs.values.fold(0, (n, p) => n + p.length) / _rate / 60).toStringAsFixed(1)} minutes\n',
  );

  final catalog = FingerprintIndex();
  final offline = FingerprintIndex();
  var catalogBytes = 0, offlineBytes = 0;
  final clock = Stopwatch()..start();
  for (final MapEntry(key: name, value: pcm) in songs.entries) {
    final c = _fp.fingerprint(pcm);
    final o = _fp.fingerprint(pcm, density: FingerprintDensity.offline);
    catalog.add(name, c);
    offline.add(name, o);
    catalogBytes += c.toBytes().length;
    offlineBytes += o.toBytes().length;
  }
  final minutes = songs.values.fold(0, (n, p) => n + p.length) / _rate / 60;
  print('Index    hashes/s  KB per 5 min (bytes form)');
  print(
    'catalog  ${(catalog.hashCount / minutes / 60).toStringAsFixed(0).padLeft(8)}  ${(catalogBytes / 1024 / minutes * 5).toStringAsFixed(0).padLeft(6)}',
  );
  print(
    'offline  ${(offline.hashCount / minutes / 60).toStringAsFixed(0).padLeft(8)}  ${(offlineBytes / 1024 / minutes * 5).toStringAsFixed(0).padLeft(6)}',
  );
  print(
    'Fingerprinting both: ${(clock.elapsedMilliseconds / minutes * 4 / 2).toStringAsFixed(0)} ms per 4-minute song each (this computer)\n',
  );

  if (args.length >= 3 && args[1] == '--explain') {
    final name = songs.keys.firstWhere(
      (k) => k.toLowerCase().contains(args[2].toLowerCase()),
    );
    final start = double.parse(args[3]);
    final length = args.length > 4 ? double.parse(args[4]) : 5.0;
    _explain(catalog, name, _cut(songs[name]!, start, length), start);
    return;
  }
  if (args.length >= 3 && args[1] == '--identify') {
    _identify(catalog, offline, await _decode(args[2]));
    return;
  }
  _evaluate(songs, catalog, offline);
}

void _evaluate(
  Map<String, Float32List> songs,
  FingerprintIndex catalog,
  FingerprintIndex offline,
) {
  final names = songs.keys.toList();
  final conditions = <String, Float32List Function(int, Float32List)>{
    'clean': (i, clip) => clip,
    'speed +2%': (i, clip) => changeSpeed(clip, 1.02),
    'room, 10 dB': (i, clip) =>
        _microphone(clip, songs[names[(i + 5) % names.length]]!, 10, 0.6),
    'hall, 5 dB + babble': (i, clip) => _microphone(
      clip,
      songs[names[(i + 5) % names.length]]!,
      5,
      1.2,
      babble: true,
    ),
    'hall, 0 dB + babble': (i, clip) => _microphone(
      clip,
      songs[names[(i + 5) % names.length]]!,
      0,
      1.5,
      babble: true,
    ),
  };
  const lengths = [3.0, 5.0, 10.0];
  for (final (label, index) in [('catalog', catalog), ('offline', offline)]) {
    print('$label index: right song (p95 position error), wrong song');
    print(
      'condition'.padRight(22) +
          lengths.map((l) => '${l.toInt()} s'.padLeft(18)).join(),
    );
    for (final MapEntry(key: condition, value: apply) in conditions.entries) {
      final row = StringBuffer(condition.padRight(22));
      for (final length in lengths) {
        var right = 0, wrong = 0, total = 0;
        final errors = <double>[];
        for (var i = 0; i < names.length; i++) {
          final pcm = songs[names[i]]!;
          for (final start in _starts(pcm)) {
            total++;
            final speedUp = condition.startsWith('speed') ? 1.02 : 1.0;
            final clip = apply(i, _cut(pcm, start, length * speedUp));
            final m = index.match(_fp.queries(clip));
            if (m.isEmpty) continue;
            if (m.first.recordingId != names[i]) {
              wrong++;
              continue;
            }
            right++;
            errors.add((m.first.position.inMicroseconds / 1e6 - start).abs());
          }
        }
        errors.sort();
        final p95 = errors.isEmpty
            ? 0
            : errors[math.min(
                errors.length - 1,
                (errors.length * .95).floor(),
              )];
        row.write(
          '${(100 * right / total).toStringAsFixed(0)}% (±${p95.toStringAsFixed(2)} s)${wrong > 0 ? ' w$wrong' : ''}'
              .padLeft(18),
        );
      }
      print(row);
    }
    print('');
  }

  // Songs left out: each song's excerpts against an index of the others.
  var falseMatches = 0, tries = 0;
  for (var i = 0; i < names.length; i++) {
    final others = FingerprintIndex();
    for (var j = 0; j < names.length; j++) {
      if (j != i) others.add(names[j], _fp.fingerprint(songs[names[j]]!));
    }
    for (final start in _starts(songs[names[i]]!)) {
      tries++;
      final m = others.match(_fp.queries(_cut(songs[names[i]]!, start, 10)));
      if (m.isNotEmpty) {
        falseMatches++;
        print(
          '  false match: ${names[i]} @${start.toStringAsFixed(0)} s -> $m',
        );
      }
    }
  }
  print(
    'Songs not in the index: $falseMatches false matches in $tries excerpts '
    '(threshold $minimumMatchScore aligned hashes)',
  );

  final clip = _cut(songs.values.first, 30, 10);
  final clock = Stopwatch()..start();
  for (var k = 0; k < 10; k++) {
    catalog.match(_fp.queries(clip));
  }
  print(
    'Identify 10 s (5 speeds, fingerprint + match): ${(clock.elapsedMilliseconds / 10).toStringAsFixed(0)} ms on this computer',
  );
}

void _explain(
  FingerprintIndex catalog,
  String name,
  Float32List clip,
  double start,
) {
  final q = _fp.fingerprint(clip, density: FingerprintDensity.query);
  print(
    'Excerpt: "$name" from ${start}s, ${(clip.length / _rate).toStringAsFixed(1)} s',
  );
  print(
    '1. Spectrogram: ${q.frameCount} frames of ${(fingerprintHop / _rate * 1000).toStringAsFixed(0)} ms',
  );
  print(
    '2-3. Peaks paired into ${q.length} hashes (${(q.length / (clip.length / _rate)).toStringAsFixed(0)} a second). First five:',
  );
  for (var i = 0; i < math.min(5, q.length); i++) {
    final h = q.hashes[i];
    final f1 = h >> 15, f2 = h >> 6 & 0x1ff, dt = h & 0x3f;
    print(
      '   frame ${q.frames[i].toString().padLeft(4)}: ${(f1 * _rate / 1024).round()} Hz -> ${(f2 * _rate / 1024).round()} Hz after ${(dt * fingerprintHop / _rate * 1000).round()} ms  = hash 0x${h.toRadixString(16).padLeft(6, '0')}',
    );
  }
  print(
    '   Upload size: ${q.toBytes().length} bytes (${_fp.queries(clip).fold(0, (n, f) => n + f.toBytes().length)} for all 5 speeds)',
  );
  print(
    '4. Votes: for each hash found in a recording, shift = recording frame - excerpt frame.',
  );
  final matches = catalog.match(_fp.queries(clip), limit: 5);
  if (matches.isEmpty) {
    print('   No recording reached $minimumMatchScore aligned hashes.');
  }
  for (final m in matches) {
    print('   $m');
  }
}

void _identify(
  FingerprintIndex catalog,
  FingerprintIndex offline,
  Float32List recording,
) {
  final seconds = recording.length / _rate;
  print(
    'Recording: ${seconds.toStringAsFixed(1)} s. Listening 3, 6 and 10 s windows every 3 s:',
  );
  for (var at = 0.0; at + 3 <= seconds; at += 3) {
    final line = StringBuffer('${at.toStringAsFixed(0).padLeft(4)} s');
    for (final length in [3.0, 6.0, 10.0]) {
      if (at + length > seconds) break;
      final queries = _fp.queries(_cut(recording, at, length));
      final c = catalog.match(queries);
      final o = offline.match(queries);
      String show(List<AudioMatch> m) => m.isEmpty
          ? '-'
          : '${m.first.recordingId.substring(0, math.min(18, m.first.recordingId.length))} @${(m.first.position.inMilliseconds / 1000).toStringAsFixed(1)}s (${m.first.score}${m.first.ambiguousPosition ? '?' : ''})';
      line.write('  |${length.toInt()}s: ${show(c)} / off: ${show(o)}');
    }
    print(line);
  }
}

List<double> _starts(Float32List pcm) {
  final d = pcm.length / _rate;
  return [2, d * .25, d * .5, d * .75, d - 12];
}

Float32List _cut(Float32List pcm, double start, double seconds) =>
    Float32List.sublistView(
      pcm,
      (start * _rate).round().clamp(0, pcm.length),
      ((start + seconds) * _rate).round().clamp(0, pcm.length),
    );

String _name(String path) =>
    path.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');

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
    '$_rate',
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

final _random = math.Random(7);

double _gauss() =>
    math.sqrt(-2 * math.log(_random.nextDouble() + 1e-12)) *
    math.cos(2 * math.pi * _random.nextDouble());

double _rms(Float32List x) =>
    math.sqrt(x.fold(0.0, (s, v) => s + v * v) / math.max(1, x.length));

/// A phone 2 m from a speaker: band-limited, reverb with [rt] s decay, pink
/// noise (and reversed music as babble) at [snrDb].
Float32List _microphone(
  Float32List clip,
  Float32List other,
  double snrDb,
  double rt, {
  bool babble = false,
}) {
  final x = Float32List.fromList(clip);
  var hp = 0.0, previous = 0.0, lp = 0.0;
  for (var i = 0; i < x.length; i++) {
    hp = 0.89 * (hp + x[i] - previous);
    previous = x[i];
    lp += 0.7 * (hp - lp);
    x[i] = lp;
  }
  final y = Float32List.fromList(x);
  for (var k = 0; k < 200; k++) {
    final d = (_random.nextDouble() * rt * _rate).round() + 200;
    final g =
        0.35 * math.exp(-6.9 * d / (rt * _rate)) * _gauss() / math.sqrt(20);
    for (var i = d; i < y.length; i++) {
      y[i] += g * x[i - d];
    }
  }
  final noise = Float32List(y.length);
  var pink = 0.0;
  for (var i = 0; i < y.length; i++) {
    pink = 0.97 * pink + _gauss() * 0.25;
    noise[i] =
        pink +
        (babble ? other[other.length - 1 - (i * 3 % other.length)] * 8 : 0);
  }
  final level = _rms(y) / math.pow(10, snrDb / 20) / _rms(noise);
  for (var i = 0; i < y.length; i++) {
    y[i] += noise[i] * level;
  }
  return y;
}
