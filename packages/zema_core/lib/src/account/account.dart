import '../failures.dart';

/// A signed-in user, as the auth service knows them.
///
/// [name] and [avatarUrl] come from the Google account and may be missing;
/// the name shown in the app is the [Profile]'s.
class AuthUser {
  const AuthUser({required this.id, this.email, this.name, this.avatarUrl});

  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.name == name &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, email, name, avatarUrl);

  @override
  String toString() => 'AuthUser($id)';
}

/// What a user may do beyond listening. Every signed-in user is a
/// [contributor]; the others are given on the server only.
enum AccountRole { contributor, moderator, admin }

/// A signed-in user's profile: the name shown in the app, the avatar and
/// their roles.
class Profile {
  const Profile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.roles = const {AccountRole.contributor},
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final Set<AccountRole> roles;

  /// Whether the user can moderate (admins can too).
  bool get isModerator =>
      roles.contains(AccountRole.moderator) ||
      roles.contains(AccountRole.admin);

  Profile copyWith({String? displayName}) => Profile(
    userId: userId,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl,
    roles: roles,
  );

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.userId == userId &&
      other.displayName == displayName &&
      other.avatarUrl == avatarUrl &&
      other.roles.length == roles.length &&
      other.roles.containsAll(roles);

  @override
  int get hashCode => Object.hash(
    userId,
    displayName,
    avatarUrl,
    Object.hashAllUnordered(roles),
  );

  @override
  String toString() => 'Profile($userId, $displayName)';
}

/// The longest display name, in characters (the server checks the same).
const displayNameMaxLength = 40;

/// The display name [name] trimmed, or a [ValidationFailure] when it is
/// empty or longer than [displayNameMaxLength] characters.
String validateDisplayName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    throw const ValidationFailure('A display name cannot be empty');
  }
  if (trimmed.runes.length > displayNameMaxLength) {
    throw const ValidationFailure(
      'A display name can be at most $displayNameMaxLength characters',
    );
  }
  return trimmed;
}

/// Signing in and out, and the signed-in user.
///
/// Guest mode is the default: [currentUser] is null until the user signs in.
/// Failures are thrown as [ZemaFailure]s only: [AuthFailure] when the
/// sign-in or session is refused, [NetworkFailure] when the server can't be
/// reached.
abstract interface class AuthRepository {
  /// The signed-in user, or null for a guest.
  AuthUser? get currentUser;

  /// [currentUser] after every sign-in, sign-out and lost session.
  Stream<AuthUser?> get userChanges;

  /// Loads the session saved by an earlier run, once at start, and returns
  /// its user without waiting for the server. The session is checked in the
  /// background: one the server refuses is cleared, and [userChanges] tells
  /// of the sign-out; offline, it stays signed in and is checked again later.
  Future<AuthUser?> restore();

  /// Signs in with a Google ID token from the account picker.
  Future<AuthUser> signInWithGoogle({
    required String idToken,
    String? accessToken,
  });

  /// Signs out on this phone. Always ends signed out, even offline.
  Future<void> signOut();

  /// Deletes the signed-in user's account on the server (profile, roles,
  /// backup and sessions with it), then signs out on this phone. Throws
  /// when the server can't be reached or refuses, and stays signed in.
  Future<void> deleteAccount();
}

/// The signed-in user's profile. Both calls need a signed-in user
/// ([AuthFailure] otherwise).
abstract interface class ProfileRepository {
  /// The signed-in user's profile and roles.
  Future<Profile> profile();

  /// Changes the display name to [name] (see [validateDisplayName]) and
  /// returns the stored profile.
  Future<Profile> rename(String name);
}
