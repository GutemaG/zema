import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/presentation/account_choice_screen.dart';
import 'package:zema/features/account/presentation/sign_in_screen.dart';
import 'package:zema/features/home/presentation/home_screen.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeGoogleAccountPicker picker;

  setUp(() {
    auth = FakeAuthRepository();
    picker = FakeGoogleAccountPicker();
  });

  /// The app as a build with Google sign-in starts it.
  Future<void> start(
    WidgetTester tester, {
    bool choiceMade = false,
    String location = AppRoutes.home,
    bool withPicker = true,
    bool backendConfigured = true,
  }) => pumpZemaApp(
    tester,
    location: location,
    auth: auth,
    googlePicker: withPicker ? picker : null,
    backendConfigured: backendConfigured,
    savedPrefs: {if (choiceMade) AccountChoiceController.key: true},
  );

  Future<bool?> choiceSaved() async =>
      (await savedPreferences()).getBool(AccountChoiceController.key);

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('S04 account choice', () {
    testWidgets('shows before Home on the first start, guest first', (
      tester,
    ) async {
      await start(tester);

      expect(find.byType(AccountChoiceScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Welcome to Zema'), findsOneWidget);
      expect(find.text('Add and fix lyrics for everyone'), findsOneWidget);
      expect(
        find.text('Back up your favorites, playlists and settings'),
        findsOneWidget,
      );
      expect(find.text('Get them back on a new phone'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Continue as guest'),
        findsOneWidget,
        reason: 'guest is the main button',
      );
      expect(find.widgetWithText(TextButton, 'Sign in'), findsOneWidget);
      expect(await choiceSaved(), isNull, reason: 'saved only on a choice');
    });

    testWidgets('Continue as guest opens Home, for good', (tester) async {
      await start(tester);
      await tapText(tester, 'Continue as guest');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(await choiceSaved(), isTrue);
      expect(auth.idTokens, isEmpty);
      expect(picker.picks, 0);

      // Going Home again (e.g. a tab tap) doesn't bring S04 back.
      GoRouter.of(tester.element(find.byType(HomeScreen))).go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(find.byType(AccountChoiceScreen), findsNothing);
    });

    testWidgets('a later start goes straight Home', (tester) async {
      await start(tester, choiceMade: true);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AccountChoiceScreen), findsNothing);
    });

    testWidgets('killed on S04, it shows again next start', (tester) async {
      await start(tester);
      expect(find.byType(AccountChoiceScreen), findsOneWidget);

      // A new start with what was saved: nothing.
      await start(tester);
      expect(find.byType(AccountChoiceScreen), findsOneWidget);
    });

    testWidgets('Sign in opens S24; leaving it goes Home, and S04 stays away', (
      tester,
    ) async {
      await start(tester);
      await tapText(tester, 'Sign in');

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(await choiceSaved(), isTrue);

      await tapText(tester, 'Continue as guest');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AccountChoiceScreen), findsNothing);
      expect(auth.currentUser, isNull);
    });

    testWidgets('closing S24 from S04 goes Home', (tester) async {
      await start(tester);
      await tapText(tester, 'Sign in');
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('system back on S24 from S04 goes Home', (tester) async {
      await start(tester);
      await tapText(tester, 'Sign in');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('skipped in a build without Google client IDs', (tester) async {
      await start(tester, withPicker: false);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AccountChoiceScreen), findsNothing);
    });

    testWidgets('skipped in a build without a backend', (tester) async {
      await start(tester, backendConfigured: false);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AccountChoiceScreen), findsNothing);
    });

    testWidgets('only Home is redirected', (tester) async {
      await start(tester, location: AppRoutes.library);
      expect(find.byType(AccountChoiceScreen), findsNothing);
    });
  });

  group('S24 sign in', () {
    testWidgets('shows the benefits, Google and guest', (tester) async {
      await start(tester, choiceMade: true, location: AppRoutes.signIn);

      expect(find.text('Sign in to Zema'), findsOneWidget);
      expect(find.text('Add and fix lyrics for everyone'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Continue with Google'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextButton, 'Continue as guest'),
        findsOneWidget,
      );
    });

    testWidgets('picking an account signs in with its ID token', (
      tester,
    ) async {
      await start(tester);
      await tapText(tester, 'Sign in');
      await tapText(tester, 'Continue with Google');

      expect(picker.picks, 1);
      expect(auth.idTokens, ['google-id-token']);
      expect(auth.currentUser, testUser);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Signed in as Abebe Bikila'), findsOneWidget);
    });

    testWidgets('signed in, it goes back to the screen underneath', (
      tester,
    ) async {
      await start(tester, choiceMade: true, location: AppRoutes.library);
      unawaited(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .push(AppRoutes.signIn),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(CloseButton), findsNothing);

      await tapText(tester, 'Continue with Google');

      expect(find.byType(SignInScreen), findsNothing);
      expect(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        AppRoutes.library,
      );
      expect(auth.currentUser, testUser);
    });

    testWidgets('a Google account without a name: its email', (tester) async {
      auth.signInAs = const AuthUser(id: 'u2', email: 'tigist@example.com');
      await start(tester, choiceMade: true, location: AppRoutes.signIn);
      await tapText(tester, 'Continue with Google');
      expect(find.text('Signed in as tigist@example.com'), findsOneWidget);
    });

    testWidgets('a cancelled picker stays on S24 with no message', (
      tester,
    ) async {
      picker.tokens = null;
      await start(tester, choiceMade: true, location: AppRoutes.signIn);
      await tapText(tester, 'Continue with Google');

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(auth.idTokens, isEmpty);
      expect(auth.currentUser, isNull);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Continue with Google'),
            )
            .onPressed,
        isNotNull,
        reason: 'ready to try again',
      );
    });

    testWidgets('offline: a short message, still a guest', (tester) async {
      auth.signInFailure = const NetworkFailure('offline');
      await start(tester, choiceMade: true, location: AppRoutes.signIn);
      await tapText(tester, 'Continue with Google');

      expect(
        find.text("No connection. Try again when you're online."),
        findsOneWidget,
      );
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(auth.currentUser, isNull);
    });

    testWidgets('a refused sign-in: a short message, still a guest', (
      tester,
    ) async {
      auth.signInFailure = const AuthFailure('bad token');
      await start(tester, choiceMade: true, location: AppRoutes.signIn);
      await tapText(tester, 'Continue with Google');

      expect(find.text("Couldn't sign in. Try again."), findsOneWidget);
      expect(auth.currentUser, isNull);
    });

    testWidgets('a Google failure: the same message', (tester) async {
      picker.failure = const AuthFailure('Google sign-in failed');
      await start(tester, choiceMade: true, location: AppRoutes.signIn);
      await tapText(tester, 'Continue with Google');

      expect(find.text("Couldn't sign in. Try again."), findsOneWidget);
      expect(auth.idTokens, isEmpty);
    });

    testWidgets('an unexpected plugin error: the same message', (tester) async {
      picker.failure = StateError('plugin missing');
      await start(tester, choiceMade: true, location: AppRoutes.signIn);
      await tapText(tester, 'Continue with Google');

      expect(find.text("Couldn't sign in. Try again."), findsOneWidget);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('busy: progress, buttons off, a second tap ignored', (
      tester,
    ) async {
      picker.gate = Completer<void>();
      await start(tester, choiceMade: true, location: AppRoutes.signIn);
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final google = find.widgetWithText(FilledButton, 'Continue with Google');
      expect(tester.widget<FilledButton>(google).onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Continue as guest'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(google, warnIfMissed: false);
      await tester.pump();
      expect(picker.picks, 1);

      picker.gate!.complete();
      await tester.pumpAndSettle();
      expect(auth.idTokens, hasLength(1));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('after a failure, trying again signs in', (tester) async {
      auth.signInFailure = const NetworkFailure('offline');
      await start(tester, choiceMade: true, location: AppRoutes.signIn);
      await tapText(tester, 'Continue with Google');
      expect(auth.currentUser, isNull);

      await tapText(tester, 'Continue with Google');
      expect(auth.currentUser, testUser);
    });
  });

  group('fit', () {
    for (final brightness in Brightness.values) {
      testWidgets('S04 and S24 fit at 1.3× text, ${brightness.name}', (
        tester,
      ) async {
        useScreen(tester, textScale: 1.3);
        await pumpZemaApp(
          tester,
          auth: auth,
          googlePicker: picker,
          phoneBrightness: brightness,
        );
        expect(find.byType(AccountChoiceScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Sign in'));
        await tester.pumpAndSettle();
        await tapText(tester, 'Sign in');
        expect(find.byType(SignInScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Continue with Google'));
        await tester.pumpAndSettle();
        expect(find.text('Continue with Google').hitTestable(), findsOneWidget);
      });
    }

    testWidgets('a small screen scrolls instead of overflowing', (
      tester,
    ) async {
      useScreen(tester, size: const Size(320, 480), textScale: 1.3);
      await start(tester, choiceMade: true, location: AppRoutes.signIn);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Continue as guest'));
      await tester.pumpAndSettle();
      expect(find.text('Continue as guest').hitTestable(), findsOneWidget);
    });
  });
}
