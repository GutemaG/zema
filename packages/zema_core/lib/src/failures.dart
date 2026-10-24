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
