import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/detection/application/detected_song.dart';
import 'package:zema/features/detection/application/detection_providers.dart';
import 'package:zema/features/detection/application/lyrics_overlay_sync.dart';
import 'package:zema/features/detection/data/lyrics_overlay.dart';
import 'package:zema/features/detection/data/playback_detector.dart';
import 'package:zema/features/detection/presentation/detected_lyrics_screen.dart';
import 'package:zema/features/home/presentation/widgets/now_detected_card.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/pump_app.dart';

class _Overlay extends NoLyricsOverlay {
  @override
  Future<bool> canShow() async => true;
}

CatalogEntry _entry(String id, String title) => CatalogEntry(
  id: id,
  title: title,
  artist: 'Choir',
  synced: true,
  version: 1,
  approvedAt: DateTime.utc(2026, 10, 1),
);

final _playback = DetectedPlayback(
  source: 'com.google.android.youtube',
  state: DetectedState.paused,
  title: 'ሰላም ለዚህ ቤት | Official',
  duration: const Duration(minutes: 4),
  position: const Duration(minutes: 1),
  positionUpdatedAt: clock.now(),
);

Future<void> _pumpHome(
  WidgetTester tester,
  List<Override> overrides, {
  ZemaDatabase? database,
}) => pumpZemaApp(
  tester,
  database: database,
  libraryScanner: FakeLibraryScanner([scannedAudio(1, '/m/1.mp3')]),
  savedPrefs: {LibraryAccessController.explainedKey: true},
  overrides: overrides,
);

void main() {
  testWidgets('a matched song floats on tap and opens its lyrics', (
    tester,
  ) async {
    useScreen(tester, size: const Size(400, 1000));
    final match = DetectedMatch(
      _playback,
      song: _entry('selam', 'ሰላም ለዚህ ቤት'),
      how: DetectedHow.title,
    );
    await _pumpHome(tester, [
      otherAppsSupportedProvider.overrideWithValue(true),
      lyricsOverlayProvider.overrideWithValue(_Overlay()),
      detectedSongProvider.overrideWithValue(match),
      detectedLyricsProvider.overrideWith(
        (ref, id) async => DetectedLyrics(
          song: Song(id: id, title: 'ሰላም ለዚህ ቤት', sections: const []),
          lines: const [OverlayLine('ሰላም', at: Duration.zero)],
          sung: const [],
        ),
      ),
    ]);

    expect(find.byType(NowDetectedCard), findsOneWidget);
    expect(find.text('Now detected'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NowDetectedCard),
        matching: find.text('ሰላም ለዚህ ቤት'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.descendant(
              of: find.byType(NowDetectedCard),
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .value,
      0.25,
    );

    await tester.tap(find.text('Show floating lyrics'));
    await tester.pumpAndSettle();
    expect(
      find.text('The lyrics will float over YouTube when you go back to it'),
      findsOneWidget,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NowDetectedCard)),
    );
    expect(container.read(overlayChoicesProvider)[match.key], isTrue);

    await tester.tap(find.text('Open lyrics'));
    await tester.pumpAndSettle();
    expect(find.byType(DetectedLyricsScreen), findsOneWidget);
    expect(find.text('Following YouTube'), findsOneWidget);
  });

  testWidgets('an unsure song asks, and Yes remembers it', (tester) async {
    useScreen(tester, size: const Size(400, 1000));
    final unsure = DetectedUnsure(
      _playback,
      candidates: [_entry('selam', 'ሰላም ለዚህ ቤት')],
    );
    final db = memoryDatabase();
    await _pumpHome(tester, [
      detectedSongProvider.overrideWithValue(unsure),
    ], database: db);

    expect(find.text('Is this ሰላም ለዚህ ቤት?'), findsOneWidget);
    expect(find.text('Open lyrics'), findsNothing);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    final rows = (await tester.runAsync(
      () => db.detectedMatchesDao.watchAll().first,
    ))!;
    expect(rows.single.songId, 'selam');
  });
}
