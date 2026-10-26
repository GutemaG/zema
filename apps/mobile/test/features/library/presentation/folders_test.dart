import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/library/presentation/folder_screen.dart';
import 'package:zema/features/library/presentation/folders_view.dart';
import 'package:zema/features/library/presentation/widgets/folder_row.dart';
import 'package:zema/features/library/presentation/widgets/track_row.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';
import '../../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));
const _phone = '/storage/emulated/0';

/// The screen's side padding, plus a little slack.
const _leftEdge = 24.0;

List<ScannedAudio> _files() => [
  scannedAudio(1, '$_phone/Music/b.mp3', title: 'Beta'),
  scannedAudio(2, '$_phone/Music/a.mp3', title: 'Alpha'),
  scannedAudio(3, '$_phone/Music/Zema/c.mp3', title: 'Gamma'),
  scannedAudio(4, '$_phone/Telegram/Telegram Audio/d.mp3', title: 'Delta'),
  scannedAudio(5, '$_phone/Telegram/Telegram Audio/e.mp3', title: 'Epsilon'),
  scannedAudio(6, '$_phone/Download/መዝሙር/f.mp3', title: 'ሰላም'),
];

/// Pumps the app on the Folders tab (or at [location]).
Future<ZemaAudioHandler> _pump(
  WidgetTester tester, {
  List<ScannedAudio>? files,
  String? location,
  Brightness phoneBrightness = Brightness.dark,
}) async {
  final handler = fakeAudioHandler();
  await pumpZemaApp(
    tester,
    location: location ?? AppRoutes.library,
    libraryScanner: FakeLibraryScanner(files ?? _files()),
    audioHandler: handler,
    phoneBrightness: phoneBrightness,
    savedPrefs: {LibraryAccessController.explainedKey: true},
  );
  if (location == null) {
    // The tab bar scrolls: on narrow screens the tab may start off-screen.
    await tester.ensureVisible(find.text(_l10n.libraryTabFolders));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.libraryTabFolders));
    await tester.pumpAndSettle();
  }
  return handler;
}

Future<void> _open(WidgetTester tester, String name) async {
  await tester.tap(find.text(name).first);
  await tester.pumpAndSettle();
}

List<String> _titles(ZemaAudioHandler handler) => [
  for (final t in handler.snapshot.queue) t.title,
];

void main() {
  group('Folders', () {
    testWidgets('lists folders with their song count and path', (tester) async {
      await _pump(tester);

      expect(find.byType(FolderRow), findsNWidgets(4));
      expect(
        find.text('2 songs · Phone/Telegram/Telegram Audio'),
        findsOneWidget,
      );
      expect(find.text('2 songs · Phone/Music'), findsOneWidget);
      expect(find.text('1 song · Phone/Download/መዝሙር'), findsOneWidget);
    });

    testWidgets('an empty library shows C07', (tester) async {
      await _pump(tester, files: const []);

      expect(find.text(_l10n.foldersEmptyTitle), findsOneWidget);
    });

    testWidgets('a folder shows subfolders first, then its songs', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester, 'Music');

      expect(find.byType(FolderScreen), findsOneWidget);
      final sub = tester.getTopLeft(find.widgetWithText(FolderRow, 'Zema'));
      final song = tester.getTopLeft(find.widgetWithText(TrackRow, 'Alpha'));
      expect(sub.dy, lessThan(song.dy));
      // A subfolder counts everything below it and shows no path.
      expect(find.text('1 song'), findsOneWidget);
      expect(find.text(_l10n.librarySongCount(3)), findsOneWidget);
    });

    testWidgets('Play all covers the folder and everything below it', (
      tester,
    ) async {
      final handler = await _pump(tester);
      await _open(tester, 'Music');

      await tester.tap(find.text(_l10n.actionPlay));
      await tester.pumpAndSettle();

      expect(_titles(handler), ['Alpha', 'Beta', 'Gamma']);
    });

    testWidgets('tapping a song plays the folder songs from it', (
      tester,
    ) async {
      final handler = await _pump(tester);
      await _open(tester, 'Music');

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(_titles(handler), ['Alpha', 'Beta']);
      expect(handler.snapshot.current?.title, 'Beta');
    });

    testWidgets('the breadcrumb opens a parent; back returns to Folders', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester, 'Telegram Audio');
      for (final crumb in ['Phone', 'Telegram', 'Telegram Audio']) {
        expect(
          find.descendant(
            of: find.byType(FolderScreen),
            matching: find.text(crumb),
          ),
          findsWidgets,
          reason: crumb,
        );
      }

      await tester.tap(find.widgetWithText(TextButton, 'Telegram'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FolderRow, 'Telegram Audio'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Telegram'), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(FolderScreen), findsNothing);
      expect(find.byType(FoldersView), findsOneWidget);
    });

    testWidgets('a short breadcrumb starts on the left', (tester) async {
      await _pump(tester);
      await _open(tester, 'Music');

      final phone = find.widgetWithText(TextButton, 'Phone');
      expect(tester.getTopLeft(phone).dx, lessThan(_leftEdge));
    });

    testWidgets('hiding a folder removes its songs everywhere; undo', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.byTooltip(_l10n.folderMenu('Telegram Audio')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.folderHide));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FolderRow, 'Telegram Audio'), findsNothing);
      expect(find.text(_l10n.folderHidden('Telegram Audio')), findsOneWidget);
      await tester.tap(find.text(_l10n.libraryTabTracks));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.librarySongCount(4)), findsOneWidget);

      await tester.tap(find.text(_l10n.actionUndo));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.librarySongCount(6)), findsOneWidget);
    });

    testWidgets('the undo snackbar goes away on its own', (tester) async {
      await _pump(tester);
      await tester.tap(find.byTooltip(_l10n.folderMenu('Music')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.folderHide));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.actionUndo), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.actionUndo), findsNothing);
    });

    testWidgets('a folder with nothing visible shows C07', (tester) async {
      await _pump(tester, location: AppRoutes.folder('$_phone/Nope'));

      expect(find.text(_l10n.folderGoneTitle), findsOneWidget);
    });

    testWidgets('Ethiopic folder names keep the Ethiopic line height', (
      tester,
    ) async {
      await _pump(tester);

      final name = tester.widget<Text>(find.text('መዝሙር'));
      expect(name.style?.height, greaterThanOrEqualTo(1.4));
    });

    testWidgets('fits at 1.3× on a small phone in light and dark', (
      tester,
    ) async {
      useScreen(tester, size: const Size(320, 640), textScale: 1.3);
      for (final brightness in Brightness.values) {
        await _pump(tester, phoneBrightness: brightness);
        expect(tester.takeException(), isNull, reason: '$brightness list');
        await _open(tester, 'Music');
        expect(tester.takeException(), isNull, reason: '$brightness folder');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
