import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:zema/features/account/application/account_providers.dart';
import 'package:zema/features/account/data/google_account_picker.dart';
import 'package:zema_core/zema_core.dart';

/// A test user, as Google sign-in would give them.
const testUser = AuthUser(
  id: '00000000-0000-0000-0000-00000000000a',
  email: 'abebe@example.com',
  name: 'Abebe Bikila',
  avatarUrl: 'https://example.com/abebe.png',
);

/// Sign-in in memory: a guest unless [user] is given (as if restored from
/// an earlier run).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? user}) : _saved = user;

  /// The user a saved session would restore.
  final AuthUser? _saved;

  AuthUser? _user;
  final _changes = StreamController<AuthUser?>.broadcast();

  /// The user the next [signInWithGoogle] signs in.
  AuthUser signInAs = testUser;

  /// Thrown by the next [signInWithGoogle] when set (then cleared).
  ZemaFailure? signInFailure;

  /// When set, [signInWithGoogle] waits for it before answering.
  Completer<void>? signInGate;

  /// The ID tokens signed in with, in order.
  final idTokens = <String>[];
  var restoreCalls = 0;
  var signOutCalls = 0;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  @override
  Future<AuthUser?> restore() async {
    restoreCalls++;
    _set(_saved);
    return _user;
  }

  @override
  Future<AuthUser> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {
    idTokens.add(idToken);
    await signInGate?.future;
    final failure = signInFailure;
    if (failure != null) {
      signInFailure = null;
      throw failure;
    }
    _set(signInAs);
    return signInAs;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _set(null);
  }

  /// Signs out as if the server refused the session.
  void loseSession() => _set(null);

  void _set(AuthUser? user) {
    _user = user;
    _changes.add(user);
  }
}

/// Profiles in memory, for the signed-in user of [auth].
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.auth, {this._profile});

  final AuthRepository auth;
  Profile? _profile;

  /// Thrown by every call when set.
  ZemaFailure? failure;

  /// The names renamed to, in order.
  final renames = <String>[];

  @override
  Future<Profile> profile() async {
    final user = _signedIn();
    return _profile ??= Profile(
      userId: user.id,
      displayName: user.name ?? user.email ?? 'Zema user',
      avatarUrl: user.avatarUrl,
    );
  }

  @override
  Future<Profile> rename(String name) async {
    final valid = validateDisplayName(name);
    final current = await profile();
    renames.add(valid);
    return _profile = current.copyWith(displayName: valid);
  }

  AuthUser _signedIn() {
    final failure = this.failure;
    if (failure != null) throw failure;
    return auth.currentUser ?? (throw const AuthFailure('not signed in'));
  }
}

/// The Google account picker, answering with [tokens] until told otherwise.
class FakeGoogleAccountPicker implements GoogleAccountPicker {
  /// What the next [pick] gives; null is a cancel.
  GoogleTokens? tokens = const GoogleTokens(idToken: 'google-id-token');

  /// Thrown by the next [pick] when set (then cleared).
  Object? failure;

  /// When set, [pick] waits for it before answering.
  Completer<void>? gate;

  var picks = 0;
  var signOutCalls = 0;

  @override
  Future<GoogleTokens?> pick() async {
    picks++;
    await gate?.future;
    final failure = this.failure;
    if (failure != null) {
      this.failure = null;
      throw failure;
    }
    return tokens;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}

/// Overrides for the account repositories: [auth] (a guest by default) and
/// [profiles] over it, or none when [backendConfigured] is false. Sign-in is
/// offered only with a [picker] (none by default, as in a build without
/// Google client IDs), so the account choice (S04) stays away.
List<Override> accountOverrides({
  AuthRepository? auth,
  ProfileRepository? profiles,
  GoogleAccountPicker? picker,
  bool backendConfigured = true,
}) {
  if (!backendConfigured) {
    return [
      authRepositoryProvider.overrideWithValue(null),
      profileRepositoryProvider.overrideWithValue(null),
      googleAccountPickerProvider.overrideWithValue(picker),
    ];
  }
  final authRepository = auth ?? FakeAuthRepository();
  return [
    googleAccountPickerProvider.overrideWithValue(picker),
    authRepositoryProvider.overrideWithValue(authRepository),
    profileRepositoryProvider.overrideWithValue(
      profiles ?? FakeProfileRepository(authRepository),
    ),
  ];
}
