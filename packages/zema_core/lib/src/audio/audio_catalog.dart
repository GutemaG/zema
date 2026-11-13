import '../failures.dart';
import 'audio_fingerprint.dart';
import 'fingerprint_index.dart';

/// A catalog recording an excerpt was found in.
class CatalogAudioMatch {
  const CatalogAudioMatch({
    required this.songId,
    required this.match,
    required this.recordingDuration,
  });

  final String songId;

  /// [AudioMatch.recordingId] is the catalog recording's ID.
  final AudioMatch match;

  final Duration recordingDuration;

  @override
  String toString() => 'CatalogAudioMatch($songId, $match)';
}

/// The catalog's recordings, searchable by excerpt (intent 009, FR-3).
/// Implementations throw [ZemaFailure]s only.
abstract interface class AudioCatalog {
  /// The approved recordings [queries] match, best first. [queries] are one
  /// excerpt fingerprinted at several speeds (`Fingerprinter.queries`).
  /// [installId] identifies this install for the daily limit
  /// ([RateLimitFailure] past it).
  Future<List<CatalogAudioMatch>> identify(
    List<AudioFingerprint> queries, {
    required String installId,
    int limit = 3,
  });

  /// The fingerprints of this `fingerprintVersion` phones can keep (intent
  /// 009, FR-4), most identified first.
  Future<List<OfflineFingerprintEntry>> offlineFingerprints();

  /// The fingerprints of up to 20 of [recordingIds]; ones not in the
  /// catalog are left out.
  Future<List<CatalogFingerprint>> fingerprints(List<String> recordingIds);

  /// Of [recordingIds] (at most 200), the catalog recordings with no
  /// fingerprint of this `fingerprintVersion`.
  Future<Set<String>> missingFingerprints(List<String> recordingIds);

  /// Shares [fingerprint] (at `FingerprintDensity.catalog`) of a library
  /// file linked to catalog recording [recordingId]. [installId] counts
  /// against a daily limit ([RateLimitFailure] past it).
  Future<FingerprintShare> shareFingerprint(
    String recordingId,
    AudioFingerprint fingerprint, {
    required String installId,
  });
}

/// A catalog recording's fingerprint that phones can keep offline.
class OfflineFingerprintEntry {
  const OfflineFingerprintEntry({
    required this.recordingId,
    required this.songId,
    required this.revision,
    required this.hashCount,
    required this.identified,
  });

  final String recordingId;
  final String songId;

  /// Goes up each time the fingerprint is replaced.
  final int revision;
  final int hashCount;

  /// How often Listen found the recording.
  final int identified;
}

/// A catalog recording's fingerprint, at [revision].
class CatalogFingerprint {
  const CatalogFingerprint({
    required this.recordingId,
    required this.revision,
    required this.fingerprint,
  });

  final String recordingId;
  final int revision;
  final AudioFingerprint fingerprint;
}

/// What became of a shared fingerprint.
enum FingerprintShare {
  /// Waiting for another install's to line up with it, or a moderator.
  pending,

  /// Lined up with another install's: the recording has a fingerprint now.
  published,

  /// The recording has a fingerprint already, or isn't in the catalog.
  notNeeded,
}
