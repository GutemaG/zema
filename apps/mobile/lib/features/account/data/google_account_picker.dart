import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import 'google_config.dart';

final _log = Logger('account.google');

/// What the Google account picker gives back.
class GoogleTokens {
  const GoogleTokens({required this.idToken, this.accessToken});

  final String idToken;
  final String? accessToken;
}

/// The Google account picker. Tests use a fake.
abstract interface class GoogleAccountPicker {
  /// Shows the picker. Null when the user cancels; [AuthFailure] when
  /// Google refuses or the picker can't show.
  Future<GoogleTokens?> pick();

  /// Forgets the picked account, so the next [pick] asks again. Never
  /// throws: the user is signed out of Zema already.
  Future<void> signOut();

  /// Like [signOut], and also revokes Zema's access to the Google account,
  /// for a deleted account. Never throws.
  Future<void> disconnect();
}

/// [GoogleAccountPicker] over `google_sign_in`: Credential Manager on
/// Android, the Google Sign-In SDK on iOS.
class PluginGoogleAccountPicker implements GoogleAccountPicker {
  PluginGoogleAccountPicker(this._config, {GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleConfig _config;
  final GoogleSignIn _signIn;
  Future<void>? _initialized;

  /// Initializes once; a failed attempt is retried on the next call.
  Future<void> _initialize() => _initialized ??= _signIn
      .initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? _config.iosClientId
            : null,
        // Makes the ID token's audience the web client, for the backend.
        serverClientId: _config.webClientId,
      )
      .catchError((Object e) {
        _initialized = null;
        throw e;
      });

  @override
  Future<GoogleTokens?> pick() async {
    try {
      await _initialize();
      final account = await _signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google gave no ID token');
      }
      return GoogleTokens(idToken: idToken);
    } on GoogleSignInException catch (e) {
      // Android also reports some setup errors (a wrong SHA-1 or package)
      // as canceled; the log tells them apart from a real cancel.
      _log.info('Google sign-in: ${e.code.name} ${e.description ?? ''}');
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthFailure('Google sign-in failed: ${e.code.name}', cause: e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _initialize();
      await _signIn.signOut();
    } on Object catch (e) {
      _log.warning('Google sign-out failed', e);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _initialize();
      await _signIn.disconnect();
    } on Object catch (e) {
      _log.warning('Google disconnect failed', e);
    }
  }
}
