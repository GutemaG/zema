import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zema/shared/random_uuid.dart';

void main() {
  final v4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('is a version 4 UUID', () {
    for (var i = 0; i < 200; i++) {
      expect(randomUuid(), matches(v4));
    }
  });

  test('sets the version and variant bits whatever the random bytes', () {
    expect(randomUuid(_Bytes(0x00)), '00000000-0000-4000-8000-000000000000');
    expect(randomUuid(_Bytes(0xff)), 'ffffffff-ffff-4fff-bfff-ffffffffffff');
  });

  test('differs each time', () {
    expect({for (var i = 0; i < 1000; i++) randomUuid()}, hasLength(1000));
  });
}

/// Answers every byte with [value].
class _Bytes implements Random {
  _Bytes(this.value);

  final int value;

  @override
  int nextInt(int max) => value;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}
