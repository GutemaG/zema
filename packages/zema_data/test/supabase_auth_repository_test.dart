import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

/// Unit tests with a fake HTTP client: no backend needed.
void main() {
  final requests = <http.Request>[];
  late MemorySessionStore store;
  late SupabaseAuthRepository auth;

  const userId = '00000000-0000-0000-0000-00000000000a';

  /// An unsigned access token for [userId] expiring in [validFor] (the
  /// client only reads its expiry).
  String accessToken({Duration validFor = const Duration(hours: 1)}) {
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final exp = DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000;
    return '${part({'alg': 'none'})}.${part({'sub': userId, 'exp': exp})}.x';
  }

  Map<String, Object?> sessionJson({
    Duration validFor = const Duration(hours: 1),
    Map<String, Object?> meta = const {
      'full_name': 'Abebe Bikila',
      'picture': 'https://example.com/a.png',
    },
  }) => {
    'access_token': accessToken(validFor: validFor),
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh-1',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'email': 'abebe@example.com',
      'app_metadata': <String, Object?>{},
      'user_metadata': meta,
      'created_at': '2026-10-29T00:00:00Z',
    },
  };

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  /// A repository whose every request is answered by [answer].
  void answerWith(
    FutureOr<http.Response> Function(http.Request request) answer, {
    String? saved,
  }) {
    store = MemorySessionStore(saved);
    auth = SupabaseAuthRepository(
      url: 'http://backend.test',
      key: 'anon-key',
      store: store,
      timeout: const Duration(seconds: 2),
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await answer(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
  }

  setUp(requests.clear);
  tearDown(() => auth.close());

  group('restore', () {
    test('with nothing saved is a guest, without a request', () async {
      answerWith((_) => json({}));
      expect(await auth.restore(), isNull);
      expect(auth.currentUser, isNull);
      expect(requests, isEmpty);
    });

    test('an unreadable saved session is cleared', () async {
      answerWith((_) => json({}), saved: 'not json');
      expect(await auth.restore(), isNull);
      await pumpEventQueue();
      expect(store.session, isNull);
    });

    test('a valid saved session signs in at once, with no request', () async {
      answerWith((_) => json({}), saved: jsonEncode(sessionJson()));
      final user = await auth.restore();
      await auth.confirmed;
      expect(
        user,
        const AuthUser(
          id: userId,
          email: 'abebe@example.com',
          name: 'Abebe Bikila',
          avatarUrl: 'https://example.com/a.png',
        ),
      );
      expect(requests, isEmpty);
    });
  });

  group('signInWithGoogle', () {
    test('sends the ID token and saves the session', () async {
      answerWith((_) => json(sessionJson()));
      final changes = <AuthUser?>[];
      auth.userChanges.listen(changes.add);

      final user = await auth.signInWithGoogle(
        idToken: 'google-id-token',
        accessToken: 'google-access',
      );
      await pumpEventQueue();

      final request = requests.single;
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'id_token');
      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body['provider'], 'google');
      expect(body['id_token'], 'google-id-token');
      expect(body['access_token'], 'google-access');

      expect(user.name, 'Abebe Bikila');
      expect(auth.currentUser, user);
      expect(changes, [user]);
      final saved = jsonDecode(store.session!) as Map<String, Object?>;
      expect(saved['refresh_token'], 'refresh-1');
    });

    test('a refused token is an AuthFailure; still a guest', () async {
      answerWith(
        (_) => json({
          'code': 400,
          'error_code': 'bad_jwt',
          'msg': 'Bad ID token',
        }, 400),
      );
      await expectLater(
        auth.signInWithGoogle(idToken: 'bad'),
        throwsA(isA<AuthFailure>()),
      );
      expect(auth.currentUser, isNull);
      expect(store.session, isNull);
    });

    test('no connection is a NetworkFailure', () async {
      answerWith((_) => throw http.ClientException('offline'));
      await expectLater(
        auth.signInWithGoogle(idToken: 'token'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(auth.currentUser, isNull);
    });

    test('Google name falls back to "name"; a blank one is null', () async {
      answerWith(
        (_) => json(sessionJson(meta: {'name': 'Tigist', 'full_name': ' '})),
      );
      expect((await auth.signInWithGoogle(idToken: 't')).name, 'Tigist');
    });
  });

  group('signOut', () {
    test('offline still signs out and clears the store', () async {
      answerWith(
        (_) => throw http.ClientException('offline'),
        saved: jsonEncode(sessionJson()),
      );
      await auth.restore();
      await auth.confirmed;
      final changes = <AuthUser?>[];
      auth.userChanges.listen(changes.add);

      await auth.signOut();
      await pumpEventQueue();

      expect(auth.currentUser, isNull);
      expect(store.session, isNull);
      expect(changes, [null]);
    });
  });

  group('profiles', () {
    test('need a signed-in user', () async {
      answerWith((_) => json({}));
      await expectLater(
        SupabaseProfileRepository(auth).profile(),
        throwsA(isA<AuthFailure>()),
      );
      expect(requests, isEmpty);
    });

    test('a bad name is refused before any request', () async {
      answerWith((_) => json({}), saved: jsonEncode(sessionJson()));
      await auth.restore();
      await expectLater(
        SupabaseProfileRepository(auth).rename('x' * 41),
        throwsA(isA<ValidationFailure>()),
      );
      expect(requests, isEmpty);
    });

    test("the server's name check is a ValidationFailure", () async {
      answerWith(
        (_) => json({
          'code': '23514',
          'message': 'violates check constraint',
          'details': null,
          'hint': null,
        }, 400),
        saved: jsonEncode(sessionJson()),
      );
      await auth.restore();
      await expectLater(
        SupabaseProfileRepository(auth).rename('Fine name'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('reads the profile and known roles, as the user', () async {
      answerWith((request) {
        if (request.url.path.endsWith('/profiles')) {
          return json([
            {'display_name': 'Abebe', 'avatar_url': null},
          ]);
        }
        return json([
          {'role': 'contributor'},
          {'role': 'moderator'},
          {'role': 'someday'},
        ]);
      }, saved: jsonEncode(sessionJson()));
      await auth.restore();

      final profile = await SupabaseProfileRepository(auth).profile();
      expect(
        profile,
        const Profile(
          userId: userId,
          displayName: 'Abebe',
          roles: {AccountRole.contributor, AccountRole.moderator},
        ),
      );
      expect(profile.isModerator, isTrue);
      expect(
        requests.first.headers['Authorization'],
        startsWith('Bearer ${accessToken().split('.').first}'),
        reason: "calls carry the user's token, not the anon key",
      );
      expect(requests.first.url.queryParameters['id'], 'eq.$userId');
    });
  });
}
