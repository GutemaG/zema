import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/backend/backend_config.dart';
import 'package:zema/app/backend/backend_providers.dart';
import 'package:zema/features/account/application/account_providers.dart';
import 'package:zema/features/account/data/secure_session_store.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

import '../../helpers/fake_auth.dart';

ProviderContainer _container(List<Override> overrides) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

/// The first user [authUserProvider] gives (kept listened, as the app does).
Future<AuthUser?> _firstUser(ProviderContainer container) {
  container.listen(authUserProvider, (_, _) {});
  return container.read(authUserProvider.future);
}

/// The values [authUserProvider] gives, as they arrive.
List<AuthUser?> _users(ProviderContainer container) {
  final users = <AuthUser?>[];
  container.listen(authUserProvider, (_, next) {
    if (next case AsyncData(:final value)) users.add(value);
  }, fireImmediately: true);
  return users;
}

void main() {
  group('a build with no backend', () {
    test('has no account features', () async {
      final container = _container([
        backendConfigProvider.overrideWithValue(
          const BackendConfig(url: BackendConfig.localUrl, key: ''),
        ),
      ]);
      expect(container.read(authRepositoryProvider), isNull);
      expect(container.read(profileRepositoryProvider), isNull);
      expect(container.read(accountsAvailableProvider), isFalse);
      expect(await _firstUser(container), isNull);
    });
  });

  group('a build with a backend', () {
    test('uses Supabase, with the session store', () async {
      final store = MemorySessionStore();
      final container = _container([
        backendConfigProvider.overrideWithValue(
          const BackendConfig(url: 'http://backend.test', key: 'anon-key'),
        ),
        sessionStoreProvider.overrideWithValue(store),
      ]);
      expect(
        container.read(authRepositoryProvider),
        isA<SupabaseAuthRepository>(),
      );
      expect(
        container.read(profileRepositoryProvider),
        isA<SupabaseProfileRepository>(),
      );
      expect(container.read(accountsAvailableProvider), isTrue);
      // Nothing saved: a guest, without reaching the (made-up) server.
      expect(await _firstUser(container), isNull);
    });
  });

  group('authUserProvider', () {
    test('restores once, then follows sign-in and sign-out', () async {
      final auth = FakeAuthRepository();
      final container = _container(accountOverrides(auth: auth));
      final users = _users(container);
      await pumpEventQueue();
      expect(users, [null]);

      await auth.signInWithGoogle(idToken: 'token');
      await pumpEventQueue();
      expect(users.last, testUser);

      await auth.signOut();
      await pumpEventQueue();
      expect(users.last, isNull);

      container.read(authUserProvider);
      expect(auth.restoreCalls, 1);
    });

    test('a saved session restores the user', () async {
      final container = _container(
        accountOverrides(auth: FakeAuthRepository(user: testUser)),
      );
      expect(await _firstUser(container), testUser);
    });

    test('a lost session becomes a guest', () async {
      final auth = FakeAuthRepository(user: testUser);
      final container = _container(accountOverrides(auth: auth));
      final users = _users(container);
      await pumpEventQueue();
      auth.loseSession();
      await pumpEventQueue();
      expect(users.last, isNull);
    });
  });

  group('the fakes', () {
    test('a failed sign-in throws once and stays a guest', () async {
      final auth = FakeAuthRepository()
        ..signInFailure = const NetworkFailure('offline');
      await expectLater(
        auth.signInWithGoogle(idToken: 't'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(auth.currentUser, isNull);
      expect(await auth.signInWithGoogle(idToken: 't'), testUser);
      expect(auth.idTokens, ['t', 't']);
    });

    test('profiles need a user, and rename validates', () async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository(auth);
      await expectLater(profiles.profile(), throwsA(isA<AuthFailure>()));

      await auth.signInWithGoogle(idToken: 't');
      expect((await profiles.profile()).displayName, 'Abebe Bikila');
      expect((await profiles.rename('  Abebe B. ')).displayName, 'Abebe B.');
      await expectLater(
        profiles.rename('x' * 41),
        throwsA(isA<ValidationFailure>()),
      );
      expect(profiles.renames, ['Abebe B.']);
    });

    test('a backend-less build overrides both repositories with null', () {
      final container = _container(accountOverrides(backendConfigured: false));
      expect(container.read(authRepositoryProvider), isNull);
      expect(container.read(accountsAvailableProvider), isFalse);
    });
  });

  group('SecureSessionStore', () {
    test('writes, reads and clears the session', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = SecureSessionStore();
      expect(await store.read(), isNull);
      await store.write('{"session": 1}');
      expect(await store.read(), '{"session": 1}');
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('an unreadable session is cleared and reads as none', () async {
      final storage = _BrokenStorage();
      final store = SecureSessionStore(storage);
      expect(await store.read(), isNull);
      expect(storage.deleted, [SecureSessionStore.key]);
    });
  });
}

/// Secure storage whose reads fail, as after a Keystore reset.
class _BrokenStorage extends FlutterSecureStorage {
  final deleted = <String>[];

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => throw Exception('bad decrypt');

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => deleted.add(key);
}
