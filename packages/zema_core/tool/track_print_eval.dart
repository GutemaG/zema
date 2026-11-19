// Tries the track print on real songs. Needs ffmpeg on the PATH.
//
//   dart run tool/track_print_eval.dart <folder>...
//
// For every file under the folders (recursively): re-encodes and trimmed
// starts of it are printed and compared with the file's own print, and every
// two different files are compared. Prints the bit differences, shared index
// keys, sizes and time, for each hop tried. Audio is decoded in memory only.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:zema_core/zema_core.dart';

const _hops = [trackPrintHop];
const _strides = [1, 4, 8, trackPrintKeyStride];

/// Copies of each file: ffmpeg input options (before `-i`) and encoder
/// options, or null for the file as it is.
const _copies = <String, (String, String)>{
  '128 kbps MP3': ('', '-c:a libmp3lame -b:a 128k -f mp3'),
  '64 kbps MP3': ('', '-c:a libmp3lame -b:a 64k -f mp3'),
  '128 kbps AAC': ('', '-c:a aac -b:a 128k -f adts'),
  'trim 0.3 s': ('-ss 0.3', '-c:a libmp3lame -b:a 128k -f mp3'),
  'trim 1 s': ('-ss 1', '-c:a libmp3lame -b:a 128k -f mp3'),
  'trim 2 s': ('-ss 2', '-c:a libmp3lame -b:a 128k -f mp3'),
};

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('usage: track_print_eval.dart <folder>...');
    exit(64);
  }
  final audio = RegExp(
    r'\.(mp3|m4a|aac|ogg|opus|flac|wav)$',
    caseSensitive: false,
  );
  final files = [
    for (final folder in args)
      ...Directory(folder)
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => audio.hasMatch(p) && !p.contains('/Backup')),
  ]..sort();
  print('${files.length} files\n');

  // pcm of each file, and of each copy, decoded a few at a time.
  final originals = <String, Float32List>{};
  final copies = <String, Map<String, Float32List>>{};
  for (var i = 0; i < files.length; i += 8) {
    await Future.wait([
      for (final path in files.skip(i).take(8))
        () async {
          originals[path] = await _decode(path, '', '');
          copies[path] = {
            for (final MapEntry(key: name, value: (input, encode))
                in _copies.entries)
              name: await _decode(path, input, encode),
          };
        }(),
    ]);
    stdout.write('\rdecoded ${math.min(i + 8, files.length)}');
  }
  print('\n');

  for (final hop in _hops) {
    final printer = TrackPrinter(hop: hop);
    final clock = Stopwatch()..start();
    final base = {for (final p in files) p: printer.print(originals[p]!)};
    final perPrint = clock.elapsedMilliseconds / files.length;
    final bytes = base.values.map((p) => p.toBytes().length).reduce(math.max);
    print(
      '=== hop $hop (${trackPrintFrame(hop).inMilliseconds} ms): '
      'up to ${(bytes / 1024).toStringAsFixed(1)} KB, '
      '${perPrint.toStringAsFixed(0)} ms per print',
    );

    // Copies.
    final worst = <String, (double, String)>{};
    final fewestKeys = {for (final s in _strides) s: 1 << 30};
    var worstCopy = 0.0;
    for (final path in files) {
      final stored = base[path]!;
      for (final MapEntry(key: name, value: pcm) in copies[path]!.entries) {
        final copy = printer.print(pcm);
        final d = printDistance(stored, copy, hop: hop);
        final bits = d?.bits ?? 1;
        if (bits > (worst[name]?.$1 ?? -1)) worst[name] = (bits, _short(path));
        worstCopy = math.max(worstCopy, bits);
        final query = printKeys(copy).toSet();
        for (final s in _strides) {
          final shared = printKeys(
            stored,
            stride: s,
          ).where(query.contains).length;
          fewestKeys[s] = math.min(fewestKeys[s]!, shared);
        }
      }
    }
    for (final MapEntry(key: name, value: (bits, file)) in worst.entries) {
      print('  copy ${name.padRight(13)} worst ${_pct(bits)}  ($file)');
    }

    // Different files.
    final close = <(double, String, String)>[];
    var keysSum = 0, keysMax = 0, pairs = 0;
    final stored4 = {
      for (final p in files) p: printKeys(base[p]!, stride: 4).toSet(),
    };
    for (var i = 0; i < files.length; i++) {
      final query = printKeys(base[files[i]]!).toSet();
      for (var j = i + 1; j < files.length; j++) {
        final d = printDistance(base[files[i]]!, base[files[j]]!, hop: hop);
        close.add((d?.bits ?? 1, _short(files[i]), _short(files[j])));
        final shared = stored4[files[j]]!.where(query.contains).length;
        keysSum += shared;
        keysMax = math.max(keysMax, shared);
        pairs++;
      }
    }
    close.sort((a, b) => a.$1.compareTo(b.$1));
    print('  different files, closest:');
    for (final (bits, a, b) in close.take(8)) {
      print('    ${_pct(bits)}  $a  ~  $b');
    }
    print(
      '  worst copy ${_pct(worstCopy)}, closest different '
      '${_pct(close.first.$1)}',
    );
    print(
      '  fewest keys a copy shares, by stride: '
      '${[for (final s in _strides) '$s: ${fewestKeys[s]}'].join(', ')}',
    );
    print(
      '  keys different files share (stride 4): '
      'mean ${(keysSum / pairs).toStringAsFixed(1)}, max $keysMax\n',
    );
  }
}

String _pct(double bits) => '${(100 * bits).toStringAsFixed(1)} %';

String _short(String path) {
  final parts = path.split('/');
  final name = parts.sublist(math.max(0, parts.length - 2)).join('/');
  return name.length > 50 ? '${name.substring(0, 50)}…' : name;
}

/// The first 125 s of [path] (or of its copy) at [fingerprintSampleRate].
Future<Float32List> _decode(String path, String input, String encode) async {
  final q = path.replaceAll("'", r"'\''");
  final cmd = encode.isEmpty
      ? "ffmpeg -v error -t 125 -i '$q' -vn -ac 1 -ar $fingerprintSampleRate -f s16le -"
      : "ffmpeg -v error $input -t 125 -i '$q' -vn $encode - | "
            'ffmpeg -v error -i - -ac 1 -ar $fingerprintSampleRate -f s16le -';
  final r = await Process.run('bash', ['-c', cmd], stdoutEncoding: null);
  if (r.exitCode != 0) throw StateError('ffmpeg failed on $path: ${r.stderr}');
  final b = Uint8List.fromList(r.stdout as List<int>);
  final s = b.buffer.asInt16List(0, b.length ~/ 2);
  return Float32List.fromList([for (final x in s) x / 32768]);
}
