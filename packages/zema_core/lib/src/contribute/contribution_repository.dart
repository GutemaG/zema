import '../audio/audio_fingerprint.dart';
import '../audio/pending_fingerprint.dart';
import '../failures.dart';
import 'contribution.dart';

/// Contributions on the backend. Every call needs a signed-in user
/// ([AuthFailure] otherwise) and throws [NetworkFailure] when the server
/// can't be reached. A refusal the backend names (a broken rule, a limit, a
/// review already made) is a [ContributionFailure] with its code.
abstract interface class ContributionRepository {
  /// Sends [contribution] for review; returns its id.
  Future<String> submit(Contribution contribution);

  /// Sends the user's contribution [id], which a moderator sent back, again
  /// with [contribution] (same kind and song); returns its new revision.
  Future<int> resubmit(String id, Contribution contribution);

  /// The signed-in user's contributions, last sent first.
  Future<List<SubmittedContribution>> mine();

  /// Moderators only: other users' pending contributions, oldest first,
  /// only of [kind] when given.
  Future<List<QueuedContribution>> queue({ContributionKind? kind});

  /// Moderators only: decides on pending contribution [id]; [note] is
  /// required unless approving. Returns the catalog song's id (for an
  /// approved new song, the one it became).
  Future<String?> review(String id, ReviewDecision decision, {String? note});

  /// Attaches [fingerprint] (at `FingerprintDensity.catalog`) of the file
  /// recording in the user's contribution [id], pending or sent back,
  /// replacing one attached before. It is published when the contribution
  /// is approved.
  Future<void> attachFingerprint(String id, AudioFingerprint fingerprint);

  /// Moderators only: fingerprints shared from libraries that no second
  /// install has confirmed yet, oldest first.
  Future<List<PendingFingerprint>> pendingFingerprints();

  /// Moderators only: publishes ([approve]) or drops pending fingerprint
  /// [id].
  Future<void> reviewFingerprint(String id, {required bool approve});
}
