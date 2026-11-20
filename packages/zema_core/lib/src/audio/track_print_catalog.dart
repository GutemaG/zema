import 'audio_catalog.dart';
import 'track_print.dart';

/// A catalog song a [TrackPrint] matched, with how far apart the prints
/// were (the share of differing bits, at most [trackPrintMatch]).
typedef TrackPrintMatch = ({String songId, double bits});

/// The catalog's track prints (intent 013): finds the song of a whole
/// library file, and takes prints of files linked to a song. Implementations
/// throw [ZemaFailure]s only.
abstract interface class TrackPrintCatalog {
  /// The approved songs [print] matches, best first. [installId] counts
  /// against a daily limit ([RateLimitFailure] past it).
  Future<List<TrackPrintMatch>> matchTrack(
    TrackPrint print, {
    required String installId,
    int limit = 3,
  });

  /// Shares [print] of a library file linked to [songId] by title or by
  /// hand. [installId] counts against a daily limit.
  Future<FingerprintShare> shareTrackPrint(
    String songId,
    TrackPrint print, {
    required String installId,
  });
}
