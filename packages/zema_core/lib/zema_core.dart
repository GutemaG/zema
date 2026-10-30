/// Shared Zema domain logic used by the mobile app, the admin site and tooling.
///
/// Must stay pure Dart: no Flutter imports and no backend (Firebase/Supabase) code.
library;

export 'src/account/account.dart';
export 'src/backup/backup_document.dart';
export 'src/backup/backup_matcher.dart';
export 'src/backup/backup_repository.dart';
export 'src/backup/track_identity.dart';
export 'src/backup/unmatched_entry.dart';
export 'src/catalog/catalog.dart';
export 'src/failures.dart';
export 'src/library/playlist_order.dart';
export 'src/library/reconcile_tracks.dart';
export 'src/library/scanned_audio.dart';
export 'src/library/track.dart';
export 'src/library/track_fingerprint.dart';
export 'src/lyrics/lrc_import.dart';
export 'src/lyrics/lyric_search.dart';
export 'src/lyrics/lyrics_models.dart';
export 'src/lyrics/lyrics_repository.dart';
export 'src/lyrics/track_matching.dart';
export 'src/lyrics/play_order.dart';
export 'src/lyrics/sync_engine.dart';
export 'src/player/play_queue.dart';
export 'src/search/normalize.dart';
export 'src/search/search_tables.dart';
export 'src/search/transliteration.dart';

/// Name of this package, for diagnostics.
const String packageName = 'zema_core';
