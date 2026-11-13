import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/contribute/presentation/lyrics_step.dart';
import 'package:zema/features/identify/application/listen_controller.dart';
import 'package:zema/features/identify/application/quick_listen.dart';
import 'package:zema/features/identify/data/microphone.dart';
import 'package:zema/features/identify/data/quick_launch.dart';
import 'package:zema/features/identify/presentation/listen_history_screen.dart';
import 'package:zema/features/identify/presentation/listen_screen.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

class _Host implements QuickListenHost {
  OpenListenMatch? opened;
  var closed = 0;

  @override
  Future<void> openApp(OpenListenMatch match) async => opened = match;

  @override
  Future<void> close() async => closed++;
}

class _Launches implements LaunchReceiver {
  _Launches([this.initial]);

  final LaunchRequest? initial;
  final controller = StreamController<LaunchRequest>.broadcast();

  @override
  Future<LaunchRequest?> takeInitial() async => initial;

  @override
  Stream<LaunchRequest> get launches => controller.stream;
}

class _Widget implements HomeWidget {
  final shown = <String?>[];

  @override
  Future<void> showLast({String? title, String? artist}) async =>
      shown.add(title);
}

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

class _FakeListen extends ListenController {
  _FakeListen(this.first);

  final ListenState Function() first;
  var listened = 0;

  @override
  ListenState build() => first();

  @override
  Future<void> listen() async => listened++;
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

  Future<void> open(
    WidgetTester tester, {
    List<Override> overrides = const [],
    Size size = const Size(400, 860),
    double textScale = 1,
  }) async {
    useScreen(tester, size: size, textScale: textScale);
    db = memoryDatabase();
    await pumpZemaApp(
      tester,
      location: AppRoutes.library,
      libraryScanner: FakeLibraryScanner([
        scannedAudio(1, '/m/1.mp3', title: 'One'),
        scannedAudio(2, '/m/2.mp3', title: 'Two', artist: 'Choir'),
      ]),
      database: db,
      savedPrefs: {LibraryAccessController.explainedKey: true},
      overrides: [
        microphoneProvider.overrideWithValue(_SilentMicrophone()),
        ...overrides,
      ],
    );
    await settle(tester);
    final tracks = (await tester.runAsync(db.libraryDao.allTracks))!;
    byTitle = {for (final t in tracks) t.title: t};
  }

  void push(WidgetTester tester, String location) => unawaited(
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(location),
  );

  ListenFound found(Track track) => ListenFound(
    track: track,
    match: AudioMatch(
      recordingId: '${track.id}',
      position: const Duration(seconds: 12),
      score: 25,
      playbackSpeed: 1,
      ambiguousPosition: false,
    ),
    startedAt: DateTime(2026, 11, 12, 10),
  );

  testWidgets('over the lock screen, Listen starts by itself and hands the '
      'song to the app', (tester) async {
    final host = _Host();
    late _FakeListen fake;
    await open(
      tester,
      overrides: [
        quickListenHostProvider.overrideWithValue(host),
        listenControllerProvider.overrideWith(
          () => fake = _FakeListen(() => found(byTitle['Two']!)),
        ),
      ],
    );
    push(tester, AppRoutes.listen);
    await settle(tester);

    expect(fake.listened, 1);
    expect(find.byTooltip(_l10n.listenHistoryTitle), findsNothing);
    expect(find.text(_l10n.listenShowLyrics), findsNothing);
    expect(find.text(_l10n.listenPlayFromHere), findsNothing);

    await tester.tap(find.text(_l10n.listenOpenInApp));
    await settle(tester);
    expect(host.opened?.trackId, byTitle['Two']!.id);
    expect(host.opened?.position, const Duration(seconds: 12));
    expect(host.opened?.startedAt, DateTime(2026, 11, 12, 10));

    await tester.tap(find.byTooltip(_l10n.playerClose));
    await settle(tester);
    expect(host.closed, 1);
  });

  testWidgets('the widget opens History in the app', (tester) async {
    await open(
      tester,
      overrides: [
        launchReceiverProvider.overrideWithValue(
          _Launches(const OpenListenHistory()),
        ),
      ],
    );
    expect(find.byType(ListenHistoryScreen), findsOneWidget);
  });

  testWidgets('a song handed over from the lock screen opens on Listen', (
    tester,
  ) async {
    final launches = _Launches();
    await open(
      tester,
      overrides: [launchReceiverProvider.overrideWithValue(launches)],
    );
    final match = found(byTitle['Two']!).toLaunch()!;
    launches.controller.add(match);
    await settle(tester);

    expect(find.byType(ListenScreen), findsOneWidget);
    expect(find.text('Two'), findsWidgets);
    expect(find.text(_l10n.listenShowLyrics), findsOneWidget);
  });

  testWidgets('the widget shows the last song identified', (tester) async {
    final widget = _Widget();
    await open(
      tester,
      overrides: [homeWidgetProvider.overrideWithValue(widget)],
    );
    expect(widget.shown, [null]);

    await tester.runAsync(
      () => db.identifiedDao.add(byTitle['Two']!.id, DateTime(2026)),
    );
    await settle(tester);
    expect(widget.shown.last, 'Two');

    await tester.runAsync(db.identifiedDao.clear);
    await settle(tester);
    expect(widget.shown.last, isNull);
  });

  testWidgets('a song found fits a small phone with large text', (
    tester,
  ) async {
    await open(
      tester,
      size: const Size(360, 640),
      textScale: 1.3,
      overrides: [
        listenControllerProvider.overrideWith(
          () => _FakeListen(() => found(byTitle['Two']!)),
        ),
      ],
    );
    push(tester, AppRoutes.listen);
    await settle(tester);
    expect(find.text(_l10n.listenShowLyrics), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a song not found can be added', (tester) async {
    await open(
      tester,
      overrides: [
        listenControllerProvider.overrideWith(
          () => _FakeListen(() => const ListenNotFound()),
        ),
      ],
    );
    push(tester, AppRoutes.listen);
    await settle(tester);

    await tester.tap(find.text(_l10n.listenAddThisSong));
    await settle(tester);
    expect(find.byType(LyricsStep), findsOneWidget);
    final drafts = (await tester.runAsync(() => db.select(db.drafts).get()))!;
    expect(drafts, hasLength(1));
  });

  testWidgets('over the lock screen, a song not found is not offered to add', (
    tester,
  ) async {
    await open(
      tester,
      overrides: [
        quickListenHostProvider.overrideWithValue(_Host()),
        listenControllerProvider.overrideWith(
          () => _FakeListen(() => const ListenNotFound()),
        ),
      ],
    );
    push(tester, AppRoutes.listen);
    await settle(tester);
    expect(find.text(_l10n.actionTryAgain), findsOneWidget);
    expect(find.text(_l10n.listenAddThisSong), findsNothing);
  });
}
