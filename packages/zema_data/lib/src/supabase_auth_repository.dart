import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart' hide AuthUser;
import 'package:zema_core/zema_core.dart';

import 'backend_errors.dart';
import 'session_store.dart';

/// Sign-in with Supabase Auth (see `backend/`), keeping the session in a
/// [SessionStore] so it survives restarts.
///
/// Every request gives up after [timeout]. [restore] signs the saved user in
/// at once and checks the session with the server in the background
/// ([confirmed]): one the server refuses is cleared, which signs out; one
/// that can't be checked because the server is out of reach stays signed in,
/// and [run] tries again before each call.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required String url,
    required String key,
    required this._store,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 10),
  }) : client = SupabaseClient(
         url,
         key,
         httpClient: TimeoutClient(httpClient ?? http.Client(), timeout),
       ) {
    // Refresh failures are reported on this stream too; they are handled
    // where the refresh was asked for.
    _authEvents = client.auth.onAuthStateChange.listen(
      _onAuthState,
      onError: (Object _) {},
    );
  }

  /// The client calls are made with, as the signed-in user once there is
  /// one. For zema_data's other repositories only; use [run].
  final SupabaseClient client;

  final SessionStore _store;
  late final StreamSubscription<AuthState> _authEvents;
  final _changes = StreamController<AuthUser?>.broadcast();

  /// Store writes, in order, so a clear never lands before an older write.
  Future<void> _storeWrites = Future.value();

  /// A saved session the server has not accepted yet (offline at start).
  String? _unconfirmed;

  AuthUser? _user;

  Future<void> _confirming = Future.value();

  /// Completes once the session [restore] loaded has been checked with the
  /// server, or the check failed because the server was out of reach.
  Future<void> get confirmed => _confirming;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  @override
  Future<AuthUser?> restore() async {
    final String? saved;
    try {
      saved = await _store.read();
    } on Object {
      await _signedOut();
      return null;
    }
    if (saved == null) return null;
    final user = _userOfJson(saved);
    if (user == null) {
      await _signedOut();
      return null;
    }
    _unconfirmed = saved;
    _setUser(user);
    _confirming = _recover(saved).then(
      (_) {},
      // Offline: stays unconfirmed. Refused: already signed out.
      onError: (Object _) {},
    );
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {
    final AuthResponse response;
    try {
      response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on Object catch (e) {
      throw _authFailure('signInWithGoogle', e);
    }
    final session = response.session;
    if (session == null) {
      throw const AuthFailure('signInWithGoogle: no session in the answer');
    }
    _signedIn(session);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on Object {
      // Offline or already gone on the server: signed out here regardless.
    }
    await _signedOut();
  }

  @override
  Future<void> deleteAccount() async {
    await run(
      'deleteAccount',
      (client, _) => client.rpc<void>('delete_account'),
    );
    // The server has already ended every session; this clears the phone's.
    await signOut();
  }

  /// Runs [call] as the signed-in user, after refreshing a session that the
  /// server hasn't confirmed yet. Errors become [ZemaFailure]s:
  /// [AuthFailure] when not signed in or the session is refused.
  Future<T> run<T>(
    String function,
    Future<T> Function(SupabaseClient client, String userId) call,
  ) async {
    await _confirming;
    final unconfirmed = _unconfirmed;
    if (unconfirmed != null) await _recover(unconfirmed);
    final userId = client.auth.currentSession?.user.id;
    if (userId == null) throw AuthFailure('$function: not signed in');
    try {
      return await call(client, userId);
    } on Object catch (e) {
      final failure = backendFailure(function, e, userSession: true);
      if (failure is AuthFailure) await _refreshOrSignOut();
      throw failure;
    }
  }

  /// Releases the client's connections and timers.
  Future<void> close() async {
    await _authEvents.cancel();
    await _changes.close();
    await _confirming;
    await _storeWrites;
    await client.dispose();
  }

  /// Sets the saved session [saved] on the client, refreshing it if it has
  /// expired. A [NetworkFailure] leaves things as they were; a refusal signs
  /// out and throws [AuthFailure].
  Future<void> _recover(String saved) async {
    final AuthResponse response;
    try {
      response = await client.auth.recoverSession(saved);
    } on Object catch (e) {
      final failure = _authFailure('restore', e);
      if (failure is AuthFailure) await _signedOut();
      throw failure;
    }
    _unconfirmed = null;
    final session = response.session;
    if (session != null) _signedIn(session);
  }

  /// After a refused token: one refresh, and sign out if that fails too.
  Future<void> _refreshOrSignOut() async {
    try {
      await client.auth.refreshSession();
    } on AuthRetryableFetchException {
      // Offline: keep the session and try again on the next call.
    } on Object {
      await _signedOut();
    }
  }

  void _onAuthState(AuthState state) {
    switch (state.event) {
      case AuthChangeEvent.signedIn ||
          AuthChangeEvent.tokenRefreshed ||
          AuthChangeEvent.userUpdated:
        final session = state.session;
        if (session != null) _signedIn(session);
      case AuthChangeEvent.signedOut:
        unawaited(_signedOut());
      default:
        break;
    }
  }

  void _signedIn(Session session) {
    _unconfirmed = null;
    final json = jsonEncode(session.toJson());
    _storeWrites = _storeWrites.then((_) => _store.write(json));
    _setUser(_userOf(session.user));
  }

  Future<void> _signedOut() {
    _unconfirmed = null;
    _storeWrites = _storeWrites.then((_) => _store.clear()).catchError((_) {});
    _setUser(null);
    return _storeWrites;
  }

  void _setUser(AuthUser? user) {
    if (user == _user) return;
    _user = user;
    if (!_changes.isClosed) _changes.add(user);
  }
}

/// An [AuthFailure] when the server refused, a [NetworkFailure] when it
/// couldn't be reached.
ZemaFailure _authFailure(String function, Object e) => switch (e) {
  ZemaFailure() => e,
  AuthRetryableFetchException() => NetworkFailure(
    '$function: ${e.message}',
    cause: e,
  ),
  AuthException() => AuthFailure(
    '$function: ${e.code ?? e.statusCode} ${e.message}',
    cause: e,
  ),
  _ => NetworkFailure('$function: $e', cause: e),
};

AuthUser _userOf(User user) {
  final meta = user.userMetadata ?? const {};
  String? text(String key) => switch (meta[key]) {
    final String value when value.trim().isNotEmpty => value,
    _ => null,
  };
  return AuthUser(
    id: user.id,
    email: user.email,
    name: text('full_name') ?? text('name'),
    avatarUrl: text('avatar_url') ?? text('picture'),
  );
}

/// The user of a saved session, or null when [json] isn't one.
AuthUser? _userOfJson(String json) {
  try {
    final session = Session.fromJson(
      (jsonDecode(json) as Map).cast<String, dynamic>(),
    );
    return session == null ? null : _userOf(session.user);
  } on Object {
    return null;
  }
}
