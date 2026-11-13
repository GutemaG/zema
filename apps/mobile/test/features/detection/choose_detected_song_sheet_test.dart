import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/features/detection/application/detected_song.dart';
import 'package:zema/features/detection/data/playback_detector.dart';
import 'package:zema/features/detection/presentation/choose_detected_song_sheet.dart';
import 'package:zema/features/identify/data/quick_launch.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

CatalogEntry _entry(String id, String title, {String? artist}) => CatalogEntry(
  id: id,
  title: title,
  artist: artist,
  synced: true,
  version: 1,
  approvedAt: DateTime.utc(2026, 10, 1),
);

void main() {
  testWidgets('suggestions come first, and picking one is remembered', (
    tester,
  ) async {
    useScreen(tester, size: const Size(400, 900));
    final db = memoryDatabase();
    final halea = _entry('halea', 'ሃሌ ሉያ ዘምሩ', artist: 'Choir A');
    final haleb = _entry('haleb', 'ሃሌ ሉያ ዘምሩ', artist: 'Choir B');
    await tester.runAsync(
      () => db.catalogDao.replaceAll([_entry('amen', 'አሜን አሜን'), halea, haleb]),
    );
    final playback = DetectedPlayback(
      source: 'com.google.android.youtube',
      state: DetectedState.playing,
      title: 'ሃሌ ሉያ ዘምሩ | live',
      position: Duration.zero,
      positionUpdatedAt: DateTime(2026, 11, 13),
    );
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await pumpThemed(
      tester,
      UncontrolledProviderScope(
        container: container,
        child: ChooseDetectedSongSheet(
          detected: DetectedUnsure(playback, candidates: [haleb, halea]),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Which song is playing?'), findsOneWidget);
    expect(find.text('ሃሌ ሉያ ዘምሩ | live'), findsOneWidget);
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles.map((t) => (t.key! as ValueKey<String>).value), [
      'haleb',
      'halea',
      'amen',
    ]);

    await tester.tap(find.byKey(const ValueKey('halea')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    final rows = await tester.runAsync(
      () => db.detectedMatchesDao.watchAll().first,
    );
    expect(rows!.single.sourceKey, detectionKey(playback));
    expect(rows.single.songId, 'halea');
  });

  test('Choose another and Identify by listening are read', () {
    expect(
      AndroidLaunchReceiver.read({
        'open': 'detected',
        'key': 'k',
        'ask': 'listen',
      }),
      isA<OpenDetected>()
          .having((o) => o.key, 'key', 'k')
          .having((o) => o.ask, 'ask', DetectedAsk.listen),
    );
    expect(
      AndroidLaunchReceiver.read({'open': 'detected', 'key': 'k', 'ask': 'x'}),
      isNull,
    );
  });
}
