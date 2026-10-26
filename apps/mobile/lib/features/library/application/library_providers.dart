import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../settings/application/settings_controller.dart';
import '../data/audio_permission_service.dart';
import '../data/audio_share_service.dart';
import '../data/collections_repository.dart';
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

final audioShareServiceProvider = Provider<AudioShareService>(
  (ref) => _isAndroid
      ? const AndroidAudioShareService()
      : const UnsupportedAudioShareService(),
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(
    ref.watch(libraryScannerProvider),
    ref.watch(databaseProvider).libraryDao,
  ),
);

final collectionsRepositoryProvider = Provider<CollectionsRepository>(
  (ref) => CollectionsRepository(ref.watch(databaseProvider).collectionsDao),
);

/// Audio shorter than this is left out of the library (voice notes, sounds).
/// Set in Settings; changing it re-runs the query, with no rescan.
final minTrackDurationProvider = Provider<Duration>(
  (ref) => ref.watch(settingsProvider.select((s) => s.minTrackDuration)),
);

/// The tracks to show, kept up to date from the database.
final libraryTracksProvider = StreamProvider<List<Track>>(
  (ref) => ref
      .watch(libraryRepositoryProvider)
      .watchTracks(minDuration: ref.watch(minTrackDurationProvider)),
);

/// Hidden folders, by path (Settings → Hidden folders).
final hiddenFoldersProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchHiddenFolders(),
);

/// Hidden songs, by title (Settings → Hidden songs).
final hiddenTracksProvider = StreamProvider<List<Track>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchHiddenTracks(),
);
