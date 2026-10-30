import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema_core/zema_core.dart';

/// The last profile the server gave, kept in shared preferences so Profile
/// (S25) and the Home avatar show it at once and offline.
class ProfileCache {
  ProfileCache(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String userId) => 'profile.$userId';

  /// The saved profile of [userId], or null when none (or unreadable).
  Profile? read(String userId) {
    final saved = _prefs.getString(_key(userId));
    if (saved == null) return null;
    try {
      final json = jsonDecode(saved) as Map<String, Object?>;
      return Profile(
        userId: userId,
        displayName: json['displayName']! as String,
        avatarUrl: json['avatarUrl'] as String?,
        roles: {
          for (final role in json['roles']! as List<Object?>)
            ?AccountRole.values.asNameMap()[role],
        },
      );
    } on Object {
      return null;
    }
  }

  Future<void> write(Profile profile) => _prefs.setString(
    _key(profile.userId),
    jsonEncode({
      'displayName': profile.displayName,
      'avatarUrl': profile.avatarUrl,
      'roles': [for (final role in profile.roles) role.name],
    }),
  );

  /// Forgets [userId]'s profile, after a sign-out or a deleted account.
  Future<void> remove(String userId) => _prefs.remove(_key(userId));
}
