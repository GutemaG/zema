import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

void main() {
  group('validateDisplayName', () {
    test('trims, and accepts 1 to 40 characters', () {
      expect(validateDisplayName('  Abebe Bikila '), 'Abebe Bikila');
      expect(validateDisplayName('A'), 'A');
      expect(validateDisplayName('x' * 40), 'x' * 40);
    });

    test('refuses empty, spaces only and over 40 characters', () {
      for (final name in ['', '   ', 'x' * 41]) {
        expect(
          () => validateDisplayName(name),
          throwsA(isA<ValidationFailure>()),
          reason: '"$name"',
        );
      }
    });

    test('counts characters, not UTF-16 units: 40 Ge\'ez letters pass', () {
      expect(validateDisplayName('ሀ' * 40), 'ሀ' * 40);
      // An emoji is two UTF-16 units but one character.
      expect(validateDisplayName('😀' * 40), '😀' * 40);
      expect(
        () => validateDisplayName('😀' * 41),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('the limit is the server\'s', () {
      expect(displayNameMaxLength, 40);
    });
  });

  group('Profile', () {
    test('moderators and admins can moderate; contributors cannot', () {
      Profile withRoles(Set<AccountRole> roles) =>
          Profile(userId: 'u', displayName: 'N', roles: roles);
      expect(withRoles({AccountRole.contributor}).isModerator, isFalse);
      expect(withRoles({AccountRole.moderator}).isModerator, isTrue);
      expect(withRoles({AccountRole.admin}).isModerator, isTrue);
      expect(withRoles({}).isModerator, isFalse);
    });

    test('is a contributor by default', () {
      expect(const Profile(userId: 'u', displayName: 'N').roles, {
        AccountRole.contributor,
      });
    });

    test('equality ignores the order of roles', () {
      const a = Profile(
        userId: 'u',
        displayName: 'N',
        roles: {AccountRole.contributor, AccountRole.moderator},
      );
      const b = Profile(
        userId: 'u',
        displayName: 'N',
        roles: {AccountRole.moderator, AccountRole.contributor},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(displayName: 'M'), isNot(a));
      expect(a.copyWith(displayName: 'M').roles, a.roles);
    });
  });

  test('AuthUser has value equality', () {
    expect(
      const AuthUser(id: 'u', email: 'e', name: 'n'),
      const AuthUser(id: 'u', email: 'e', name: 'n'),
    );
    expect(
      const AuthUser(id: 'u', name: 'n'),
      isNot(const AuthUser(id: 'u', name: 'm')),
    );
  });
}
