/// Typed failures thrown at repository boundaries.
///
/// Repositories never let raw platform, database or HTTP exceptions escape;
/// they wrap them in one of these. More subtypes (network, not found,
/// validation) are added by the intents that need them.
sealed class ZemaFailure implements Exception {
  const ZemaFailure(this.message, {this.cause});

  /// Developer-facing description. Never shown to users as is.
  final String message;

  /// The underlying error, kept for logging.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// A permission the operation needs was not granted.
final class PermissionFailure extends ZemaFailure {
  const PermissionFailure(super.message, {super.cause});
}

/// Reading the device's audio library failed.
final class ScanFailure extends ZemaFailure {
  const ScanFailure(super.message, {super.cause});
}

/// The local database could not be opened, read or written.
final class DatabaseFailure extends ZemaFailure {
  const DatabaseFailure(super.message, {super.cause});
}

/// A name that must be unique is already taken (e.g. a playlist name).
final class DuplicateNameFailure extends ZemaFailure {
  const DuplicateNameFailure(super.message, {super.cause});
}

/// Lyrics data (JSON, LRC or timing) is malformed or inconsistent.
final class LyricsFormatFailure extends ZemaFailure {
  const LyricsFormatFailure(super.message, {super.cause});
}

/// The backend could not be reached: no connection, a timeout, or the server
/// is down.
final class NetworkFailure extends ZemaFailure {
  const NetworkFailure(super.message, {super.cause});
}

/// The backend refused the request because too many were sent (e.g. the
/// daily report limit).
final class RateLimitFailure extends ZemaFailure {
  const RateLimitFailure(super.message, {super.cause});
}

/// The backend answered with an error: a refused key, rejected input or a
/// server fault.
final class BackendFailure extends ZemaFailure {
  const BackendFailure(super.message, {super.cause});
}

/// Not signed in, or the sign-in or session was refused (e.g. an expired
/// or revoked session, or a token the server does not accept).
final class AuthFailure extends ZemaFailure {
  const AuthFailure(super.message, {super.cause});
}

/// Input the user can correct, such as a name that is too long.
final class ValidationFailure extends ZemaFailure {
  const ValidationFailure(super.message, {super.cause});
}

/// A backup document that can't be read: malformed, or written by a newer
/// app ([newerFormat]; the user should update the app).
final class BackupFormatFailure extends ZemaFailure {
  const BackupFormatFailure(
    super.message, {
    this.newerFormat = false,
    super.cause,
  });

  /// The backup's format is newer than this app knows.
  final bool newerFormat;
}

/// Fingerprint bytes that can't be read: damaged, or made by another
/// fingerprint version.
final class FingerprintFormatFailure extends ZemaFailure {
  const FingerprintFormatFailure(super.message, {super.cause});
}

/// The backend refused a contribution or a review for a reason it names:
/// [code] is one of the shared codes (see `ContributionError`), such as
/// `timing_count`, `too_many_open` or `already_reviewed`.
final class ContributionFailure extends ZemaFailure {
  const ContributionFailure(super.message, {required this.code, super.cause});

  final String code;
}
