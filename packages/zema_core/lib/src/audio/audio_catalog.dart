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
  Future<List<CatalogAudioMatch>> identify(
    List<AudioFingerprint> queries, {
    int limit = 3,
  });
}
