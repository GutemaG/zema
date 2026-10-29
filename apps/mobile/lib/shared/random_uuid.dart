import 'dart:math';

/// A random (version 4) UUID, e.g. `3f2b8c1e-9a4d-4e7f-b2c6-0d5e8a1f7c93`.
String randomUuid([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = [for (var i = 0; i < 16; i++) source.nextInt(256)];
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return [
    hex.sublist(0, 4),
    hex.sublist(4, 6),
    hex.sublist(6, 8),
    hex.sublist(8, 10),
    hex.sublist(10, 16),
  ].map((part) => part.join()).join('-');
}
