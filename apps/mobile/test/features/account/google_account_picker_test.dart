import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zema/features/account/data/google_account_picker.dart';
import 'package:zema/features/account/data/google_config.dart';
import 'package:zema_core/zema_core.dart';

/// The native side of `google_sign_in`, in memory.
class _FakePlatform extends GoogleSignInPlatform
    with MockPlatformInterfaceMixin {
  final inits = <InitParameters>[];
  var authenticates = 0;
  var signOuts = 0;
  var disconnects = 0;

  /// Thrown by disconnect when set.
  Object? disconnectFailure;

  /// Thrown by the next init when set (then cleared).
  Object? initFailure;

  /// Thrown by authenticate when set.
  Object? authFailure;

  String? idToken = 'google-id-token';

  @override
  Future<void> init(InitParameters params) async {
    inits.add(params);
    final failure = initFailure;
    if (failure != null) {
      initFailure = null;
      throw failure;
    }
  }

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    authenticates++;
    final failure = authFailure;
    if (failure != null) throw failure;
    return AuthenticationResults(
      user: const GoogleSignInUserData(email: 'abebe@example.com', id: '1'),
      authenticationTokens: AuthenticationTokenData(idToken: idToken),
    );
  }

  @override
  Future<void> signOut(SignOutParams params) async => signOuts++;

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) => null;

  @override
  bool supportsAuthenticate() => true;

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<void> disconnect(DisconnectParams params) async {
    final failure = disconnectFailure;
    if (failure != null) throw failure;
    disconnects++;
  }
}

void main() {
  late _FakePlatform platform;
  const config = GoogleConfig(webClientId: 'web-id', iosClientId: 'ios-id');

  setUp(() {
    platform = _FakePlatform();
    GoogleSignInPlatform.instance = platform;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  GoogleSignInException googleError(GoogleSignInExceptionCode code) =>
      GoogleSignInException(code: code, description: 'test');

  group('GoogleConfig', () {
    test('needs the web ID, and on iOS the iOS ID too', () {
      expect(config.isConfiguredFor(TargetPlatform.android), isTrue);
      expect(config.isConfiguredFor(TargetPlatform.iOS), isTrue);
      const webOnly = GoogleConfig(webClientId: 'web-id');
      expect(webOnly.isConfiguredFor(TargetPlatform.android), isTrue);
      expect(webOnly.isConfiguredFor(TargetPlatform.iOS), isFalse);
      const none = GoogleConfig(iosClientId: 'ios-id');
      expect(none.isConfiguredFor(TargetPlatform.iOS), isFalse);
      expect(none.isConfiguredFor(TargetPlatform.android), isFalse);
    });

    test('this test run has no IDs, like a build without config', () {
      expect(
        const GoogleConfig.fromEnvironment().isConfiguredFor(
          TargetPlatform.android,
        ),
        isFalse,
      );
    });
  });

  group('PluginGoogleAccountPicker', () {
    test('asks for a token for the web client, and returns it', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final picker = PluginGoogleAccountPicker(config);

      final tokens = await picker.pick();

      expect(tokens?.idToken, 'google-id-token');
      expect(platform.inits.single.serverClientId, 'web-id');
      expect(
        platform.inits.single.clientId,
        isNull,
        reason: 'Android takes its client from the package and SHA-1',
      );
    });

    test('passes the iOS client ID on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await PluginGoogleAccountPicker(config).pick();
      expect(platform.inits.single.clientId, 'ios-id');
      expect(platform.inits.single.serverClientId, 'web-id');
    });

    test('initializes once for many picks', () async {
      final picker = PluginGoogleAccountPicker(config);
      await picker.pick();
      await picker.pick();
      await picker.signOut();
      expect(platform.inits, hasLength(1));
      expect(platform.authenticates, 2);
      expect(platform.signOuts, 1);
    });

    test('a cancel is null', () async {
      platform.authFailure = googleError(GoogleSignInExceptionCode.canceled);
      expect(await PluginGoogleAccountPicker(config).pick(), isNull);
    });

    test('other Google errors are AuthFailures', () async {
      for (final code in [
        GoogleSignInExceptionCode.interrupted,
        GoogleSignInExceptionCode.clientConfigurationError,
        GoogleSignInExceptionCode.uiUnavailable,
        GoogleSignInExceptionCode.unknownError,
      ]) {
        platform.authFailure = googleError(code);
        await expectLater(
          PluginGoogleAccountPicker(config).pick(),
          throwsA(isA<AuthFailure>()),
          reason: code.name,
        );
      }
    });

    test('no ID token is an AuthFailure', () async {
      platform.idToken = null;
      await expectLater(
        PluginGoogleAccountPicker(config).pick(),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('a failed initialize is tried again on the next pick', () async {
      platform.initFailure = googleError(
        GoogleSignInExceptionCode.providerConfigurationError,
      );
      final picker = PluginGoogleAccountPicker(config);
      await expectLater(picker.pick(), throwsA(isA<AuthFailure>()));
      expect(platform.authenticates, 0);

      expect((await picker.pick())?.idToken, 'google-id-token');
      expect(platform.inits, hasLength(2));
    });

    test('sign-out errors are swallowed', () async {
      platform.initFailure = StateError('no plugin');
      await PluginGoogleAccountPicker(config).signOut();
      expect(platform.signOuts, 0);
    });

    test('disconnect revokes access, and its errors are swallowed', () async {
      final picker = PluginGoogleAccountPicker(config);
      await picker.disconnect();
      expect(platform.disconnects, 1);

      platform.disconnectFailure = StateError('offline');
      await picker.disconnect();
      expect(platform.disconnects, 1);
    });
  });
}
