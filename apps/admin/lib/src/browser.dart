import 'package:web/web.dart' as web;
import 'package:zema_data/zema_data.dart';

import 'session.dart';

/// The real page: its address and `localStorage`. Web only.
class PageBrowser implements Browser {
  const PageBrowser();

  @override
  Uri get location => Uri.parse(web.window.location.href);

  @override
  void go(Uri url) => web.window.location.assign(url.toString());

  @override
  void replaceLocation(Uri url) =>
      web.window.history.replaceState(null, '', url.toString());
}

/// The signed-in session, in `localStorage` (only this site can read it).
class LocalSessionStore implements SessionStore {
  const LocalSessionStore();

  static const _key = 'zema.admin.session';

  @override
  Future<String?> read() async => web.window.localStorage.getItem(_key);

  @override
  Future<void> write(String session) async =>
      web.window.localStorage.setItem(_key, session);

  @override
  Future<void> clear() async => web.window.localStorage.removeItem(_key);
}

/// Keeps the sign-in's code verifier while the browser is away at Google.
class LocalRedirectStorage extends GotrueAsyncStorage {
  const LocalRedirectStorage();

  @override
  Future<String?> getItem({required String key}) async =>
      web.window.localStorage.getItem(key);

  @override
  Future<void> setItem({required String key, required String value}) async =>
      web.window.localStorage.setItem(key, value);

  @override
  Future<void> removeItem({required String key}) async =>
      web.window.localStorage.removeItem(key);
}
