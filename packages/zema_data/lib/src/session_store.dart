/// Where the signed-in session is kept between runs: secure storage in the
/// app, memory in tests and tools.
///
/// The session is a JSON string holding the access and refresh tokens, so
/// implementations must keep it private to the app.
abstract interface class SessionStore {
  /// The saved session, or null.
  Future<String?> read();

  Future<void> write(String session);

  Future<void> clear();
}

/// A [SessionStore] in memory, lost when the process ends.
class MemorySessionStore implements SessionStore {
  MemorySessionStore([this.session]);

  /// The saved session, or null.
  String? session;

  @override
  Future<String?> read() async => session;

  @override
  Future<void> write(String session) async => this.session = session;

  @override
  Future<void> clear() async => session = null;
}
