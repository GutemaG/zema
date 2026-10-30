import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/misc.dart';
import 'package:zema/features/account/application/account_providers.dart';
import 'package:zema/features/account/application/auto_backup.dart';
import 'package:zema/features/account/application/profile.dart';
import 'package:zema/features/account/data/avatar_cache.dart';
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
    // A sign-in before the restore has saved its own session, as the real
    // store would.
    if (_user == null) _set(_saved);
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

  /// Thrown by the next [deleteAccount] when set (then cleared).
  ZemaFailure? deleteFailure;

  /// When set, [deleteAccount] waits for it before answering.
  Completer<void>? deleteGate;

  var deleteCalls = 0;

  @override
  Future<void> deleteAccount() async {
    if (_user == null) throw const AuthFailure('not signed in');
    deleteCalls++;
    await deleteGate?.future;
    final failure = deleteFailure;
    if (failure != null) {
      deleteFailure = null;
      throw failure;
    }
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

  /// When set, [signOut] and [disconnect] wait for it, as the plugin
  /// takes a moment.
  Completer<void>? signOutGate;

  var picks = 0;
  var signOutCalls = 0;
  var disconnectCalls = 0;

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
  Future<void> signOut() async {
    signOutCalls++;
    await signOutGate?.future;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    await signOutGate?.future;
  }
}

/// A 1×1 PNG, a stand-in avatar.
final testAvatar = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x38, 0x31, 0x41, 0xEB, //
  0x3F, 0x00, 0x06, 0x28, 0x02, 0x82, 0x73, 0x84, 0x85, 0x06, 0x00, 0x00, //
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

/// Avatars in memory: every URL gives [image] (null: none to show).
class FakeAvatarCache implements AvatarCache {
  Uint8List? image = testAvatar;

  /// The URLs loaded, in order.
  final loads = <String>[];
  var clearCalls = 0;

  @override
  Future<Uint8List?> load(String userId, String url) async {
    loads.add(url);
    return image;
  }

  @override
  Future<void> clear() async => clearCalls++;
}

/// Overrides for the account repositories: [auth] (a guest by default) and
/// [profiles] over it, or none when [backendConfigured] is false; avatars
/// from [avatars], a [FakeAvatarCache] by default. Sign-in is
/// offered only with a [picker] (none by default, as in a build without
/// Google client IDs), so the account choice (S04) stays away.
/// The user's one cloud backup, in memory.
class FakeBackupRepository implements BackupRepository {
  FakeBackupRepository({this.stored});

  StoredBackup? stored;

  /// Thrown by the next call when set (then cleared).
  ZemaFailure? failure;

  /// When set, [save] waits for it before saving.
  Completer<void>? saveGate;

  /// Every document saved, in order.
  final saves = <BackupDocument>[];
  var fetches = 0;

  /// The server's clock: each save is a second after the last.
  DateTime clock = DateTime.utc(2026, 10, 30, 12);

  void _fail() {
    final f = failure;
    failure = null;
    if (f != null) throw f;
  }

  @override
  Future<DateTime?> savedAt() async {
    _fail();
    return stored?.savedAt;
  }

  @override
  Future<StoredBackup?> fetch() async {
    _fail();
    fetches++;
    return stored;
  }

  @override
  Future<DateTime> save(BackupDocument document) async {
    _fail();
    await saveGate?.future;
    clock = clock.add(const Duration(seconds: 1));
    saves.add(document);
    stored = StoredBackup(document: document, savedAt: clock);
    return clock;
  }
}

List<Override> accountOverrides({
  AuthRepository? auth,
  ProfileRepository? profiles,
  GoogleAccountPicker? picker,
  AvatarCache? avatars,
  BackupRepository? backups,
  bool Function()? onWifi,
  bool backendConfigured = true,
}) {
  final avatarCache = avatarCacheProvider.overrideWithValue(
    avatars ?? FakeAvatarCache(),
  );
  // Off Wi-Fi by default, so auto backup stays out of other tests.
  final network = unmeteredNetworkProvider.overrideWithValue(
    () async => onWifi?.call() ?? false,
  );
  if (!backendConfigured) {
    return [
      avatarCache,
      network,
      authRepositoryProvider.overrideWithValue(null),
      profileRepositoryProvider.overrideWithValue(null),
      backupRepositoryProvider.overrideWithValue(null),
      googleAccountPickerProvider.overrideWithValue(picker),
    ];
  }
  final authRepository = auth ?? FakeAuthRepository();
  return [
    avatarCache,
    network,
    googleAccountPickerProvider.overrideWithValue(picker),
    authRepositoryProvider.overrideWithValue(authRepository),
    profileRepositoryProvider.overrideWithValue(
      profiles ?? FakeProfileRepository(authRepository),
    ),
    backupRepositoryProvider.overrideWithValue(
      backups ?? FakeBackupRepository(),
    ),
  ];
}
