/// Where the backend is, set at build time from the app's config file:
///
/// ```text
/// flutter run -d chrome --dart-define-from-file=../mobile/config/backend.prod.local.json
/// ```
class AdminConfig {
  const AdminConfig({required this.url, required this.key});

  /// `ZEMA_BACKEND_URL` (default: the local backend) and `ZEMA_BACKEND_KEY`
  /// (the public anon key; never a service key).
  const AdminConfig.fromEnvironment()
    : url = const String.fromEnvironment(
        'ZEMA_BACKEND_URL',
        defaultValue: 'http://127.0.0.1:54321',
      ),
      key = const String.fromEnvironment('ZEMA_BACKEND_KEY');

  final String url;
  final String key;

  bool get isConfigured => url.isNotEmpty && key.isNotEmpty;
}
