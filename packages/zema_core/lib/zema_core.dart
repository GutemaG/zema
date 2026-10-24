/// Shared Zema domain logic used by the mobile app, the admin site and tooling.
///
/// Must stay pure Dart: no Flutter imports and no backend (Firebase/Supabase) code.
library;

export 'src/failures.dart';
export 'src/library/reconcile_tracks.dart';
export 'src/library/scanned_audio.dart';
export 'src/library/track.dart';
export 'src/library/track_fingerprint.dart';

/// Name of this package, for diagnostics.
const String packageName = 'zema_core';
