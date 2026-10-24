import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// User-visible text must come from AppLocalizations so it can be translated.
void main() {
  test('lib/ passes no string literals as user-visible text', () {
    // Text('…'), tooltip: '…', semanticLabel: '…', label: '…', title: '…',
    // with single or double quotes.
    final literal = RegExp(
      r'''(\bText\(\s*|\b(tooltip|semanticLabel|label|title|message):\s*)['"]''',
    );
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.startsWith('lib/l10n/generated/'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (literal.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Add the text to lib/l10n/app_en.arb.');
  });
}
