import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

/// [seconds] of changing tones and noise, the same for the same [seed].
Float32List _music(int seconds, {int seed = 1}) {
  final random = math.Random(seed);
  final out = Float32List(seconds * fingerprintSampleRate);
  var f1 = 440.0, f2 = 660.0;
  for (var i = 0; i < out.length; i++) {
    if (i % 2205 == 0) {
      f1 = 300 + random.nextDouble() * 1500;
      f2 = 300 + random.nextDouble() * 1500;
    }
    final t = i / fingerprintSampleRate;
    out[i] =
        0.4 * math.sin(2 * math.pi * f1 * t) +
        0.3 * math.sin(2 * math.pi * f2 * t) +
        0.05 * (random.nextDouble() - 0.5);
  }
  return out;
}

void main() {
  const printer = TrackPrinter();
  final song = _music(130);
  final print = printer.print(song);

  test('covers the first 110 s in at most 10 KB', () {
    final frame = trackPrintFrame().inMicroseconds;
    expect(print.values.length, closeTo(110e6 / frame, 25));
    expect(print.toBytes().length, lessThanOrEqualTo(10 * 1024));
    expect(print.duration.inSeconds, 130);
  });

  test('survives toBytes and fromBytes', () {
    final back = TrackPrint.fromBytes(print.toBytes());
    expect(back.values, print.values);
    expect(back.duration, print.duration);
  });

  test('rejects another version and damaged bytes', () {
    final bytes = print.toBytes();
    expect(
      () => TrackPrint.fromBytes(Uint8List.fromList([2, ...bytes.skip(1)])),
      throwsA(isA<FingerprintFormatFailure>()),
    );
    expect(
      () => TrackPrint.fromBytes(Uint8List.sublistView(bytes, 0, 50)),
      throwsA(isA<FingerprintFormatFailure>()),
    );
  });

  test('the same audio is 0 apart, and a start cut by whole frames lines up '
      'at that shift', () {
    expect(printDistance(print, printer.print(song))!.bits, 0);
    // 10 print frames = 10 hops at half the rate = 20 hops of input samples.
    final cut = Float32List.sublistView(song, 10 * 2 * trackPrintHop);
    final d = printDistance(print, printer.print(cut))!;
    expect(d.shift, -10);
    expect(d.bits, lessThan(0.02));
    expect(d.bits, lessThan(trackPrintMatch));
  });

  test('other audio is about half the bits apart', () {
    final d = printDistance(print, printer.print(_music(130, seed: 2)))!;
    expect(d.bits, closeTo(0.5, 0.05));
    expect(d.bits, greaterThan(trackPrintMatch));
  });

  test('too short to compare gives null; very short audio gives no values', () {
    final short = printer.print(_music(20));
    expect(printDistance(print, short), isNull);
    expect(printer.print(Float32List(1000)).values, isEmpty);
  });

  test('keys are the top bits, fewer with a stride', () {
    final all = printKeys(print);
    expect(all.every((k) => k < 1 << trackPrintKeyBits), isTrue);
    expect(all.toSet().length, all.length);
    expect(printKeys(print, stride: 4).length, lessThan(all.length));
    final silent = TrackPrint(
      values: Uint32List.fromList([0, 0, 0x80001000]),
      duration: Duration.zero,
    );
    expect(printKeys(silent), [0x80001]);
  });

  test('signed values keep the bits', () {
    final p = TrackPrint(
      values: Uint32List.fromList([1, 0x7fffffff, 0x80000000, 0xffffffff]),
      duration: Duration.zero,
    );
    expect(printValuesSigned(p), [1, 0x7fffffff, -0x80000000, -1]);
  });
}
