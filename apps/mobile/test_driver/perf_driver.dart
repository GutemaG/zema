import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Writes the frame-timing summaries reported by `watchPerformance` to
/// `build/integration_response_data.json` and prints them.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await File('build/integration_response_data.json').writeAsString(json);
    stdout.writeln(json);
  },
);
