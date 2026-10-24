import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/application/track_sort_provider.dart';
import 'package:zema/features/library/presentation/widgets/alphabet_scroller.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

List<ScannedAudio> _files() => [
  scannedAudio(
    1,
    '/m/a.mp3',
    title: 'Kidus',
    artist: 'Zerfe',
    durationMs: 90000,
  ),
  scannedAudio(
    2,
    '/m/b.mp3',
    title: 'Amlak',
    artist: 'Mahlet',
    durationMs: 40000,
  ),
  scannedAudio(
    3,
    '/m/c.mp3',
    title: 'ሰላም ለኪ',
    artist: 'ዘማሪት',
    durationMs: 120000,
  ),
  scannedAudio(4, '/m/d.mp3', title: 'Tselot', durationMs: 60000),
];

Future<ZemaAudioHandler> _pumpTracks(
  WidgetTester tester, {
  List<ScannedAudio>? files,
  Map<String, Object> savedPrefs = const {},
}) async {
  final handler = fakeAudioHandler();
  await pumpZemaApp(
    tester,
    location: AppRoutes.library,
    libraryScanner: FakeLibraryScanner(files ?? _files()),
    audioHandler: handler,
    savedPrefs: {LibraryAccessController.explainedKey: true, ...savedPrefs},
  );
  return handler;
}

List<String> _visibleTitles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
    row.track.title,
];

void main() {
  group('Tracks', () {
    testWidgets('shows top tabs with Tracks first and placeholders after', (
      tester,
    ) async {
      await _pumpTracks(tester);

      for (final name in [
        _l10n.libraryTabTracks,
        _l10n.libraryTabFolders,
        _l10n.libraryTabAlbums,
      ]) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text(_l10n.librarySongCount(4)), findsOneWidget);

      await tester.tap(find.text(_l10n.libraryTabFolders));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.libraryTabComingSoon), findsOneWidget);
    });

    testWidgets('sorts by title by default with an alphabet strip', (
      tester,
    ) async {
      await _pumpTracks(tester);

      expect(_visibleTitles(tester), ['Amlak', 'Kidus', 'Tselot', 'ሰላም ለኪ']);
      final strip = tester.widget<AlphabetScroller>(
        find.byType(AlphabetScroller),
      );
      expect(strip.letters, ['A', 'K', 'T', 'ሰ']);
    });

    testWidgets('search filters as you type and can be cleared', (
      tester,
    ) async {
      await _pumpTracks(tester);

      await tester.enterText(find.byType(TextField), 'zer');
      await tester.pump();
      expect(_visibleTitles(tester), ['Kidus']);
      expect(find.text(_l10n.librarySongCount(1)), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nothing like this');
      await tester.pump();
      expect(find.text(_l10n.libraryNoResultsTitle), findsOneWidget);

      await tester.tap(find.byTooltip(_l10n.libraryClearSearch));
      await tester.pump();
      expect(_visibleTitles(tester), hasLength(4));
    });

    testWidgets('changing the sort is applied and remembered', (tester) async {
      await _pumpTracks(tester);

      await tester.tap(find.byTooltip(_l10n.librarySortTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.sortDuration));
      await tester.pumpAndSettle();
      expect(_visibleTitles(tester), ['Amlak', 'Tselot', 'Kidus', 'ሰላም ለኪ']);
      // Not a text sort: no alphabet strip.
      expect(find.byType(AlphabetScroller), findsNothing);

      await tester.tap(find.byTooltip(_l10n.librarySortTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.sortDescending));
      await tester.pumpAndSettle();
      expect(_visibleTitles(tester).first, 'ሰላም ለኪ');

      final prefs = await savedPreferences();
      expect(prefs.getString(TrackSortController.fieldKey), 'duration');
      expect(prefs.getBool(TrackSortController.descendingKey), isTrue);
    });

    testWidgets('a saved sort is used on the next launch', (tester) async {
      await _pumpTracks(
        tester,
        savedPrefs: {
          TrackSortController.fieldKey: 'artist',
          TrackSortController.descendingKey: false,
        },
      );

      expect(_visibleTitles(tester), ['Amlak', 'Kidus', 'ሰላም ለኪ', 'Tselot']);
    });

    testWidgets('tapping a row plays the visible list from that row', (
      tester,
    ) async {
      final handler = await _pumpTracks(tester);
      await tester.enterText(find.byType(TextField), 'l');
      await tester.pump();
      final visible = _visibleTitles(tester);
      expect(visible, ['Amlak', 'Tselot']);

      await tester.tap(find.text('Tselot'));
      await tester.pumpAndSettle();

      expect(handler.snapshot.queue.map((t) => t.title), visible);
      expect(handler.snapshot.current?.title, 'Tselot');
      expect(handler.snapshot.playing, isTrue);
      final row = tester.widget<TrackRow>(
        find.ancestor(of: find.text('Tselot'), matching: find.byType(TrackRow)),
      );
      expect(row.isCurrent, isTrue);
    });

    testWidgets('Play plays the list in order, Shuffle shuffled', (
      tester,
    ) async {
      final handler = await _pumpTracks(tester);

      await tester.tap(find.text(_l10n.actionPlay));
      await tester.pumpAndSettle();
      expect(handler.snapshot.current?.title, 'Amlak');
      expect(handler.snapshot.shuffle, isFalse);

      await tester.tap(find.byTooltip(_l10n.actionShuffle));
      await tester.pumpAndSettle();
      expect(handler.snapshot.shuffle, isTrue);
      expect(handler.snapshot.queue, hasLength(4));
    });

    testWidgets('the alphabet strip jumps to a section', (tester) async {
      final files = [
        for (var i = 0; i < 40; i++)
          scannedAudio(i + 1, '/m/a$i.mp3', title: 'A song $i'),
        for (var i = 0; i < 40; i++)
          scannedAudio(i + 100, '/m/z$i.mp3', title: 'Z song $i'),
      ];
      await _pumpTracks(tester, files: files);
      expect(find.text('Z song 0'), findsNothing);

      tester
          .widget<AlphabetScroller>(find.byType(AlphabetScroller))
          .onSelected('Z');
      await tester.pumpAndSettle();

      expect(find.text('Z song 0'), findsOneWidget);
    });

    testWidgets('dragging along the strip selects letters', (tester) async {
      final picked = <String>[];
      await pumpThemed(
        tester,
        SizedBox(
          height: 300,
          child: AlphabetScroller(
            letters: const ['A', 'B', 'C'],
            onSelected: picked.add,
          ),
        ),
      );
      final strip = tester.getRect(find.byType(AlphabetScroller));

      // A timed drag moves in small steps, like a finger.
      await tester.timedDragFrom(
        strip.topCenter + const Offset(0, 5),
        Offset(0, strip.height - 10),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      expect(picked, ['A', 'B', 'C']);
    });

    testWidgets('rows fit at 1.3× with Ethiopic text in light and dark', (
      tester,
    ) async {
      useScreen(tester, size: const Size(320, 640), textScale: 1.3);
      for (final brightness in Brightness.values) {
        await pumpZemaApp(
          tester,
          location: AppRoutes.library,
          libraryScanner: FakeLibraryScanner(_files()),
          phoneBrightness: brightness,
          savedPrefs: {LibraryAccessController.explainedKey: true},
        );
        expect(tester.takeException(), isNull, reason: '$brightness');
        expect(
          tester.getSize(find.byType(TrackRow).first).height,
          TrackRow.height,
        );
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
