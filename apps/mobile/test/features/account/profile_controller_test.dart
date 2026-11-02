import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/own_copies_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/account/application/profile.dart';
import 'package:zema/features/account/data/profile_cache.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_library.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeGoogleAccountPicker picker;
  late FakeAvatarCache avatars;
  late SharedPreferences prefs;
  late ProviderContainer container;
  late ZemaDatabase db;

  final server = Profile(
    userId: testUser.id,
    displayName: 'Abebe B.',
    avatarUrl: testUser.avatarUrl,
    roles: const {AccountRole.contributor, AccountRole.moderator},
  );
  final saved = Profile(userId: testUser.id, displayName: 'Saved name');

  Future<void> start({AuthUser? user = testUser, Profile? cached}) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    if (cached != null) await ProfileCache(prefs).write(cached);
    auth = FakeAuthRepository(user: user);
    profiles = FakeProfileRepository(auth, profile: server);
    picker = FakeGoogleAccountPicker();
    avatars = FakeAvatarCache();
    db = memoryDatabase();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        ...accountOverrides(
          auth: auth,
          profiles: profiles,
          picker: picker,
          avatars: avatars,
        ),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(profileProvider, (_, _) {})
      ..listen(accountActionsProvider, (_, _) {});
  }

  Future<Profile?> profile() => container.read(profileProvider.future);
  ProfileCache cache() => ProfileCache(prefs);
  AccountActionsController actions() =>
      container.read(accountActionsProvider.notifier);

  group('profile', () {
    test('a guest has none', () async {
      await start(user: null);
      expect(await profile(), isNull);
    });

    test("with none saved, the server's, which is then saved", () async {
      await start();
      expect(await profile(), server);
      expect(cache().read(testUser.id), server);
    });

    test("the saved one shows first, then the server's", () async {
      await start(cached: saved);
      expect(await profile(), saved);
      await pumpEventQueue();
      expect(container.read(profileProvider).value, server);
      expect(cache().read(testUser.id), server);
    });

    test('offline: the saved one stays', () async {
      await start(cached: saved);
      profiles.failure = const NetworkFailure('offline');
      expect(await profile(), saved);
      await pumpEventQueue();
      expect(container.read(profileProvider).value, saved);
    });

    test('offline with none saved: the Google name and photo', () async {
      await start();
      profiles.failure = const NetworkFailure('offline');
      expect(
        await profile(),
        Profile(
          userId: testUser.id,
          displayName: testUser.name!,
          avatarUrl: testUser.avatarUrl,
        ),
      );
      expect(cache().read(testUser.id), isNull);
    });

    test('follows a sign-out', () async {
      await start();
      await profile();
      await auth.signOut();
      await pumpEventQueue();
      expect(container.read(profileProvider).value, isNull);
    });

    test('an unreadable saved profile is ignored', () async {
      await start();
      await prefs.setString('profile.${testUser.id}', '{"displayName": 3}');
      expect(cache().read(testUser.id), isNull);
    });
  });

  group('rename', () {
    test('saves on the server and here', () async {
      await start();
      await profile();
      await container.read(profileProvider.notifier).rename('  New name ');
      expect(profiles.renames, ['New name']);
      expect(container.read(profileProvider).value?.displayName, 'New name');
      expect(cache().read(testUser.id)?.displayName, 'New name');
    });

    test('offline: throws, and the old name stays', () async {
      await start();
      await profile();
      profiles.failure = const NetworkFailure('offline');
      await expectLater(
        container.read(profileProvider.notifier).rename('New name'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(container.read(profileProvider).value, server);
      expect(cache().read(testUser.id), server);
    });
  });

  group('sign out', () {
    test('here and of Google, forgetting the profile and avatar', () async {
      await start();
      await profile();
      expect(await actions().signOut(), isTrue);
      expect(auth.currentUser, isNull);
      expect(picker.signOutCalls, 1);
      expect(picker.disconnectCalls, 0);
      expect(cache().read(testUser.id), isNull);
      expect(avatars.clearCalls, 1);
      expect(container.read(accountActionsProvider), isNull);
    });

    test(
      'forgets own copies of contributions and their shared files',
      () async {
        await start();
        final files = await Directory.systemTemp.createTemp('own_copies');
        addTearDown(() => files.delete(recursive: true));
        final audio = File('${files.path}/shared_audio/a.ogg');
        await audio.create(recursive: true);
        await db.ownCopiesDao.add(
          OwnCopy(
            contributionId: 'c-1',
            kind: ContributionKind.newSong,
            song: const Song(id: 'selam', title: 'Selam', sections: []),
            audioPath: audio.path,
            submittedAt: DateTime.utc(2026, 11, 2),
          ),
        );

        await actions().signOut();
        expect(await db.ownCopiesDao.all(), isEmpty);
        expect(audio.existsSync(), isFalse);
      },
    );
  });

  group('delete account', () {
    test('on the server, then signs out and disconnects Google', () async {
      await start();
      await profile();
      expect(await actions().deleteAccount(), isTrue);
      expect(auth.deleteCalls, 1);
      expect(auth.currentUser, isNull);
      expect(picker.disconnectCalls, 1);
      expect(cache().read(testUser.id), isNull);
      expect(avatars.clearCalls, 1);
    });

    test('a failure is thrown and changes nothing', () async {
      for (final failure in const [
        NetworkFailure('offline'),
        BackendFailure('server error'),
      ]) {
        await start();
        await profile();
        auth.deleteFailure = failure;
        await expectLater(actions().deleteAccount(), throwsA(failure));
        expect(auth.currentUser, testUser);
        expect(picker.disconnectCalls, 0);
        expect(cache().read(testUser.id), server);
        expect(avatars.clearCalls, 0);
        expect(container.read(accountActionsProvider), isNull);
      }
    });

    test('is the running action, and a second call is ignored', () async {
      await start();
      await profile();
      auth.deleteGate = Completer<void>();
      final first = actions().deleteAccount();
      expect(
        container.read(accountActionsProvider),
        AccountAction.deleteAccount,
      );

      expect(await actions().deleteAccount(), isFalse);
      expect(await actions().signOut(), isFalse);
      expect(auth.signOutCalls, 0);

      auth.deleteGate!.complete();
      expect(await first, isTrue);
      expect(auth.deleteCalls, 1);
      expect(container.read(accountActionsProvider), isNull);
    });
  });
}
