import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/preferences_provider.dart';
import 'account_providers.dart';

final _log = Logger('account.sign_in');

/// Whether the one-time account choice (S04) is still to be shown: sign-in
/// is available and the user hasn't picked guest or sign in yet.
final accountChoicePendingProvider =
    NotifierProvider<AccountChoiceController, bool>(
      AccountChoiceController.new,
    );

class AccountChoiceController extends Notifier<bool> {
  static const key = 'accountChoiceShown';

  @override
  bool build() =>
      ref.watch(signInAvailableProvider) &&
      !(ref.read(sharedPreferencesProvider).getBool(key) ?? false);

  /// Saves the choice, so S04 never shows again. Called on either button,
  /// not when S04 shows: killing the app on S04 shows it again.
  Future<void> chosen() async {
    state = false;
    await ref.read(sharedPreferencesProvider).setBool(key, true);
  }
}

/// Signing in with Google from S24. Loading while the picker or the backend
/// is busy; an error holds the [ZemaFailure] to show. A cancel is no error.
final signInProvider =
    AsyncNotifierProvider.autoDispose<SignInController, void>(
      SignInController.new,
    );

class SignInController extends AsyncNotifier<void> {
  @override
  void build() {}

  /// Picks a Google account and signs in to the backend with its ID token.
  /// The signed-in user; null when cancelled, failed or already busy.
  Future<AuthUser?> signIn() async {
    final picker = ref.read(googleAccountPickerProvider);
    final auth = ref.read(authRepositoryProvider);
    if (state.isLoading || picker == null || auth == null) return null;
    state = const AsyncLoading();
    try {
      final tokens = await picker.pick();
      final user = tokens == null
          ? null
          : await auth.signInWithGoogle(
              idToken: tokens.idToken,
              accessToken: tokens.accessToken,
            );
      if (ref.mounted) state = const AsyncData(null);
      return user;
    } on Object catch (e, stack) {
      _log.warning('Sign-in failed', e);
      final failure = e is ZemaFailure
          ? e
          : AuthFailure('Sign-in failed: $e', cause: e);
      if (ref.mounted) state = AsyncError(failure, stack);
      return null;
    }
  }
}
