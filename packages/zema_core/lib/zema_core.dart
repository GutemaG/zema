/// Shared Zema domain logic used by the mobile app, the admin site and tooling.
///
/// Must stay pure Dart: no Flutter imports and no backend (Firebase/Supabase) code.
library;

export 'src/failures.dart';
export 'src/library/playlist_order.dart';
export 'src/library/reconcile_tracks.dart';
export 'src/library/scanned_audio.dart';
export 'src/library/track.dart';
export 'src/library/track_fingerprint.dart';
export 'src/player/play_queue.dart';
export 'src/search/normalize.dart';
export 'src/search/search_tables.dart';
export 'src/search/transliteration.dart';

/// Name of this package, for diagnostics.
const String packageName = 'zema_core';
