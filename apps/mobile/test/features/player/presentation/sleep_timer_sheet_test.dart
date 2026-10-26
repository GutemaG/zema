import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/player/data/sleep_timer.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/features/player/presentation/sleep_timer_sheet.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

final _tracks = [
  for (var i = 1; i <= 2; i++)
    Track.fromScan(i, scannedAudio(100 + i, '/m/$i.mp3', title: 'Song $i')),
];

/// Opens Now Playing with a song playing. The handler's timer is cancelled
/// when the test ends, so no timer is left pending.
Future<ZemaAudioHandler> _nowPlaying(
  WidgetTester tester, {
  Brightness phoneBrightness = Brightness.dark,
  Map<String, Object> savedPrefs = const {},
}) async {
  final handler = fakeAudioHandler();
  await pumpZemaApp(
    tester,
    location: AppRoutes.nowPlaying,
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true, ...savedPrefs},
  );
  await handler.playTracks(_tracks);
  await tester.pumpAndSettle();
  return handler;
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_l10n.sleepTitle));
  await tester.pumpAndSettle();
}

Future<void> _endTest(WidgetTester tester, ZemaAudioHandler handler) async {
  handler.cancelSleepTimer();
  await tester.pumpWidget(const SizedBox());
}

/// The option tiles shown selected.
List<String> _selected(WidgetTester tester) => [
  for (final tile in tester.widgetList<ListTile>(
    find.descendant(
      of: find.byType(SleepTimerSheet),
      matching: find.byType(ListTile),
    ),
  ))
    if (tile.selected) (tile.title! as Text).data!,
];

void main() {
  group('Sleep timer default', () {
    testWidgets('nothing is preselected by default', (tester) async {
      final handler = await _nowPlaying(tester);
      await _openSheet(tester);

      expect(_selected(tester), isEmpty);
      expect(find.byIcon(Icons.check), findsNothing);
      await _endTest(tester, handler);
    });

    testWidgets('the saved default is preselected; nothing starts', (
      tester,
    ) async {
      final handler = await _nowPlaying(
        tester,
        savedPrefs: {'sleepTimerDefault': 'minutes30'},
      );
      await _openSheet(tester);

      expect(_selected(tester), [_l10n.sleepMinutes(30)]);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, _l10n.sleepMinutes(30)),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(handler.snapshot.sleepTimer, isNull);

      // One tap starts it.
      await tester.tap(find.text(_l10n.sleepMinutes(30)));
      await tester.pumpAndSettle();
      expect(handler.snapshot.sleepTimer, isA<TimedSleep>());
      await _endTest(tester, handler);
    });

    testWidgets('end of song can be the default', (tester) async {
      final handler = await _nowPlaying(
        tester,
        savedPrefs: {'sleepTimerDefault': 'endOfSong'},
      );
      await _openSheet(tester);

      expect(_selected(tester), [_l10n.sleepEndOfSong]);
      await _endTest(tester, handler);
    });
  });

  group('Sleep timer sheet', () {
    testWidgets('offers the presets, end of song and custom', (tester) async {
      final handler = await _nowPlaying(tester);
      await _openSheet(tester);

      for (final label in [
        for (final m in SleepTimerSheet.presets) _l10n.sleepMinutes(m),
        _l10n.sleepEndOfSong,
        _l10n.sleepCustom,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text(_l10n.sleepCancel), findsNothing);
      await _endTest(tester, handler);
    });

    testWidgets('a preset starts the timer; Now Playing counts down', (
      tester,
    ) async {
      final handler = await _nowPlaying(tester);
      await _openSheet(tester);

      await tester.tap(find.text(_l10n.sleepMinutes(30)));
      await tester.pumpAndSettle();

      expect(find.byType(SleepTimerSheet), findsNothing);
      expect(handler.snapshot.sleepTimer, isA<TimedSleep>());
      expect(find.text('30:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      expect(find.text('29:50'), findsOneWidget);
      await _endTest(tester, handler);
    });

    testWidgets('while a timer runs the sheet shows the time left; cancel', (
      tester,
    ) async {
      final handler = await _nowPlaying(tester);
      handler.setSleepTimer(const Duration(minutes: 15));
      await tester.pump(const Duration(seconds: 30));
      await _openSheet(tester);

      expect(find.text(_l10n.sleepStopsIn('14:30')), findsOneWidget);

      await tester.tap(find.text(_l10n.sleepCancel));
      await tester.pumpAndSettle();

      expect(handler.snapshot.sleepTimer, isNull);
      expect(find.text('14:30'), findsNothing);
      await _endTest(tester, handler);
    });

    testWidgets('end of current song', (tester) async {
      final handler = await _nowPlaying(tester);
      await _openSheet(tester);

      await tester.tap(find.text(_l10n.sleepEndOfSong));
      await tester.pumpAndSettle();

      expect(handler.snapshot.sleepTimer, const EndOfTrackSleep());
      expect(find.text(_l10n.sleepEndOfSongShort), findsOneWidget);

      await _openSheet(tester);
      expect(find.text(_l10n.sleepStopsAtEndOfSong), findsOneWidget);
      await _endTest(tester, handler);
    });

    testWidgets('custom: Save stays disabled outside 1–180 minutes', (
      tester,
    ) async {
      final handler = await _nowPlaying(tester);
      await _openSheet(tester);
      await tester.tap(find.text(_l10n.sleepCustom));
      await tester.pumpAndSettle();

      final save = find.widgetWithText(TextButton, _l10n.actionSave);
      bool saveEnabled() => tester.widget<TextButton>(save).onPressed != null;
      final range = _l10n.sleepCustomRange(1, 180);

      expect(saveEnabled(), isFalse, reason: 'empty');
      for (final value in ['0', '181']) {
        await tester.enterText(find.byType(TextField), value);
        await tester.pump();
        expect(saveEnabled(), isFalse, reason: value);
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.decoration?.errorText, range, reason: value);
      }

      await tester.enterText(find.byType(TextField), '45');
      await tester.pump();
      expect(saveEnabled(), isTrue);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.byType(CustomSleepDialog), findsNothing);
      expect(find.byType(SleepTimerSheet), findsNothing);
      expect(find.text('45:00'), findsOneWidget);
      await _endTest(tester, handler);
    });

    testWidgets('custom only accepts digits', (tester) async {
      final handler = await _nowPlaying(tester);
      await _openSheet(tester);
      await tester.tap(find.text(_l10n.sleepCustom));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1a5');
      await tester.pump();

      expect(find.text('15'), findsOneWidget);
      await _endTest(tester, handler);
    });

    testWidgets('fits at 1.3× on a small phone in light and dark', (
      tester,
    ) async {
      useScreen(tester, size: const Size(320, 568), textScale: 1.3);
      for (final brightness in Brightness.values) {
        final handler = await _nowPlaying(tester, phoneBrightness: brightness);
        handler.setSleepTimer(const Duration(minutes: 90));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$brightness S08');
        await _openSheet(tester);
        expect(tester.takeException(), isNull, reason: '$brightness C05');
        await _endTest(tester, handler);
      }
    });
  });
}
