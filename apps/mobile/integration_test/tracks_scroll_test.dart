// On-device check that the Tracks list scrolls smoothly with a large library.
//
// Needs a device with audio access granted and the bulk test files
// (`tool/test_audio.sh --bulk 1000`). Run in profile mode from apps/mobile:
//
//   flutter drive --profile --no-dds -d <device> \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/tracks_scroll_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scrolling 1,000 tracks', (tester) async {
    await app.main();
    await _pumpUntilFound(tester, find.text('Library'));
    await tester.tap(find.text('Library').last);
    await _pumpUntilFound(tester, find.byType(TrackRow));

    final list = find.byType(ListView).first;
    await binding.watchPerformance(() async {
      for (var i = 0; i < 6; i++) {
        await tester.fling(list, const Offset(0, -1200), 4000);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 6; i++) {
        await tester.fling(list, const Offset(0, 1200), 4000);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'tracks_scroll');
  });
}

/// Pumps frames until [finder] matches, for up to [timeout].
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}
