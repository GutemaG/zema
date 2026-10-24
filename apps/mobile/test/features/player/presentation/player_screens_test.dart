import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/features/player/presentation/mini_player.dart';
import 'package:zema/features/player/presentation/now_playing_screen.dart';
import 'package:zema/features/player/presentation/player_progress.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

final _tracks = [
  Track.fromScan(
    1,
    scannedAudio(11, '/m/a.mp3', title: 'Kidus', artist: 'Zerfe'),
  ),
  Track.fromScan(
    2,
    scannedAudio(12, '/m/b.mp3', title: 'ሰላም ለኪ', artist: 'ዘማሪት'),
  ),
];

/// Pumps the app with a fake player; plays [play] tracks when given.
Future<(ZemaAudioHandler, FakeAudioBackend)> _pump(
  WidgetTester tester, {
  bool play = true,
  String location = AppRoutes.home,
  Brightness phoneBrightness = Brightness.dark,
}) async {
  final backend = FakeAudioBackend();
  final handler = fakeAudioHandler(backend);
  await pumpZemaApp(
    tester,
    location: location,
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  if (play) {
    await handler.playTracks(_tracks);
    await tester.pumpAndSettle();
  }
  return (handler, backend);
}

void main() {
  group('Mini player', () {
    testWidgets('is hidden while nothing is loaded', (tester) async {
      await _pump(tester, play: false);

      expect(find.text('Kidus'), findsNothing);
      expect(find.byTooltip(_l10n.playerNext), findsNothing);
    });

    testWidgets('shows the song above the navigation on every tab', (
      tester,
    ) async {
      await _pump(tester);

      for (final tab in ['Home', 'Search', 'Library', 'Contribute']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(MiniPlayer),
            matching: find.text('Kidus'),
          ),
          findsOneWidget,
          reason: tab,
        );
      }
    });

    testWidgets('play/pause and next control the player', (tester) async {
      final (handler, _) = await _pump(tester);

      await tester.tap(find.byTooltip(_l10n.playerPause));
      await tester.pumpAndSettle();
      expect(handler.snapshot.playing, isFalse);
      expect(find.byTooltip(_l10n.playerPlay), findsOneWidget);

      await tester.tap(find.byTooltip(_l10n.playerNext));
      await tester.pumpAndSettle();
      expect(handler.snapshot.current?.title, 'ሰላም ለኪ');
    });

    testWidgets('is one labeled button for screen readers', (tester) async {
      await _pump(tester);

      expect(
        find.bySemanticsLabel(_l10n.playerMiniLabel('Kidus', 'Zerfe')),
        findsOneWidget,
      );
    });

    testWidgets('shows progress as the song plays', (tester) async {
      final (_, backend) = await _pump(tester);

      backend.advanceTo(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      final line = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byType(PlayerProgressLine),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(line.value, closeTo(0.5, 0.01));
    });

    testWidgets('tapping it opens Now Playing; back closes it', (tester) async {
      await _pump(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(MiniPlayer),
          matching: find.text('Kidus'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      await tester.tap(find.byTooltip(_l10n.playerClose));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsNothing);
    });
  });

  group('Now Playing', () {
    testWidgets('shows the song, the controls and "No lyrics yet"', (
      tester,
    ) async {
      await _pump(tester, location: AppRoutes.nowPlaying);

      expect(find.text('Kidus'), findsOneWidget);
      expect(find.text('Zerfe'), findsOneWidget);
      expect(find.text(_l10n.playerNoLyrics), findsOneWidget);
      for (final tooltip in [
        _l10n.playerShuffleOff,
        _l10n.playerPrevious,
        _l10n.playerPause,
        _l10n.playerNext,
        _l10n.playerRepeatOff,
      ]) {
        expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
      }
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('-1:00'), findsOneWidget);
    });

    testWidgets('shuffle and repeat change and show their state', (
      tester,
    ) async {
      final (handler, _) = await _pump(tester, location: AppRoutes.nowPlaying);

      await tester.tap(find.byTooltip(_l10n.playerShuffleOff));
      await tester.pumpAndSettle();
      expect(handler.snapshot.shuffle, isTrue);
      expect(find.byTooltip(_l10n.playerShuffleOn), findsOneWidget);

      // Off → all → one → off; the tooltip always names the current mode.
      for (final (current, next, repeat) in [
        (_l10n.playerRepeatOff, _l10n.playerRepeatAll, QueueRepeat.all),
        (_l10n.playerRepeatAll, _l10n.playerRepeatOne, QueueRepeat.one),
        (_l10n.playerRepeatOne, _l10n.playerRepeatOff, QueueRepeat.off),
      ]) {
        await tester.tap(find.byTooltip(current));
        await tester.pumpAndSettle();
        expect(handler.snapshot.repeat, repeat);
        expect(find.byTooltip(next), findsOneWidget);
      }
    });

    testWidgets('previous and next move through the queue', (tester) async {
      final (handler, _) = await _pump(tester, location: AppRoutes.nowPlaying);

      await tester.tap(find.byTooltip(_l10n.playerNext));
      await tester.pumpAndSettle();
      expect(find.text('ሰላም ለኪ'), findsOneWidget);

      await tester.tap(find.byTooltip(_l10n.playerPrevious));
      await tester.pumpAndSettle();
      expect(handler.snapshot.current?.title, 'Kidus');
    });

    testWidgets('the seek label follows the drag; audio seeks on release', (
      tester,
    ) async {
      final (_, backend) = await _pump(tester, location: AppRoutes.nowPlaying);
      final slider = find.byType(Slider);
      final rect = tester.getRect(slider);

      final gesture = await tester.startGesture(
        rect.centerLeft + const Offset(24, 0),
      );
      await gesture.moveTo(rect.center);
      await tester.pump();
      expect(backend.position, Duration.zero);
      expect(find.text('0:30'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(backend.position.inSeconds, closeTo(30, 2));
    });

    testWidgets('the seek bar announces position of duration', (tester) async {
      final (_, backend) = await _pump(tester, location: AppRoutes.nowPlaying);
      backend.advanceTo(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      final seek = find.bySemanticsLabel(RegExp(_l10n.playerSeek));
      expect(seek, findsOneWidget);
      // The slider's node is merged into the labeled one: one focus stop.
      final data = tester.getSemantics(seek).getSemanticsData();
      expect(data.value, _l10n.playerTrackPosition('0:30', '1:00'));
      expect(data.flagsCollection.isSlider, isTrue);
    });

    testWidgets('a fast swipe down closes it', (tester) async {
      await _pump(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(MiniPlayer),
          matching: find.text('Kidus'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.text(_l10n.playerNoLyrics),
        const Offset(0, 400),
        1500,
      );
      await tester.pumpAndSettle();

      expect(find.byType(NowPlayingScreen), findsNothing);
    });

    testWidgets('thin progress uses accent in light mode, gold in dark', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await _pump(
          tester,
          location: AppRoutes.nowPlaying,
          phoneBrightness: brightness,
        );
        final context = tester.element(find.byType(SeekBar));
        final colors = context.zemaColors;
        expect(
          progressColor(context),
          brightness == Brightness.dark ? colors.primary : colors.accent,
        );
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('fits at 1.3× on a small phone in light and dark', (
      tester,
    ) async {
      useScreen(tester, size: const Size(320, 568), textScale: 1.3);
      for (final brightness in Brightness.values) {
        await _pump(
          tester,
          location: AppRoutes.nowPlaying,
          phoneBrightness: brightness,
        );
        expect(tester.takeException(), isNull, reason: '$brightness');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a skipped song shows a snackbar', (tester) async {
      final backend = FakeAudioBackend()..unplayable.add(_tracks[0].uri);
      final handler = fakeAudioHandler(backend);
      await pumpZemaApp(tester, audioHandler: handler);

      await handler.playTracks(_tracks);
      await tester.pumpAndSettle();

      expect(find.text(_l10n.playerUnplayable('Kidus')), findsOneWidget);
      expect(handler.snapshot.current?.title, 'ሰላም ለኪ');
    });
  });
}
