import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema_admin/src/app.dart';
import 'package:zema_admin/src/config.dart';
import 'package:zema_admin/src/session.dart';
import 'package:zema_admin/src/strings.dart';
import 'package:zema_core/zema_core.dart';

const _userId = '00000000-0000-0000-0000-00000000000a';

class _Browser implements Browser {
  _Browser(String url) : location = Uri.parse(url);

  @override
  Uri location;
  Uri? went;

  @override
  void go(Uri url) => went = url;

  @override
  void replaceLocation(Uri url) => location = url;
}

class _Auth implements AdminAuth {
  static const user = AuthUser(id: _userId, email: 'abebe@example.com');

  AuthUser? saved;
  final codes = <String>[];
  var signedOut = false;

  @override
  Future<AuthUser?> restore() async => saved;

  @override
  Future<Uri> googleRedirectUrl(Uri returnTo) async => Uri(
    scheme: 'http',
    host: 'backend.test',
    path: '/auth/v1/authorize',
    queryParameters: {'provider': 'google', 'redirect_to': '$returnTo'},
  );

  @override
  Future<AuthUser> completeRedirectSignIn(String code) async {
    if (code == 'bad') throw const AuthFailure('flow_state_not_found');
    codes.add(code);
    return user;
  }

  @override
  Future<void> signOut() async => signedOut = true;
}

class _Profiles implements ProfileRepository {
  _Profiles(this.roles);

  final Set<AccountRole> roles;

  @override
  Future<Profile> profile() async =>
      Profile(userId: _userId, displayName: 'Abebe', roles: roles);

  @override
  Future<Profile> rename(String name) => throw UnimplementedError();
}

void main() {
  late _Browser browser;
  late _Auth auth;

  Future<void> pump(
    WidgetTester tester, {
    String url = 'https://admin.test/',
    Set<AccountRole> roles = const {AccountRole.moderator},
    AdminConfig config = const AdminConfig(
      url: 'http://backend.test',
      key: 'k',
    ),
  }) async {
    browser = _Browser(url);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminConfigProvider.overrideWithValue(config),
          browserProvider.overrideWithValue(browser),
          adminAuthProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(_Profiles(roles)),
          pageBodiesProvider.overrideWithValue(const {}),
        ],
        child: const AdminApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => auth = _Auth());

  testWidgets('without a backend it says so', (tester) async {
    await pump(
      tester,
      config: const AdminConfig(url: 'x', key: ''),
    );
    expect(find.text(Strings.notConfigured), findsOneWidget);
  });

  testWidgets('signed out: Sign in sends the browser to Google', (
    tester,
  ) async {
    await pump(tester, url: 'https://admin.test/?x=1');
    await tester.tap(find.text(Strings.signIn));
    await tester.pumpAndSettle();
    expect(browser.went?.queryParameters['provider'], 'google');
    expect(browser.went?.queryParameters['redirect_to'], 'https://admin.test/');
  });

  testWidgets('back from Google: a moderator gets the pages', (tester) async {
    await pump(tester, url: 'https://admin.test/?code=c1');
    expect(auth.codes, ['c1']);
    expect(browser.location.toString(), 'https://admin.test/');
    for (final page in AdminPage.values) {
      expect(find.text(page.label), findsWidgets);
    }
    expect(find.text('Abebe'), findsOneWidget);

    await tester.tap(find.text(Strings.reports));
    await tester.pumpAndSettle();
    expect(find.text(Strings.comingSoon), findsOneWidget);
  });

  testWidgets('anyone else is told and can sign out', (tester) async {
    await pump(tester, url: 'https://admin.test/?code=c1', roles: const {});
    expect(find.text(Strings.notModerator), findsOneWidget);
    expect(find.text(Strings.contributions), findsNothing);

    await tester.tap(find.text(Strings.signOut));
    await tester.pumpAndSettle();
    expect(find.text(Strings.signIn), findsOneWidget);
    expect(auth.signedOut, isTrue);
  });

  testWidgets('a refused code shows why', (tester) async {
    await pump(tester, url: 'https://admin.test/?code=bad');
    expect(find.textContaining('flow_state_not_found'), findsOneWidget);
  });

  testWidgets('a failed sign-in shows why', (tester) async {
    await pump(tester, url: 'https://admin.test/?error=access_denied');
    expect(find.textContaining('access_denied'), findsOneWidget);
    expect(browser.location.toString(), 'https://admin.test/');
  });

  testWidgets('a saved session signs in at once', (tester) async {
    auth.saved = _Auth.user;
    await pump(tester);
    expect(find.text('Abebe'), findsOneWidget);
  });

  testWidgets('narrow screens get a bottom bar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    auth.saved = _Auth.user;
    await pump(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
