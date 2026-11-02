import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/account/application/sign_in.dart';
import 'package:zema/features/account/data/profile_cache.dart';
import 'package:zema/features/account/presentation/profile_screen.dart';
import 'package:zema/features/account/presentation/sign_in_screen.dart';
import 'package:zema/features/account/presentation/widgets/account_avatar.dart';
import 'package:zema/features/home/presentation/home_screen.dart';
import 'package:zema/features/settings/presentation/settings_screen.dart';
import 'package:zema/features/library/presentation/widgets/track_art.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeGoogleAccountPicker picker;
  late FakeAvatarCache avatars;

  final server = Profile(
    userId: testUser.id,
    displayName: 'Abebe Bikila',
    avatarUrl: testUser.avatarUrl,
  );

  setUp(() {
    picker = FakeGoogleAccountPicker();
    avatars = FakeAvatarCache();
  });

  /// The app with Google sign-in, the account choice already made, signed
  /// in as [user] (a guest when null) with [profile] on the server, or
  /// [profileFailure] from it.
  Future<void> start(
    WidgetTester tester, {
    AuthUser? user = testUser,
    Profile? profile,
    String location = AppRoutes.home,
    bool withPicker = true,
    Map<String, Object> savedPrefs = const {},
    Brightness phoneBrightness = Brightness.dark,
    ZemaFailure? profileFailure,
  }) async {
    auth = FakeAuthRepository(user: user);
    profiles = FakeProfileRepository(auth, profile: profile ?? server)
      ..failure = profileFailure;
    await pumpZemaApp(
      tester,
      location: location,
      auth: auth,
      profiles: profiles,
      googlePicker: withPicker ? picker : null,
      avatars: avatars,
      phoneBrightness: phoneBrightness,
      savedPrefs: {AccountChoiceController.key: true, ...savedPrefs},
    );
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) =>
      tap(tester, find.text(text));

  Future<void> openProfile(WidgetTester tester) =>
      tap(tester, find.byTooltip('Profile'));

  Finder dialogButton(String label) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

  group('Home header', () {
    testWidgets('signed in: the avatar opens Profile', (tester) async {
      await start(tester);
      expect(find.byTooltip('Settings'), findsNothing);
      final avatar = find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(AccountAvatar),
      );
      expect(avatar, findsOneWidget);
      expect(
        find.descendant(of: avatar, matching: find.byType(Image)),
        findsOneWidget,
      );
      expect(avatars.loads, [testUser.avatarUrl]);

      await openProfile(tester);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('a guest gets the guest icon, opening Profile', (tester) async {
      await start(tester, user: null);
      expect(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byIcon(Icons.person_outline),
        ),
        findsOneWidget,
      );
      await openProfile(tester);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('without sign-in, it stays the Settings button', (
      tester,
    ) async {
      await start(tester, user: null, withPicker: false);
      expect(find.byTooltip('Profile'), findsNothing);
      await tap(tester, find.byTooltip('Settings'));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('no photo: a letter tile of the name', (tester) async {
      await start(
        tester,
        profile: Profile(userId: testUser.id, displayName: 'Meron'),
      );
      expect(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(LetterTile),
        ),
        findsOneWidget,
      );
      expect(find.text('M'), findsOneWidget);
    });
  });

  group('S25 signed in', () {
    testWidgets('avatar, name, role, Settings, Sign out, Delete', (
      tester,
    ) async {
      await start(tester, location: AppRoutes.profile);
      expect(find.byType(AccountAvatar), findsOneWidget);
      expect(find.text('Abebe Bikila'), findsOneWidget);
      expect(find.text('Contributor'), findsOneWidget);
      expect(find.byTooltip('Edit name'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
      expect(find.text('Sign in to do more'), findsNothing);
    });

    testWidgets('the badge names the highest role', (tester) async {
      await start(
        tester,
        location: AppRoutes.profile,
        profile: Profile(
          userId: testUser.id,
          displayName: 'Abebe Bikila',
          roles: const {AccountRole.contributor, AccountRole.moderator},
        ),
      );
      expect(find.text('Moderator'), findsOneWidget);
      expect(find.text('Contributor'), findsNothing);
    });

    testWidgets('Settings opens from Profile, and back returns', (
      tester,
    ) async {
      await start(tester);
      await openProfile(tester);
      await tapText(tester, 'Settings');
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tap(tester, find.byType(BackButton));
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('offline: the saved name and avatar show', (tester) async {
      await start(
        tester,
        location: AppRoutes.profile,
        savedPrefs: await savedProfile(
          Profile(
            userId: testUser.id,
            displayName: 'Saved name',
            avatarUrl: 'https://example.com/saved.png',
          ),
        ),
        profileFailure: const NetworkFailure('offline'),
      );
      expect(find.text('Saved name'), findsOneWidget);
      expect(avatars.loads, ['https://example.com/saved.png']);
      expect(
        find.descendant(
          of: find.byType(AccountAvatar),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
    });
  });

  group('edit name', () {
    Future<void> openRename(WidgetTester tester) async {
      await start(tester, location: AppRoutes.profile);
      await tap(tester, find.byTooltip('Edit name'));
    }

    testWidgets('saves the new name', (tester) async {
      await openRename(tester);
      expect(find.text('Display name'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  Abebe B. ');
      await tester.pump();
      await tap(tester, dialogButton('Save'));

      expect(profiles.renames, ['Abebe B.']);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Abebe B.'), findsOneWidget);
    });

    testWidgets('Save is off when empty, unchanged or too long', (
      tester,
    ) async {
      await openRename(tester);
      TextButton save() => tester.widget<TextButton>(
        find.ancestor(
          of: dialogButton('Save'),
          matching: find.byType(TextButton),
        ),
      );
      expect(save().onPressed, isNull, reason: 'unchanged');
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(save().onPressed, isNull, reason: 'empty');
      await tester.enterText(find.byType(TextField), 'x' * 40);
      await tester.pump();
      expect(save().onPressed, isNotNull, reason: '40 characters');
      expect(
        tester.widget<TextField>(find.byType(TextField)).maxLength,
        40,
        reason: 'the field stops at 40',
      );
    });

    testWidgets('Cancel keeps the name', (tester) async {
      await openRename(tester);
      await tester.enterText(find.byType(TextField), 'Other');
      await tap(tester, dialogButton('Cancel'));
      expect(profiles.renames, isEmpty);
      expect(find.text('Abebe Bikila'), findsOneWidget);
    });

    testWidgets('offline: a message, and the old name stays', (tester) async {
      await openRename(tester);
      profiles.failure = const NetworkFailure('offline');
      await tester.enterText(find.byType(TextField), 'Abebe B.');
      await tester.pump();
      await tap(tester, dialogButton('Save'));

      expect(find.text("No connection. Your name wasn't changed."), findsOne);
      expect(find.text('Abebe Bikila'), findsOneWidget);
    });

    testWidgets('a refused name: a message', (tester) async {
      await openRename(tester);
      profiles.failure = const ValidationFailure('refused');
      await tester.enterText(find.byType(TextField), 'Abebe B.');
      await tester.pump();
      await tap(tester, dialogButton('Save'));
      expect(find.text("Couldn't save your name. Try again."), findsOne);
    });
  });

  group('sign out', () {
    testWidgets('after confirming: the guest version, local data kept', (
      tester,
    ) async {
      await start(tester, location: AppRoutes.profile);
      await tapText(tester, 'Sign out');
      expect(find.text('Sign out?'), findsOneWidget);
      expect(
        find.text('Your songs, playlists and favorites stay on this phone.'),
        findsOneWidget,
      );
      await tap(tester, dialogButton('Sign out'));

      expect(auth.currentUser, isNull);
      expect(picker.signOutCalls, 1);
      expect(avatars.clearCalls, 1);
      expect(find.text('Signed out'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign in to do more'), findsOneWidget);
      expect(find.text('Delete account'), findsNothing);
    });

    testWidgets('the message shows though Google signs out slowly', (
      tester,
    ) async {
      await start(tester, location: AppRoutes.profile);
      picker.signOutGate = Completer<void>();
      await tapText(tester, 'Sign out');
      await tester.tap(dialogButton('Sign out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Signed out already: the account rows are gone before it returns.
      expect(find.text('Guest'), findsOneWidget);

      picker.signOutGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Signed out'), findsOneWidget);
    });

    testWidgets('Cancel keeps the user signed in', (tester) async {
      await start(tester, location: AppRoutes.profile);
      await tapText(tester, 'Sign out');
      await tap(tester, dialogButton('Cancel'));
      expect(auth.signOutCalls, 0);
      expect(find.text('Abebe Bikila'), findsOneWidget);
    });
  });

  group('S25 as a guest', () {
    testWidgets('guest icon, a sign-in card and Settings', (tester) async {
      await start(tester, user: null, location: AppRoutes.profile);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign in to do more'), findsOneWidget);
      expect(find.text('Add and fix lyrics for everyone'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
      expect(find.text('Delete account'), findsNothing);
    });

    testWidgets('signing in from the card comes back signed in', (
      tester,
    ) async {
      await start(tester, user: null);
      await openProfile(tester);
      await tap(tester, find.widgetWithText(FilledButton, 'Sign in'));
      expect(find.byType(SignInScreen), findsOneWidget);
      await tapText(tester, 'Continue with Google');

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Abebe Bikila'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });
  });

  group('delete account', () {
    Future<void> confirmBoth(WidgetTester tester) async {
      await tapText(tester, 'Delete account');
      await tap(tester, dialogButton('Continue'));
      await tap(tester, dialogButton('Delete'));
    }

    testWidgets('the first dialog says what is deleted and what stays', (
      tester,
    ) async {
      await start(tester, location: AppRoutes.profile);
      await tapText(tester, 'Delete account');
      expect(find.text('Delete your account?'), findsOneWidget);
      final message = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.textContaining('cloud backup'),
            ),
          )
          .data!;
      expect(message, contains('Zema account'));
      expect(message, contains('profile'));
      expect(message, contains('on this phone stay'));

      await tap(tester, dialogButton('Cancel'));
      expect(find.byType(AlertDialog), findsNothing, reason: 'no second step');
      expect(auth.deleteCalls, 0);
    });

    testWidgets('the second has a red Delete; Cancel there keeps all', (
      tester,
    ) async {
      await start(tester, location: AppRoutes.profile);
      await tapText(tester, 'Delete account');
      await tap(tester, dialogButton('Continue'));
      expect(find.text("This can't be undone"), findsOneWidget);
      final delete = tester.widget<FilledButton>(
        find.ancestor(
          of: dialogButton('Delete'),
          matching: find.byType(FilledButton),
        ),
      );
      final context = tester.element(find.byType(AlertDialog));
      expect(
        delete.style?.backgroundColor?.resolve({}),
        Theme.of(context).colorScheme.error,
      );

      await tap(tester, dialogButton('Cancel'));
      expect(auth.deleteCalls, 0);
      expect(auth.currentUser, testUser);
    });

    testWidgets('confirmed: deleted, signed out, Google disconnected', (
      tester,
    ) async {
      await start(tester, location: AppRoutes.profile);
      await confirmBoth(tester);

      expect(auth.deleteCalls, 1);
      expect(auth.currentUser, isNull);
      expect(picker.disconnectCalls, 1);
      expect(avatars.clearCalls, 1);
      expect(find.text('Account deleted'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('the message shows though Google disconnects slowly', (
      tester,
    ) async {
      await start(tester, location: AppRoutes.profile);
      picker.signOutGate = Completer<void>();
      await tapText(tester, 'Delete account');
      await tap(tester, dialogButton('Continue'));
      await tester.tap(dialogButton('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(auth.currentUser, isNull);
      expect(find.text('Guest'), findsOneWidget);

      picker.signOutGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Account deleted'), findsOneWidget);
    });

    testWidgets('while deleting, the screen is covered', (tester) async {
      await start(tester, location: AppRoutes.profile);
      auth.deleteGate = Completer<void>();
      await tapText(tester, 'Delete account');
      await tap(tester, dialogButton('Continue'));
      await tester.tap(dialogButton('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Deleting your account…'), findsOneWidget);
      expect(find.text('Sign out').hitTestable(), findsNothing);

      auth.deleteGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Deleting your account…'), findsNothing);
      expect(find.text('Account deleted'), findsOneWidget);
    });

    testWidgets('offline: a message, still signed in', (tester) async {
      await start(tester, location: AppRoutes.profile);
      auth.deleteFailure = const NetworkFailure('offline');
      await confirmBoth(tester);

      expect(
        find.text("No connection. Your account wasn't deleted."),
        findsOne,
      );
      expect(auth.currentUser, testUser);
      expect(picker.disconnectCalls, 0);
      expect(find.text('Abebe Bikila'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
    });

    testWidgets('a server error: a message, still signed in', (tester) async {
      await start(tester, location: AppRoutes.profile);
      auth.deleteFailure = const BackendFailure('server error');
      await confirmBoth(tester);

      expect(
        find.text("Couldn't delete your account. Try again later."),
        findsOne,
      );
      expect(auth.currentUser, testUser);
    });
  });

  group('fit', () {
    for (final brightness in Brightness.values) {
      testWidgets('S25 fits at 1.3× text, ${brightness.name}', (tester) async {
        useScreen(tester, textScale: 1.3);
        await start(
          tester,
          location: AppRoutes.profile,
          phoneBrightness: brightness,
          profile: Profile(
            userId: testUser.id,
            displayName: 'Abebe Bikila Woldemariam Tessema Gebre',
            avatarUrl: testUser.avatarUrl,
          ),
        );
        expect(tester.takeException(), isNull);
        final name = tester.widget<Text>(
          find.textContaining('Abebe Bikila Woldemariam'),
        );
        expect(name.overflow, TextOverflow.ellipsis);
        expect(name.maxLines, 1);
        // The list builds lazily.
        await tester.scrollUntilVisible(find.text('Delete account'), 200);
        await tester.pumpAndSettle();
        expect(find.text('Delete account').hitTestable(), findsOneWidget);

        await tapText(tester, 'Sign out');
        await tap(tester, dialogButton('Sign out'));
        expect(tester.takeException(), isNull);
        // Past the "Signed out" snackbar, which can cover the last row.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        // The guest version is taller; the list builds lazily.
        await tester.scrollUntilVisible(find.text('Settings'), 200);
        await tester.pumpAndSettle();
        expect(find.text('Settings').hitTestable(), findsOneWidget);
      });
    }
  });
}

/// [profile] as the app saves it, for `savedPrefs`.
Future<Map<String, Object>> savedProfile(Profile profile) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await ProfileCache(prefs).write(profile);
  return {for (final key in prefs.getKeys()) key: prefs.get(key)!};
}
