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

    test('deleteAccount removes the user and signs out here', () async {
      final store = MemorySessionStore(await signUp());
      final saved = store.session!;
      final auth = connect(store);
      await auth.restore();

      await auth.deleteAccount();

      expect(auth.currentUser, isNull);
      expect(store.session, isNull);
      // Its refresh token went with the user, so the old session can't
      // come back once its access token expires.
      final again = connect(MemorySessionStore(expired(saved)));
      await again.restore();
      await again.confirmed;
      expect(again.currentUser, isNull);
    });
  });

  group('backups on the local backend', skip: skip, () {
    final document = BackupDocument(
      createdAt: DateTime.utc(2026, 10, 30, 12),
      favorites: [
        BackupFavorite(
          track: const TrackIdentity(
            title: 'Tizita',
            artist: 'Mahmoud Ahmed',
            durationMs: 241000,
            fileName: 'Tizita.mp3',
          ),
          addedAt: DateTime.utc(2026, 1, 2),
        ),
      ],
      settings: const {'themeMode': 'dark'},
      extras: const {
        'futureSection': [1, 2],
      },
    );

    test('none at first; save, then read it back exactly', () async {
      final auth = connect(MemorySessionStore(await signUp()));
      await auth.restore();
      final backups = SupabaseBackupRepository(auth);

      expect(await backups.savedAt(), isNull);
      expect(await backups.fetch(), isNull);

      final before = DateTime.now().toUtc().subtract(
        const Duration(minutes: 1),
      );
      final savedAt = await backups.save(document);
      expect(savedAt.isUtc, isTrue);
      expect(savedAt.isAfter(before), isTrue);
      expect(await backups.savedAt(), savedAt);

      final stored = await backups.fetch();
      expect(stored!.savedAt, savedAt);
      expect(stored.document, document);

      await deleteAccount(auth);
    });

    test('a save replaces the previous backup', () async {
      final auth = connect(MemorySessionStore(await signUp()));
      await auth.restore();
      final backups = SupabaseBackupRepository(auth);

      final first = await backups.save(document);
      final second = await backups.save(
        BackupDocument(createdAt: DateTime.utc(2026, 11)),
      );
      expect(second.isAfter(first), isTrue);
      final stored = await backups.fetch();
      expect(stored!.document.favorites, isEmpty);
      expect(stored.document.createdAt, DateTime.utc(2026, 11));

      await deleteAccount(auth);
    });

    test("users can't read each other's backups", () async {
      final alice = connect(MemorySessionStore(await signUp()));
      final bob = connect(MemorySessionStore(await signUp()));
      await alice.restore();
      await bob.restore();
      await SupabaseBackupRepository(alice).save(document);

      expect(await SupabaseBackupRepository(bob).fetch(), isNull);

      await deleteAccount(alice);
      await deleteAccount(bob);
    });

    test('a backup from a newer app says so', () async {
      final auth = connect(MemorySessionStore(await signUp()));
      await auth.restore();
      await auth.run(
        'save newer',
        (client, _) => client.rpc<Object?>(
          'save_backup',
          params: {
            'document': {'format': 2, 'createdAt': '2027-01-01T00:00:00Z'},
            'format': 2,
          },
        ),
      );

      await expectLater(
        SupabaseBackupRepository(auth).fetch(),
        throwsA(
          isA<BackupFormatFailure>().having(
            (f) => f.newerFormat,
            'newerFormat',
            isTrue,
          ),
        ),
      );

      await deleteAccount(auth);
    });

    test('offline: NetworkFailure', () async {
      final store = MemorySessionStore(await signUp());
      final auth = connect(store);
      await auth.restore();
      final offline = connect(
        MemorySessionStore(await store.read()),
        url: 'http://127.0.0.1:9',
        timeout: const Duration(seconds: 2),
      );
      await offline.restore();

      await expectLater(
        SupabaseBackupRepository(offline).save(document),
        throwsA(isA<NetworkFailure>()),
      );

      await deleteAccount(auth);
    });

    test('a guest gets AuthFailure', () async {
      final backups = SupabaseBackupRepository(connect(MemorySessionStore()));
      await expectLater(backups.savedAt(), throwsA(isA<AuthFailure>()));
      await expectLater(backups.save(document), throwsA(isA<AuthFailure>()));
    });
  });
}
