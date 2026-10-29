import 'package:flutter/foundation.dart';

/// The Google OAuth client IDs, set at build time:
///
/// ```text
/// flutter run --dart-define-from-file=config/google.local.json
/// ```
///
/// (gitignored; see `docs/google-sign-in-setup.md`). Without them the build
/// offers no sign-in.
class GoogleConfig {
  const GoogleConfig({this.webClientId = '', this.iosClientId = ''});

  /// From `--dart-define`: `ZEMA_GOOGLE_WEB_CLIENT_ID` (the ID token's
  /// audience, which the backend checks) and `ZEMA_GOOGLE_IOS_CLIENT_ID`.
  const GoogleConfig.fromEnvironment()
    : webClientId = const String.fromEnvironment('ZEMA_GOOGLE_WEB_CLIENT_ID'),
      iosClientId = const String.fromEnvironment('ZEMA_GOOGLE_IOS_CLIENT_ID');

  final String webClientId;
  final String iosClientId;

  /// Whether sign-in can run on [platform]: the web ID everywhere, and iOS
  /// also needs its own.
  bool isConfiguredFor(TargetPlatform platform) =>
      webClientId.isNotEmpty &&
      (platform != TargetPlatform.iOS || iosClientId.isNotEmpty);
}
