/// Where the catalog backend is, set at build time:
///
/// ```text
/// flutter run --dart-define-from-file=config/backend.local.json
/// ```
///
/// (`tool/backend_env.sh` writes that file for the local backend). No key is
/// built in, so without one the catalog is not configured.
class BackendConfig {
  const BackendConfig({
    required this.url,
    required this.key,
    this.fingerprintUploads = false,
  });

  /// From `--dart-define`: `ZEMA_BACKEND_URL` (default: the local backend as
  /// the Android emulator sees it) and `ZEMA_BACKEND_KEY` (the public anon
  /// key; never a service key), and `ZEMA_FINGERPRINT_UPLOADS`.
  const BackendConfig.fromEnvironment()
    : url = const String.fromEnvironment(
        'ZEMA_BACKEND_URL',
        defaultValue: localUrl,
      ),
      key = const String.fromEnvironment('ZEMA_BACKEND_KEY'),
      fingerprintUploads = const bool.fromEnvironment(
        'ZEMA_FINGERPRINT_UPLOADS',
      );

  /// The local backend (`npx supabase start`) from the Android emulator.
  static const localUrl = 'http://10.0.2.2:54321';

  final String url;
  final String key;

  /// Whether phones send fingerprints for the catalog to store: those of
  /// contributions and shared library songs. Off by default while server
  /// storage is limited; songs are still identified by sound on the phone,
  /// and lookups on the server store nothing.
  final bool fingerprintUploads;

  bool get isConfigured => url.isNotEmpty && key.isNotEmpty;
}
