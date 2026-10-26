import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/features/player/presentation/queue_sheet.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

List<Track> _tracks(int count) => [
  for (var i = 1; i <= count; i++)
    Track.fromScan(i, scannedAudio(100 + i, '/m/$i.mp3', title: 'Song $i')),
];

/// Plays [count] tracks from [start] and opens the queue from Now Playing.
Future<ZemaAudioHandler> _openQueue(
  WidgetTester tester, {
  int count = 4,
  int start = 1,
  bool shuffle = false,
}) async {
  final handler = fakeAudioHandler();
  await pumpZemaApp(
    tester,
    location: AppRoutes.nowPlaying,
    audioHandler: handler,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  await handler.playTracks(_tracks(count), start: start, shuffle: shuffle);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(_l10n.queueTitle));
  await tester.pumpAndSettle();
  return handler;
}

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(QueueSheet), matching: finder);

Finder _row(String title) => _inSheet(find.widgetWithText(TrackRow, title));

List<String> _rowTitles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(
    _inSheet(find.byType(TrackRow)),
  ))
    row.track.title,
];

List<String> _queueTitles(ZemaAudioHandler handler) => [
  for (final t in handler.snapshot.queue) t.title,
];

void main() {
  group('Queue sheet', () {
    testWidgets('shows the queue with the current song highlighted', (
      tester,
    ) async {
      await _openQueue(tester);

      expect(find.byType(QueueSheet), findsOneWidget);
      expect(find.text(_l10n.queueUpNext(2)), findsOneWidget);
      expect(_rowTitles(tester), ['Song 1', 'Song 2', 'Song 3', 'Song 4']);
      final current = tester.widget<TrackRow>(_row('Song 2'));
      expect(current.isCurrent, isTrue);
      // Songs already played are dimmed.
      final played = tester.widget<Opacity>(
        find.ancestor(of: _row('Song 1'), matching: find.byType(Opacity)),
      );
      expect(played.opacity, lessThan(1));
    });

    testWidgets('dragging a song changes the play order', (tester) async {
      final handler = await _openQueue(tester);
      final handle = find.descendant(
        of: _row('Song 4'),
        matching: find.byIcon(Icons.drag_handle),
      );

      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, -TrackRow.height / 10));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_queueTitles(handler), ['Song 1', 'Song 2', 'Song 4', 'Song 3']);
      expect(_rowTitles(tester), _queueTitles(handler));
      expect(handler.snapshot.current?.title, 'Song 2');
    });

    testWidgets('swiping removes a song; undo puts it back', (tester) async {
      final handler = await _openQueue(tester);

      await tester.drag(_row('Song 3'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(_queueTitles(handler), ['Song 1', 'Song 2', 'Song 4']);
      expect(_rowTitles(tester), _queueTitles(handler));
      expect(find.text(_l10n.queueRemoved('Song 3')), findsOneWidget);

      await tester.tap(find.text(_l10n.actionUndo));
      await tester.pumpAndSettle();

      expect(_queueTitles(handler), ['Song 1', 'Song 2', 'Song 3', 'Song 4']);
      expect(_rowTitles(tester), _queueTitles(handler));
    });

    testWidgets('the undo snackbar shows on the sheet and times out', (
      tester,
    ) async {
      await _openQueue(tester);

      await tester.drag(_row('Song 3'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(_inSheet(find.text(_l10n.actionUndo)), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.actionUndo), findsNothing);
    });

    testWidgets('the current song cannot be swiped away', (tester) async {
      final handler = await _openQueue(tester);

      await tester.drag(_row('Song 2'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(_queueTitles(handler), hasLength(4));
      expect(_row('Song 2'), findsOneWidget);
    });

    testWidgets('screen readers can remove upcoming songs only', (
      tester,
    ) async {
      await _openQueue(tester);

      bool hasRemoveAction(String title) => tester
          .widgetList<Semantics>(
            find.ancestor(of: _row(title), matching: find.byType(Semantics)),
          )
          .any(
            (s) =>
                s.properties.customSemanticsActions?.keys.any(
                  (a) => a.label == _l10n.queueRemove,
                ) ??
                false,
          );

      expect(hasRemoveAction('Song 3'), isTrue);
      expect(hasRemoveAction('Song 2'), isFalse);
    });

    testWidgets('"Clear queue" removes everything after the current song', (
      tester,
    ) async {
      final handler = await _openQueue(tester);

      await tester.tap(find.text(_l10n.queueClear));
      await tester.pumpAndSettle();

      expect(_queueTitles(handler), ['Song 1', 'Song 2']);
      expect(find.text(_l10n.queueUpNext(0)), findsOneWidget);
      final clear = tester.widget<TextButton>(
        find.widgetWithText(TextButton, _l10n.queueClear),
      );
      expect(clear.onPressed, isNull);
    });

    testWidgets('tapping a song plays it', (tester) async {
      final handler = await _openQueue(tester);

      await tester.tap(_row('Song 4'));
      await tester.pumpAndSettle();

      expect(handler.snapshot.current?.title, 'Song 4');
      expect(tester.widget<TrackRow>(_row('Song 4')).isCurrent, isTrue);
    });

    testWidgets('with shuffle on it shows the shuffled order', (tester) async {
      final handler = await _openQueue(tester, count: 8, start: 0);

      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      await tester.pumpAndSettle();

      expect(_queueTitles(handler), isNot(_tracks(8).map((t) => t.title)));
      expect(
        _rowTitles(tester),
        _queueTitles(handler).take(_rowTitles(tester).length),
      );
    });

    testWidgets('a 1,000-song queue opens at the current song', (tester) async {
      await _openQueue(tester, count: 1000, start: 900);

      expect(_row('Song 901'), findsOneWidget);
      expect(_row('Song 1'), findsNothing);
      expect(
        tester.getTopLeft(_row('Song 901')).dy,
        lessThan(tester.getBottomLeft(find.byType(QueueSheet)).dy),
      );
    });

    testWidgets('fits at 1.3× on a small phone', (tester) async {
      useScreen(tester, size: const Size(320, 568), textScale: 1.3);
      await _openQueue(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
