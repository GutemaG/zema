import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/presentation/widgets/sign_in_prompt.dart';
import 'package:zema/features/contribute/application/drafts.dart';
import 'package:zema/features/contribute/presentation/contribute_flow_screen.dart';
import 'package:zema/features/contribute/presentation/contribute_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

ContributionDraft titled(String title, {DraftStep step = DraftStep.lyrics}) =>
    ContributionDraft(
      song: Song(id: '', title: title, sections: const []),
      step: step,
    );

void main() {
  late ZemaDatabase db;
  late FakeAuthRepository auth;
  final t0 = DateTime.utc(2026, 11, 2, 9);

  setUp(() {
    db = memoryDatabase();
    auth = FakeAuthRepository(user: testUser);
  });

  Future<void> start(
    WidgetTester tester, {
    String location = AppRoutes.contribute,
    bool backendConfigured = true,
    Brightness brightness = Brightness.dark,
  }) {
    // Closes the app inside the test, even when it fails; left to the
    // framework, a failed test's database streams close outside the fake
    // clock and the run never ends.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(draftSaveDelay * 2);
    });
    return pumpZemaApp(
      tester,
      location: location,
      auth: auth,
      database: db,
      backendConfigured: backendConfigured,
      googlePicker: FakeGoogleAccountPicker(),
      phoneBrightness: brightness,
      savedPrefs: {AccountChoiceController.key: true},
    );
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder addLyrics() =>
      find.widgetWithText(FilledButton, _l10n.contributeAddLyrics);

  Finder field(String label) => find.widgetWithText(TextField, label);

  Finder dialogButton(String label) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

  // Plain selects: awaiting a Drift stream hangs in widget tests.
  Future<List<ContributionDraft>> savedDrafts() async => [
    for (final row in await db.select(db.drafts).get())
      ContributionDraft.fromJson(jsonDecode(row.draft)),
  ];

  Future<List<String>> savedTitles() async => [
    for (final d in await savedDrafts()) d.title,
  ];

  group('guests', () {
    setUp(() => auth = FakeAuthRepository());

    testWidgets('see how it works; Add lyrics asks them to sign in', (
      tester,
    ) async {
      await start(tester);
      expect(find.text(_l10n.contributeHowTitle), findsOneWidget);
      expect(find.text(_l10n.contributeStepSync), findsOneWidget);

      await tap(tester, addLyrics());
      expect(find.byType(SignInPrompt), findsOneWidget);
      expect(find.text(_l10n.contributeSignInReason), findsOneWidget);

      await tap(tester, find.text(_l10n.signInPromptNotNow));
      expect(find.byType(ContributeFlowScreen), findsNothing);
      expect(await savedTitles(), isEmpty);
    });

    testWidgets('after signing in, the draft starts', (tester) async {
      await start(tester);
      await tap(tester, addLyrics());
      await tap(tester, find.widgetWithText(FilledButton, _l10n.accountSignIn));
      await tap(tester, find.text(_l10n.signInWithGoogle));

      expect(auth.currentUser, isNotNull);
      expect(find.byType(ContributeFlowScreen), findsOneWidget);
      expect(await savedDrafts(), hasLength(1));
    });
  });

  testWidgets('without a backend: no actions, a note instead', (tester) async {
    await start(tester, backendConfigured: false);
    expect(find.text(_l10n.contributeHowTitle), findsOneWidget);
    expect(find.text(_l10n.contributeNoBackend), findsOneWidget);
    expect(addLyrics(), findsNothing);
  });

  group('drafts', () {
    testWidgets('typing is saved shortly after, and listed on S05', (
      tester,
    ) async {
      await start(tester);
      await tap(tester, addLyrics());
      expect(find.byType(ContributeFlowScreen), findsOneWidget);

      await tester.enterText(field(_l10n.contributeFieldTitle), 'Selam');
      await tester.enterText(field(_l10n.contributeFieldArtist), 'Choir');
      await tester.pump(draftSaveDelay ~/ 2);
      expect(await savedTitles(), [''], reason: 'not yet');
      await tester.pump(draftSaveDelay);
      final saved = (await savedDrafts()).single;
      expect(saved.song.title, 'Selam');
      expect(saved.song.artist, 'Choir');

      await tap(tester, find.byType(CloseButton));
      expect(find.byType(ContributeScreen), findsOneWidget);
      expect(find.text('Selam'), findsOneWidget);
      expect(find.textContaining(_l10n.contributeStepLyrics), findsWidgets);
    });

    testWidgets('a change is saved when the flow closes at once', (
      tester,
    ) async {
      await start(tester);
      await tap(tester, addLyrics());
      await tester.enterText(field(_l10n.contributeFieldTitle), 'Tizita');
      await tap(tester, find.byType(CloseButton));
      await tester.pump(draftSaveDelay);
      expect(await savedTitles(), ['Tizita']);
    });

    testWidgets(
      'a change is saved at once when the app goes to the background',
      (tester) async {
        await start(tester);
        await tap(tester, addLyrics());
        await tester.enterText(field(_l10n.contributeFieldTitle), 'Paused');
        // Into the background and back with no time passing (frames stop
        // while paused).
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pump();
        expect(await savedTitles(), ['Paused'], reason: 'before the delay');
      },
    );

    testWidgets('listed last changed first; one opens with what was typed', (
      tester,
    ) async {
      useScreen(tester, size: const Size(400, 1200));
      await db.draftsDao.create(titled('Older'), now: t0);
      await db.draftsDao.create(
        titled('Newer'),
        now: t0.add(const Duration(hours: 1)),
      );
      await start(tester);

      final older = tester.getTopLeft(find.text('Older')).dy;
      final newer = tester.getTopLeft(find.text('Newer')).dy;
      expect(newer, lessThan(older));

      await tap(tester, find.text('Older'));
      expect(find.byType(ContributeFlowScreen), findsOneWidget);
      expect(
        tester
            .widget<TextField>(field(_l10n.contributeFieldTitle))
            .controller!
            .text,
        'Older',
      );
    });

    testWidgets('an untitled draft is listed as Untitled', (tester) async {
      await db.draftsDao.create(const ContributionDraft(), now: t0);
      await start(tester);
      expect(find.text(_l10n.contributeDraftUntitled), findsOneWidget);
    });

    testWidgets('deleted after confirming; Cancel keeps it', (tester) async {
      await db.draftsDao.create(titled('Selam'), now: t0);
      await start(tester);

      await tap(tester, find.byTooltip(_l10n.contributeDraftDelete));
      expect(
        find.text(_l10n.contributeDraftDeleteMessage('Selam')),
        findsOneWidget,
      );
      await tap(tester, dialogButton(_l10n.actionCancel));
      expect(await savedTitles(), ['Selam']);

      await tap(tester, find.byTooltip(_l10n.contributeDraftDelete));
      await tap(tester, dialogButton(_l10n.contributeDraftDelete));
      expect(await savedTitles(), isEmpty);
      expect(find.text('Selam'), findsNothing);
    });

    testWidgets('a saved draft is there in a new app instance', (tester) async {
      await start(tester);
      await tap(tester, addLyrics());
      await tester.enterText(field(_l10n.contributeFieldTitle), 'Kept');
      await tester.pump(draftSaveDelay * 2);

      // As after the app was killed: the same database, a new app.
      await tester.pumpWidget(const SizedBox());
      await start(tester);
      expect(find.text('Kept'), findsOneWidget);
    });

    testWidgets('a title over 200 characters is flagged', (tester) async {
      await start(tester);
      await tap(tester, addLyrics());
      await tester.enterText(field(_l10n.contributeFieldTitle), 't' * 201);
      await tester.pump();
      expect(find.text(_l10n.contributeTitleTooLong), findsOneWidget);
    });

    testWidgets('a draft that no longer exists says so', (tester) async {
      await start(tester, location: AppRoutes.draft(99));
      expect(find.text(_l10n.contributeDraftGone), findsOneWidget);
    });
  });

  group('signing out', () {
    testWidgets('names the drafts, and confirming deletes them', (
      tester,
    ) async {
      await db.draftsDao.create(titled('Selam'), now: t0);
      await db.draftsDao.create(const ContributionDraft(), now: t0);
      await start(tester, location: AppRoutes.profile);

      await tap(tester, find.text(_l10n.profileSignOut));
      expect(
        find.textContaining(
          _l10n.profileDraftsWarning(
            2,
            'Selam, ${_l10n.contributeDraftUntitled}',
          ),
        ),
        findsOneWidget,
      );
      await tap(tester, dialogButton(_l10n.profileSignOut));
      expect(auth.currentUser, isNull);
      expect(await savedTitles(), isEmpty);
    });

    testWidgets('with no drafts, the message is as before', (tester) async {
      await start(tester, location: AppRoutes.profile);
      await tap(tester, find.text(_l10n.profileSignOut));
      expect(find.text(_l10n.profileSignOutMessage), findsOneWidget);
    });

    testWidgets('deleting the account names them too', (tester) async {
      await db.draftsDao.create(titled('Selam'), now: t0);
      await start(tester, location: AppRoutes.profile);
      await tester.scrollUntilVisible(
        find.text(_l10n.profileDeleteAccount),
        200,
      );
      await tap(tester, find.text(_l10n.profileDeleteAccount));
      expect(
        find.textContaining(_l10n.profileDraftsWarning(1, 'Selam')),
        findsOneWidget,
      );
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a small phone at 1.3× text ($brightness)', (
      tester,
    ) async {
      useScreen(tester, textScale: 1.3);
      await db.draftsDao.create(titled('ሰላም ለዚህ ቤት ' * 4), now: t0);
      await start(tester, brightness: brightness);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byTooltip(_l10n.contributeDraftDelete),
        200,
      );
      expect(tester.takeException(), isNull);

      await tap(tester, find.textContaining('ሰላም ለዚህ ቤት'));
      expect(find.byType(ContributeFlowScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
