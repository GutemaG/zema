import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/identify/application/listen_controller.dart';
import 'package:zema/features/identify/presentation/listen_lyrics_screen.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/lyrics/presentation/lyrics_view.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

ListenFound _found(Track track, Duration position, {bool sure = true}) =>
    ListenFound(
      track: track,
      match: AudioMatch(
        recordingId: '${track.id}',
        position: position,
        score: 30,
        playbackSpeed: 1,
        ambiguousPosition: !sure,
      ),
      startedAt: clock.now(),
      sure: sure,
    );

class _FakeListen extends ListenController {
  _FakeListen(this.first, this.next);

  final ListenState Function() first;
  final ListenState Function() next;
  var listened = 0;

  @override
  ListenState build() => first();

  @override
  Future<void> listen() async {
    listened++;
    state = const Listening(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    state = next();
  }
}

void main() {
  late ZemaDatabase db;
  late Track track;
  late _FakeListen fake;

  Future<void> open(
    WidgetTester tester, {
    required ListenState Function() first,
    ListenState Function()? next,
  }) async {
    useScreen(tester, size: const Size(400, 860));
    db = memoryDatabase();
    fake = _FakeListen(first, next ?? first);
    await pumpZemaApp(
      tester,
      location: AppRoutes.library,
      libraryScanner: FakeLibraryScanner([
        scannedAudio(1, '/m/0.mp3', title: 'Galatoomi'),
      ]),
      database: db,
      savedPrefs: {LibraryAccessController.explainedKey: true},
      overrides: [listenControllerProvider.overrideWith(() => fake)],
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    track = (await tester.runAsync(db.libraryDao.allTracks))!.single;
  }

  Future<void> show(WidgetTester tester) async {
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push(AppRoutes.listenLyrics),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  int? current(WidgetTester tester) =>
      tester.widget<LyricsLines>(find.byType(LyricsLines)).current;

  testWidgets('the lyrics follow the song that was heard', (tester) async {
    await open(
      tester,
      first: () => _found(track, const Duration(seconds: 1)),
      next: () => _found(track, const Duration(seconds: 11)),
    );
    await show(tester);
    expect(find.byType(ListenLyricsScreen), findsOneWidget);
    expect(find.text('Waaqayyo nu jaallatee'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(current(tester), 0);
    await tester.pump(const Duration(seconds: 4));
    expect(current(tester), 1);
    expect(find.text(_l10n.listenUnsure), findsNothing);

    await tester.tap(find.text(_l10n.listenResync));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(_l10n.listenListening), findsOneWidget);
    expect(current(tester), 1, reason: 'kept while listening again');
    await tester.pump(const Duration(milliseconds: 400));
    expect(fake.listened, 1);
    expect(current(tester), 2);
  });

  testWidgets('a re-sync that hears nothing keeps the place', (tester) async {
    await open(
      tester,
      first: () => _found(track, const Duration(seconds: 7)),
      next: () => const ListenNotFound(),
    );
    await show(tester);
    expect(current(tester), 1);

    await tester.tap(find.text(_l10n.listenResync));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(_l10n.listenResyncFailed), findsOneWidget);
    expect(current(tester), 1);
  });

  testWidgets('an unsure place says so', (tester) async {
    await open(
      tester,
      first: () => _found(track, const Duration(seconds: 11), sure: false),
    );
    await show(tester);
    expect(find.text(_l10n.listenUnsure), findsOneWidget);
  });

  testWidgets('the end of the song offers to listen again', (tester) async {
    await open(tester, first: () => _found(track, const Duration(seconds: 58)));
    await show(tester);
    expect(find.text(_l10n.listenSongEnded), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text(_l10n.listenSongEnded), findsOneWidget);
    expect(find.text(_l10n.listenAgain), findsOneWidget);
  });
}
