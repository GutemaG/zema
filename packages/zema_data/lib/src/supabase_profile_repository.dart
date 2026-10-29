import 'package:supabase/supabase.dart' hide AuthUser;
import 'package:zema_core/zema_core.dart';

import 'supabase_auth_repository.dart';

/// The signed-in user's profile, from the backend's `profiles` and
/// `user_roles` tables (users read only their own rows, and may change only
/// their display name).
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._auth);

  final SupabaseAuthRepository _auth;

  @override
  Future<Profile> profile() => _auth.run('profile', (client, userId) async {
    final rows = await client
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId);
    return _profile(client, userId, rows);
  });

  @override
  Future<Profile> rename(String name) async {
    final displayName = validateDisplayName(name);
    return _auth.run('rename', (client, userId) async {
      final rows = await client
          .from('profiles')
          .update({'display_name': displayName})
          .eq('id', userId)
          .select('display_name, avatar_url');
      return _profile(client, userId, rows);
    });
  }
}

// Reads lists rather than maybeSingle(): postgrest's maybeSingle replaces a
// server error's code (e.g. 23514) with the HTTP status.
Future<Profile> _profile(
  SupabaseClient client,
  String userId,
  List<Map<String, dynamic>> rows,
) async {
  // Every user gets a profile on sign-up; none means the account is gone.
  if (rows.isEmpty) {
    throw const AuthFailure('No profile for the signed-in user');
  }
  final row = rows.first;
  final roles = await client
      .from('user_roles')
      .select('role')
      .eq('user_id', userId);
  try {
    return Profile(
      userId: userId,
      displayName: row['display_name']! as String,
      avatarUrl: row['avatar_url'] as String?,
      roles: {for (final role in roles) ?_roles[role['role']]},
    );
  } on TypeError catch (e) {
    throw BackendFailure('profile: unreadable answer: $e', cause: e);
  }
}

const _roles = {
  'contributor': AccountRole.contributor,
  'moderator': AccountRole.moderator,
  'admin': AccountRole.admin,
};
