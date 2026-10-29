import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:zema_core/zema_core.dart';

/// The [ZemaFailure] for error [e] from calling [function].
///
/// With [userSession] (calls made as a signed-in user), a refused token means
/// the session is no longer valid ([AuthFailure]) rather than a bad app key,
/// and a failed check constraint is input the user can fix
/// ([ValidationFailure]).
ZemaFailure backendFailure(
  String function,
  Object e, {
  bool userSession = false,
}) => switch (e) {
  ZemaFailure() => e,
  PostgrestException(code: 'PT429') => RateLimitFailure(
    '$function: ${e.message}',
    cause: e,
  ),
  PostgrestException(code: 'PGRST301' || 'PGRST302' || '401')
      when userSession =>
    AuthFailure('$function: the session was refused', cause: e),
  PostgrestException(code: '23514') when userSession => ValidationFailure(
    '$function: ${e.message}',
    cause: e,
  ),
  // PostgREST's JWT errors, or the gateway's 401/403 for an unknown key.
  PostgrestException(code: 'PGRST301' || 'PGRST302' || '401' || '403') =>
    BackendFailure("$function: the backend refused the app's key", cause: e),
  // The gateway is up but the API behind it isn't.
  PostgrestException(code: '502' || '503' || '504') => NetworkFailure(
    '$function: backend unavailable (${e.code})',
    cause: e,
  ),
  PostgrestException() => BackendFailure(
    '$function: ${e.code} ${e.message}',
    cause: e,
  ),
  FormatException() => BackendFailure(
    '$function: unreadable answer: $e',
    cause: e,
  ),
  // No answer from the server: offline, refused, TLS or timed out
  // (http.ClientException, TimeoutException, ...).
  _ => NetworkFailure('$function: $e', cause: e),
};

/// Gives up on any request that takes longer than [timeout].
class TimeoutClient extends http.BaseClient {
  TimeoutClient(this._inner, this.timeout);

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(timeout);

  @override
  void close() => _inner.close();
}
