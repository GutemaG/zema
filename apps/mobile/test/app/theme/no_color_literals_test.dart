import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colors must come from `ZemaColors`; only `lib/app/theme/` may define them.
void main() {
  test('lib/ has no Color(0x…) literals outside lib/app/theme/', () {
    final offenders = <String>[];
    final literal = RegExp(r'Color\(\s*0x');
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.startsWith('lib/app/theme/'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (literal.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Use context.zemaColors instead.');
  });
}
