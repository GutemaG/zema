import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/presentation/backup_screen.dart';
import 'package:zema/features/account/presentation/sign_in_screen.dart';
import 'package:zema/features/account/presentation/widgets/sign_in_prompt.dart';
import 'package:zema/features/library/application/library_access_controller.dart';
import 'package:zema/features/player/presentation/mini_player.dart';
import 'package:zema/features/player/presentation/now_playing_screen.dart';
import 'package:zema/features/settings/presentation/settings_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  late FakeAuthRepository auth;
  late FakeGoogleAccountPicker picker;

  setUp(() {
    auth = FakeAuthRepository();
    picker = FakeGoogleAccountPicker();
  });

  Future<void> start(
    WidgetTester tester, {
    bool withPicker = true,
    String location = AppRoutes.settings,
    FakeLibraryScanner? scanner,
  }) => pumpZemaApp(
    tester,
    location: location,
    auth: auth,
    googlePicker: withPicker ? picker : null,
    libraryScanner: scanner,
    savedPrefs: {
      AccountChoiceController.key: true,
      LibraryAccessController.explainedKey: true,
    },
  );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openAccountBackup(WidgetTester tester) =>
      tap(tester, find.text(_l10n.settingsAccountBackup));

  group('Settings → Account & backup', () {
    testWidgets('is hidden when the build has no sign-in', (tester) async {
      await start(tester, withPicker: false);

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        find.text(_l10n.settingsSectionAccount.toUpperCase()),
        findsNothing,
      );
      expect(find.text(_l10n.settingsAccountBackup), findsNothing);
    });

    testWidgets('a guest gets C09: why, Sign in and Not now', (tester) async {
      await start(tester);
      expect(
        find.text(_l10n.settingsSectionAccount.toUpperCase()),
        findsOneWidget,
      );

      await openAccountBackup(tester);

      expect(find.byType(SignInPrompt), findsOneWidget);
      expect(find.text(_l10n.signInPromptTitle), findsOneWidget);
      expect(find.text(_l10n.backupSignInReason), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, _l10n.accountSignIn),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextButton, _l10n.signInPromptNotNow),
        findsOneWidget,
      );
      expect(find.byType(BackupScreen), findsNothing);
    });

    testWidgets('Not now closes C09 with no change', (tester) async {
      await start(tester);
      await openAccountBackup(tester);

      await tap(tester, find.text(_l10n.signInPromptNotNow));

      expect(find.byType(SignInPrompt), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
      expect(picker.picks, 0);
      expect(auth.currentUser, isNull);
    });

    testWidgets('dismissing C09 changes nothing either', (tester) async {
      await start(tester);
      await openAccountBackup(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPrompt), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(picker.picks, 0);
    });

    testWidgets('Sign in opens S24, then returns to Settings signed in', (
      tester,
    ) async {
      await start(tester);
      await openAccountBackup(tester);

      await tap(tester, find.widgetWithText(FilledButton, _l10n.accountSignIn));
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(SignInPrompt), findsNothing);

      await tap(tester, find.text(_l10n.signInWithGoogle));

      expect(find.byType(SignInScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(SignInPrompt), findsNothing);
      expect(auth.currentUser, testUser);

      // Now the row opens Backup & sync.
      await openAccountBackup(tester);
      expect(find.byType(BackupScreen), findsOneWidget);
    });

    testWidgets('back from S24 returns to Settings, still a guest', (
      tester,
    ) async {
      await start(tester);
      await openAccountBackup(tester);
      await tap(tester, find.widgetWithText(FilledButton, _l10n.accountSignIn));

      await tap(tester, find.byTooltip('Back'));

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(SignInPrompt), findsNothing);
      expect(auth.currentUser, isNull);
    });

    testWidgets('a signed-in user goes straight to S25b', (tester) async {
      auth = FakeAuthRepository(user: testUser);
      await start(tester);

      await openAccountBackup(tester);

      expect(find.byType(SignInPrompt), findsNothing);
      expect(find.byType(BackupScreen), findsOneWidget);
      expect(find.text(_l10n.backupTitle), findsOneWidget);
      expect(find.text(_l10n.backupIncludedTitle), findsOneWidget);
      expect(find.text(_l10n.backupNotIncludedTitle), findsOneWidget);
    });
  });

  group('showSignInPrompt', () {
    testWidgets('resolves to whether the user ended signed in', (tester) async {
      await start(tester);
      final context = tester.element(find.byType(SettingsScreen));

      var result = showSignInPrompt(context, reason: 'Why');
      await tester.pumpAndSettle();
      expect(find.text('Why'), findsOneWidget);
      await tap(tester, find.text(_l10n.signInPromptNotNow));
      expect(await result, isFalse);

      result = showSignInPrompt(context, reason: 'Why');
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(FilledButton, _l10n.accountSignIn));
      await tap(tester, find.text(_l10n.signInWithGoogle));
      expect(await result, isTrue);
    });

    for (final brightness in Brightness.values) {
      testWidgets('C09 fits a small phone at 1.3× text ($brightness)', (
        tester,
      ) async {
        useScreen(tester, textScale: 1.3);
        await pumpZemaApp(
          tester,
          location: AppRoutes.settings,
          phoneBrightness: brightness,
          auth: auth,
          googlePicker: picker,
          savedPrefs: {
            AccountChoiceController.key: true,
            'themeMode': brightness.name,
          },
        );
        await tester.scrollUntilVisible(
          find.text(_l10n.settingsAccountBackup),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await openAccountBackup(tester);

        expect(tester.takeException(), isNull);
        expect(find.text(_l10n.signInPromptNotNow).hitTestable(), findsOne);
      });
    }
  });

  testWidgets('FR-9: a guest is never asked to sign in while listening, '
      'browsing, searching or using lyrics', (tester) async {
    await start(
      tester,
      location: AppRoutes.home,
      scanner: FakeLibraryScanner([
        scannedAudio(1, '/m/Tizita.mp3', title: 'Tizita', artist: 'Mahmoud'),
        scannedAudio(2, '/m/Ambassel.mp3', title: 'Ambassel', artist: 'Aster'),
      ]),
    );

    void expectNoPrompt(String where) {
      expect(find.byType(SignInPrompt), findsNothing, reason: where);
      expect(find.byType(SignInScreen), findsNothing, reason: where);
    }

    expectNoPrompt('Home');
    for (final tab in ['Search', 'Library', 'Contribute', 'Home']) {
      await tap(tester, find.text(tab).last);
      expectNoPrompt(tab);
    }

    // Library: every tab, then play a song.
    await tap(tester, find.text('Library').last);
    for (final tab in [
      _l10n.libraryTabFolders,
      _l10n.libraryTabAlbums,
      _l10n.libraryTabArtists,
      _l10n.libraryTabFavorites,
      _l10n.libraryTabPlaylists,
      _l10n.libraryTabTracks,
    ]) {
      await tap(tester, find.text(tab));
      expectNoPrompt(tab);
    }
    await tap(tester, find.text('Tizita'));
    expectNoPrompt('playing');

    // Now Playing: favorite, lyrics, artwork, next.
    await tap(
      tester,
      find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.text('Tizita'),
      ),
    );
    expect(find.byType(NowPlayingScreen), findsOneWidget);
    for (final tooltip in [
      _l10n.songFavorite,
      _l10n.playerShowLyrics,
      _l10n.playerShowArtwork,
      _l10n.playerNext,
      _l10n.playerPause,
    ]) {
      await tap(tester, find.byTooltip(tooltip));
      expectNoPrompt(tooltip);
    }
    await tap(tester, find.byTooltip(_l10n.playerClose));

    // Search for a song.
    await tap(tester, find.text('Search').last);
    await tester.enterText(find.byType(TextField), 'Amba');
    await tester.pumpAndSettle();
    expectNoPrompt('search');

    expect(picker.picks, 0);
    expect(auth.currentUser, isNull);
  });
}
