import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:zema_data/zema_data.dart';

final _log = Logger('account.session');

/// The signed-in session in the phone's secure storage: the Android
/// Keystore, the iOS Keychain (this device only, readable after the first
/// unlock so background backups can use it).
///
/// A session that can't be read (e.g. its key was reset when the app was
/// restored onto another phone) is cleared, which means signed out.
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const key = 'supabaseSession';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: key);
    } on Object catch (e) {
      _log.warning('Saved session unreadable; signing out: $e');
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(String session) =>
      _storage.write(key: key, value: session);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: key);
    } on Object catch (e) {
      _log.warning('Could not clear the saved session: $e');
    }
  }
}
