@Tags(['backend'])
library;

import 'dart:convert';
import 'dart:math';

import 'package:supabase/supabase.dart' hide AuthUser;
import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

import 'support/local_backend.dart';

/// Sign-in, sessions and profiles against the local backend.
///
/// Google can't sign in here, so each test signs a user up by email with a
/// separate client and hands the session to the repository, as a saved
/// session from an earlier run.
void main() {
  final key = localAnonKey();
  final skip = key == null ? backendNotRunning : null;
  final open = <SupabaseAuthRepository>[];
  final random = Random();

  SupabaseAuthRepository connect(
    SessionStore store, {
    String url = localUrl,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final repository = SupabaseAuthRepository(
      url: url,
      key: key!,
      store: store,
      timeout: timeout,
    );
    open.add(repository);
    return repository;
  }

  /// A new user signed up as Google would name them; their session as saved
  /// JSON.
  Future<String> signUp({String name = 'Test User'}) async {
    final client = SupabaseClient(
      localUrl,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    try {
      final response = await client.auth.signUp(
        email: 'zema-data-${random.nextInt(1 << 32)}@example.com',
        password: 'Test-pass-12345',
        data: {'full_name': name, 'avatar_url': 'https://example.com/a.png'},
      );
      return jsonEncode(response.session!.toJson());
    } finally {
      await client.dispose();
    }
  }

  /// [session] with an access token that expired an hour ago, keeping the
  /// real refresh token (the client reads the expiry from the token itself;
  /// only the refresh token reaches the server).
  String expired(String session) {
    final json = jsonDecode(session) as Map<String, Object?>;
    final user = json['user']! as Map<String, Object?>;
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final exp =
        DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch ~/
        1000;
    json['access_token'] =
        '${part({'alg': 'none'})}.${part({'sub': user['id'], 'exp': exp})}.x';
    return jsonEncode(json);
  }

  String accessToken(String? session) =>
      (jsonDecode(session!) as Map<String, Object?>)['access_token']! as String;

  /// Deletes the signed-in user, so the tests leave nothing behind.
  Future<void> deleteAccount(SupabaseAuthRepository auth) => auth.run(
    'delete_account',
    (client, _) => client.rpc<void>('delete_account'),
  );

  tearDown(() async {
    for (final r in open) {
      await r.close();
    }
    open.clear();
  });

  group('the local backend', skip: skip, () {
    test('restores a saved session: user, profile and roles', () async {
      final store = MemorySessionStore(await signUp(name: '  Almaz Ayana '));
      final auth = connect(store);

      final user = await auth.restore();
      expect(user?.name, '  Almaz Ayana ');
      expect(user?.avatarUrl, 'https://example.com/a.png');
      expect(auth.currentUser, user);

      final profile = await SupabaseProfileRepository(auth).profile();
      expect(profile.userId, user!.id);
      expect(profile.displayName, 'Almaz Ayana');
      expect(profile.avatarUrl, 'https://example.com/a.png');
      expect(profile.roles, {AccountRole.contributor});
      expect(profile.isModerator, isFalse);

      await deleteAccount(auth);
    });

    test('renames, trimmed; a bad name is refused before sending', () async {
      final auth = connect(MemorySessionStore(await signUp()));
      await auth.restore();
      final profiles = SupabaseProfileRepository(auth);

      expect((await profiles.rename('  Abebe B. ')).displayName, 'Abebe B.');
      expect((await profiles.profile()).displayName, 'Abebe B.');
      await expectLater(
        profiles.rename('x' * 41),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        profiles.rename('   '),
        throwsA(isA<ValidationFailure>()),
      );
      expect((await profiles.profile()).displayName, 'Abebe B.');

      await deleteAccount(auth);
    });

    test('an expired session is refreshed on restore and saved', () async {
      final saved = expired(await signUp());
      final store = MemorySessionStore(saved);
      final auth = connect(store);

      expect(await auth.restore(), isNotNull);
      await auth.confirmed;
      await pumpEventQueue();
      expect(
        accessToken(store.session) != accessToken(saved),
        isTrue,
        reason: 'a new access token was saved',
      );
      expect(
        (await SupabaseProfileRepository(auth).profile()).displayName,
        'Test User',
      );

      await deleteAccount(auth);
    });

    test('sign out clears the store and tells listeners', () async {
      final store = MemorySessionStore(await signUp());
      final auth = connect(store);
      final user = await auth.restore();
      final changes = <AuthUser?>[];
      auth.userChanges.listen(changes.add);

      // Keep a copy to delete the user afterwards.
      final copy = store.session!;
      await auth.signOut();
      await pumpEventQueue();

      expect(auth.currentUser, isNull);
      expect(store.session, isNull);
      expect(changes, [null]);
      await expectLater(
        SupabaseProfileRepository(auth).profile(),
        throwsA(isA<AuthFailure>()),
      );

      // Signing out locally keeps the server session; clean up through it.
      final cleanup = connect(MemorySessionStore(copy));
      expect((await cleanup.restore())?.id, user!.id);
      await deleteAccount(cleanup);
    });

    test('a session the server refused becomes the guest state', () async {
      final saved = await signUp();
      // Sign out everywhere, which revokes the refresh token.
      final other = connect(MemorySessionStore(saved));
      await other.restore();
      await other.client.auth.signOut(scope: SignOutScope.global);

      final store = MemorySessionStore(expired(saved));
      final auth = connect(store);
      final changes = <AuthUser?>[];
      auth.userChanges.listen(changes.add);
      expect(await auth.restore(), isNotNull, reason: 'signed in at once');
      await auth.confirmed;
      await pumpEventQueue();
      expect(changes.last, isNull, reason: 'then signed out');
      expect(auth.currentUser, isNull);
      expect(store.session, isNull);
      // The user is left behind (no session to delete it with); local only.
    });

    test(
      'offline with an expired session: still signed in, retried later',
      () async {
        final saved = expired(await signUp());
        final store = MemorySessionStore(saved);
        final offline = connect(
          store,
          url: 'http://127.0.0.1:9',
          timeout: const Duration(seconds: 2),
        );

        final user = await offline.restore();
        expect(user, isNotNull, reason: 'the saved user stays signed in');
        expect(offline.currentUser, user);
        expect(store.session, saved, reason: 'the saved session is kept');
        await expectLater(
          SupabaseProfileRepository(offline).profile(),
          throwsA(isA<NetworkFailure>()),
        );
        expect(offline.currentUser, user);

        // Back online, the same saved session refreshes.
        final online = connect(store);
        expect((await online.restore())?.id, user!.id);
        await deleteAccount(online);
      },
    );

    test('after delete_account the profile is gone', () async {
      final auth = connect(MemorySessionStore(await signUp()));
      await auth.restore();
      await deleteAccount(auth);
      await expectLater(
        SupabaseProfileRepository(auth).profile(),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
