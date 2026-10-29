import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

import '../../../app/backend/backend_providers.dart';
import '../data/secure_session_store.dart';

/// Where the signed-in session is kept between runs. Tests override it.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);

/// The Supabase sign-in, shared by the account repositories; null when the
/// build has no backend.
final _supabaseAuthProvider = Provider<SupabaseAuthRepository?>((ref) {
  final config = ref.watch(backendConfigProvider);
  if (!config.isConfigured) return null;
  final repository = SupabaseAuthRepository(
    url: config.url,
    key: config.key,
    store: ref.watch(sessionStoreProvider),
  );
  ref.onDispose(repository.close);
  return repository;
});

/// Signing in and out, or null when the build has no backend (no account
/// features at all). Tests override it.
final authRepositoryProvider = Provider<AuthRepository?>(
  (ref) => ref.watch(_supabaseAuthProvider),
);

/// The signed-in user's profile, or null when the build has no backend.
/// Tests override it.
final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final auth = ref.watch(_supabaseAuthProvider);
  return auth == null ? null : SupabaseProfileRepository(auth);
});

/// Whether this build offers accounts at all.
final accountsAvailableProvider = Provider<bool>(
  (ref) => ref.watch(authRepositoryProvider) != null,
);

/// The signed-in user, or null for a guest. Restores the saved session the
/// first time it is read, then follows every sign-in and sign-out.
final authUserProvider = StreamProvider<AuthUser?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  if (auth == null) return Stream.value(null);
  final users = StreamController<AuthUser?>();
  // Listen before restoring, so no change is missed.
  final changes = auth.userChanges.listen(users.add);
  ref.onDispose(() {
    unawaited(changes.cancel());
    unawaited(users.close());
  });
  unawaited(
    auth.restore().then(
      (_) => users.add(auth.currentUser),
      onError: (Object _) => users.add(null),
    ),
  );
  return users.stream;
});
