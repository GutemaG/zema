import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../data/audio_permission_service.dart';
import '../data/library_repository.dart';
import '../data/library_scanner.dart';
import '../data/media_store_library_scanner.dart';

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// MediaStore on Android; unsupported elsewhere for now.
final libraryScannerProvider = Provider<LibraryScanner>(
  (ref) => _isAndroid
      ? const MediaStoreLibraryScanner()
      : const UnsupportedLibraryScanner(),
);

final audioPermissionServiceProvider = Provider<AudioPermissionService>(
  (ref) => _isAndroid
      ? AndroidAudioPermissionService()
      : const UnsupportedAudioPermissionService(),
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(
    ref.watch(libraryScannerProvider),
    ref.watch(databaseProvider).libraryDao,
  ),
);

/// Audio shorter than this is left out of the library (voice notes, sounds).
const defaultMinTrackDuration = Duration(seconds: 30);

/// Becomes a setting in story 020.
final minTrackDurationProvider = Provider<Duration>(
  (ref) => defaultMinTrackDuration,
);

/// The tracks to show, kept up to date from the database.
final libraryTracksProvider = StreamProvider<List<Track>>(
  (ref) => ref
      .watch(libraryRepositoryProvider)
      .watchTracks(minDuration: ref.watch(minTrackDurationProvider)),
);
