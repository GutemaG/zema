import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

import 'config.dart';

/// The page's address and moving away from it; the browser's in the site,
/// a fake in tests.
abstract interface class Browser {
  Uri get location;

  /// Leaves the site for [url].
  void go(Uri url);

  /// Changes the address bar to [url] without loading it.
  void replaceLocation(Uri url);
}

/// Who is using the site.
sealed class AdminSession {
  const AdminSession();
}

class SignedOut extends AdminSession {
  const SignedOut({this.error});

  /// Why the last sign-in failed, if it did.
  final String? error;
}

class NotModerator extends AdminSession {
  const NotModerator(this.user);

  final AuthUser user;
}

class Moderator extends AdminSession {
  const Moderator(this.user, this.profile);

  final AuthUser user;
  final Profile profile;
}

final adminConfigProvider = Provider<AdminConfig>(
  (_) => const AdminConfig.fromEnvironment(),
);

/// Set in `main.dart` (browser storage) and in tests.
final sessionStoreProvider = Provider<SessionStore>(
  (_) => throw UnimplementedError('sessionStoreProvider'),
);
final redirectStorageProvider = Provider<GotrueAsyncStorage?>((_) => null);

final browserProvider = Provider<Browser>(
  (_) => throw UnimplementedError('browserProvider'),
);

/// The sign-in calls the site makes; [SupabaseAuthRepository] in the site.
abstract interface class AdminAuth {
  Future<AuthUser?> restore();

  Future<Uri> googleRedirectUrl(Uri returnTo);

  Future<AuthUser> completeRedirectSignIn(String code);

  Future<void> signOut();
}

class _SupabaseAdminAuth implements AdminAuth {
  const _SupabaseAdminAuth(this._auth);

  final SupabaseAuthRepository _auth;

  @override
  Future<AuthUser?> restore() => _auth.restore();

  @override
  Future<Uri> googleRedirectUrl(Uri returnTo) =>
      _auth.googleRedirectUrl(returnTo);

  @override
  Future<AuthUser> completeRedirectSignIn(String code) =>
      _auth.completeRedirectSignIn(code);

  @override
  Future<void> signOut() => _auth.signOut();
}

final adminAuthProvider = Provider<AdminAuth>(
  (ref) => _SupabaseAdminAuth(ref.watch(authProvider)),
);

final authProvider = Provider<SupabaseAuthRepository>((ref) {
  final config = ref.watch(adminConfigProvider);
  final auth = SupabaseAuthRepository(
    url: config.url,
    key: config.key,
    store: ref.watch(sessionStoreProvider),
    redirectStorage: ref.watch(redirectStorageProvider),
  );
  ref.onDispose(auth.close);
  return auth;
});

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(authProvider)),
);

final contributionRepositoryProvider = Provider<ContributionRepository>(
  (ref) => SupabaseContributionRepository(ref.watch(authProvider)),
);

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => SupabaseModerationRepository(ref.watch(authProvider)),
);

final sessionProvider = AsyncNotifierProvider<SessionNotifier, AdminSession>(
  SessionNotifier.new,
);

/// Signs in on load when Google sent the browser back with a code, or
/// restores the saved session; then reads the user's roles.
class SessionNotifier extends AsyncNotifier<AdminSession> {
  @override
  Future<AdminSession> build() async {
    final browser = ref.watch(browserProvider);
    final auth = ref.watch(adminAuthProvider);
    final query = browser.location.queryParameters;
    final code = query['code'];
    final error = query['error_description'] ?? query['error'];
    if (code != null || error != null) browser.replaceLocation(_home(browser));
    if (error != null) return SignedOut(error: error);
    final AuthUser? user;
    try {
      user = code != null
          ? await auth.completeRedirectSignIn(code)
          : await auth.restore();
    } on AuthFailure catch (e) {
      return SignedOut(error: e.message);
    }
    if (user == null) return const SignedOut();
    return _withRole(user);
  }

  /// Sends the browser to Google; it comes back to this page.
  Future<void> signIn() async {
    final browser = ref.read(browserProvider);
    try {
      browser.go(
        await ref.read(adminAuthProvider).googleRedirectUrl(_home(browser)),
      );
    } on ZemaFailure catch (e) {
      state = AsyncData(SignedOut(error: e.message));
    }
  }

  Future<void> signOut() async {
    await ref.read(adminAuthProvider).signOut();
    state = const AsyncData(SignedOut());
  }

  Future<AdminSession> _withRole(AuthUser user) async {
    final profile = await ref.read(profileRepositoryProvider).profile();
    return profile.isModerator ? Moderator(user, profile) : NotModerator(user);
  }

  /// This page without its query: where Google sends the browser back.
  static Uri _home(Browser browser) {
    final here = browser.location;
    return Uri(
      scheme: here.scheme,
      host: here.host,
      port: here.hasPort ? here.port : null,
      path: here.path,
    );
  }
}
