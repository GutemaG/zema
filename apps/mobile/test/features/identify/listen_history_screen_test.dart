import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/identify/data/microphone.dart';
import 'package:zema/features/identify/presentation/listen_history_screen.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/player/presentation/now_playing_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

class _SilentMicrophone implements Microphone {
  @override
  int get sampleRate => 44100;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Stream<Float32List>> start() async => const Stream.empty();

  @override
  Future<void> stop() async {}
}

void main() {
  late ZemaDatabase db;
  late Map<String, Track> byTitle;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester tester, {String? at}) async {
    useScreen(tester, size: const Size(400, 860));
    db = memoryDatabase();
    await pumpZemaApp(
      tester,
      location: AppRoutes.library,
      libraryScanner: FakeLibraryScanner([
        scannedAudio(1, '/m/1.mp3', title: 'One', artist: 'Choir'),
        scannedAudio(2, '/m/2.mp3', title: 'Two'),
      ]),
      database: db,
      savedPrefs: {LibraryAccessController.explainedKey: true},
      overrides: [microphoneProvider.overrideWithValue(_SilentMicrophone())],
    );
    await settle(tester);
    final tracks = (await tester.runAsync(db.libraryDao.allTracks))!;
    byTitle = {for (final t in tracks) t.title: t};
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push(at ?? AppRoutes.listenHistory),
    );
    await settle(tester);
  }

  Future<void> identified(
    WidgetTester tester,
    String title,
    DateTime at,
  ) async {
    await tester.runAsync(() => db.identifiedDao.add(byTitle[title]!.id, at));
  }

  testWidgets('empty History says what will show there', (tester) async {
    await open(tester);
    expect(find.text(_l10n.listenHistoryEmptyTitle), findsOneWidget);
    expect(find.text(_l10n.listenHistoryClear), findsNothing);
  });

  testWidgets('songs show newest first, and can be removed', (tester) async {
    await open(tester);
    await identified(tester, 'One', DateTime(DateTime.now().year, 3, 4, 9, 5));
    await identified(
      tester,
      'Two',
      DateTime(DateTime.now().year, 3, 4, 10, 30),
    );
    await settle(tester);

    final one = tester.getTopLeft(find.text('One')).dy;
    final two = tester.getTopLeft(find.text('Two')).dy;
    expect(two, lessThan(one));
    expect(find.textContaining('Choir · '), findsOneWidget);
    expect(find.textContaining('Mar 4, 9:05'), findsOneWidget);

    await tester.tap(find.byTooltip(_l10n.listenHistoryRemove).first);
    await settle(tester);
    expect(find.text('Two'), findsNothing);
    expect(find.text('One'), findsOneWidget);

    await tester.tap(find.text(_l10n.listenHistoryClear));
    await settle(tester);
    await tester.tap(find.text(_l10n.actionCancel));
    await settle(tester);
    expect(find.text('One'), findsOneWidget);

    await tester.tap(find.text(_l10n.listenHistoryClear));
    await settle(tester);
    await tester.tap(find.text(_l10n.listenHistoryClear).last);
    await settle(tester);
    expect(find.text(_l10n.listenHistoryEmptyTitle), findsOneWidget);
  });

  testWidgets('tapping a song plays it', (tester) async {
    await open(tester);
    await identified(
      tester,
      'Two',
      DateTime(DateTime.now().year, 3, 4, 10, 30),
    );
    await settle(tester);

    await tester.tap(find.text('Two'));
    await settle(tester);
    expect(find.byType(NowPlayingScreen), findsOneWidget);
    expect(find.text('Two'), findsWidgets);
  });

  testWidgets('Listen opens History', (tester) async {
    await open(tester, at: AppRoutes.listen);
    await tester.tap(find.byTooltip(_l10n.listenHistoryTitle));
    await settle(tester);
    expect(find.byType(ListenHistoryScreen), findsOneWidget);
  });
}
