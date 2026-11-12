import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/identify/presentation/listen_screen.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/l10n/generated/app_localizations.dart';

import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  Future<void> openAt(WidgetTester tester, String location) async {
    useScreen(tester, size: const Size(400, 860));
    await pumpZemaApp(
      tester,
      location: location,
      libraryScanner: FakeLibraryScanner([
        scannedAudio(1, '/m/0.mp3', title: 'Galatoomi'),
      ]),
      savedPrefs: {LibraryAccessController.explainedKey: true},
    );
  }

  Future<void> expectListenOpens(WidgetTester tester, Finder button) async {
    await tester.tap(button);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ListenScreen), findsOneWidget);
  }

  testWidgets('Search opens Listen', (tester) async {
    await openAt(tester, AppRoutes.search);
    await expectListenOpens(tester, find.byTooltip(_l10n.listenTooltip));
  });

  testWidgets('Now Playing with nothing playing offers Listen', (tester) async {
    await openAt(tester, AppRoutes.nowPlaying);
    expect(find.text(_l10n.playerNothingTitle), findsOneWidget);
    await expectListenOpens(tester, find.text(_l10n.listenTitle));
  });
}
