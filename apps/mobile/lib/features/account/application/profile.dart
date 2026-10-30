import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/preferences_provider.dart';
import '../data/avatar_cache.dart';
import '../data/profile_cache.dart';
import 'account_providers.dart';
import 'backup.dart';

final _log = Logger('account.profile');

/// The saved profiles. Tests read it through shared preferences.
final profileCacheProvider = Provider<ProfileCache>(
  (ref) => ProfileCache(ref.watch(sharedPreferencesProvider)),
);

/// The saved avatar images. Tests override it.
final avatarCacheProvider = Provider<AvatarCache>(
  (ref) => FileAvatarCache(
    () async => Directory(
      p.join((await getApplicationSupportDirectory()).path, 'avatar'),
    ),
  ),
);

/// The avatar image of [userId] from [url], or null while loading, offline
/// with none saved, or when it can't be had.
final avatarProvider = FutureProvider.autoDispose
    .family<Uint8List?, ({String userId, String url})>(
      (ref, avatar) =>
          ref.watch(avatarCacheProvider).load(avatar.userId, avatar.url),
    );

/// The signed-in user's profile, or null for a guest.
///
/// Shows the saved profile at once (offline too) and the server's when it
/// answers. With none saved, it waits for the server, and falls back to the
/// Google name and photo when the server can't be reached.
final profileProvider = AsyncNotifierProvider<ProfileController, Profile?>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final user = await ref.watch(authUserProvider.future);
    if (user == null) return null;
    final saved = ref.read(profileCacheProvider).read(user.id);
    if (saved != null) {
      // After build, so the saved profile shows first.
      Timer.run(() => unawaited(refresh()));
      return saved;
    }
    return await _fetch() ?? _fromGoogle(user);
  }

  /// Asks the server for the profile again; a failure keeps what's shown.
  Future<void> refresh() async {
    final profile = await _fetch();
    // Not after a sign-out or a change of user meanwhile.
    if (profile == null || !ref.mounted) return;
    if (state.value?.userId != profile.userId) return;
    state = AsyncData(profile);
  }

  /// Saves [name] as the display name on the server. Throws the
  /// [ZemaFailure] (offline, refused) and keeps the old name.
  Future<void> rename(String name) async {
    final profiles = ref.read(profileRepositoryProvider);
    if (profiles == null) throw const AuthFailure('No backend');
    final profile = await profiles.rename(name);
    await ref.read(profileCacheProvider).write(profile);
    if (ref.mounted) state = AsyncData(profile);
  }

  /// The server's profile, saved; null when it can't be had.
  Future<Profile?> _fetch() async {
    final profiles = ref.read(profileRepositoryProvider);
    if (profiles == null) return null;
    try {
      final profile = await profiles.profile();
      await ref.read(profileCacheProvider).write(profile);
      return profile;
    } on Object catch (e) {
      _log.info('Profile refresh failed', e);
      return null;
    }
  }

  static Profile _fromGoogle(AuthUser user) => Profile(
    userId: user.id,
    displayName: user.name ?? user.email ?? '',
    avatarUrl: user.avatarUrl,
  );
}

/// An account action that takes a moment.
enum AccountAction { signOut, deleteAccount }

/// Sign out and delete account, from Profile (S25): the action running, or
/// null. A second call while one runs is ignored.
final accountActionsProvider =
    NotifierProvider.autoDispose<AccountActionsController, AccountAction?>(
      AccountActionsController.new,
    );

class AccountActionsController extends Notifier<AccountAction?> {
  @override
  AccountAction? build() => null;

  /// Signs out here and of Google; local data stays. Always ends signed
  /// out. False when another action is running.
  Future<bool> signOut() => _run(AccountAction.signOut, () async {
    final auth = ref.read(authRepositoryProvider);
    final userId = auth?.currentUser?.id;
    await auth?.signOut();
    await ref.read(googleAccountPickerProvider)?.signOut();
    await _forget(userId);
  });

  /// Deletes the account on the server, then signs out here and
  /// disconnects Google. Throws the [ZemaFailure] (offline, refused) and
  /// stays signed in. False when another action is running.
  Future<bool> deleteAccount() => _run(AccountAction.deleteAccount, () async {
    final auth = ref.read(authRepositoryProvider);
    if (auth == null) throw const AuthFailure('No backend');
    final userId = auth.currentUser?.id;
    try {
      await auth.deleteAccount();
    } on ZemaFailure catch (e) {
      _log.warning('Delete account failed', e);
      rethrow;
    }
    await ref.read(googleAccountPickerProvider)?.disconnect();
    // The backup went with the account. On sign-out the status stays, so
    // signing in again knows the cloud backup is this phone's.
    if (userId != null) {
      await ref.read(backupStatusStoreProvider).remove(userId);
    }
    await _forget(userId);
  });

  Future<bool> _run(AccountAction action, Future<void> Function() run) async {
    if (state != null) return false;
    state = action;
    try {
      await run();
      return true;
    } finally {
      if (ref.mounted) state = null;
    }
  }

  Future<void> _forget(String? userId) async {
    if (userId != null) await ref.read(profileCacheProvider).remove(userId);
    // Songs not found at restore belong to that account's backup.
    await ref.read(databaseProvider).unmatchedDao.clear();
    try {
      await ref.read(avatarCacheProvider).clear();
    } on Object catch (e) {
      _log.warning('Clearing the avatar failed', e);
    }
  }
}
