import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/library/application/library_providers.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';
import 'package:zema/features/library/data/library_scanner.dart';
import 'package:zema_core/zema_core.dart';

/// A [LibraryScanner] that returns [files], or throws [error] when set.
class FakeLibraryScanner implements LibraryScanner {
  FakeLibraryScanner([List<ScannedAudio> files = const []])
    : files = [...files];

  List<ScannedAudio> files;
  ZemaFailure? error;
  int scans = 0;

  @override
  bool get isSupported => true;

  @override
  Future<List<ScannedAudio>> scan() async {
    scans++;
    final failure = error;
    if (failure != null) throw failure;
    return [...files];
  }

  @override
  Future<Uint8List?> loadArtwork(int mediaStoreId, {int size = 200}) async =>
      null;
}

/// An [AudioPermissionService] whose answers the test sets.
class FakeAudioPermissionService implements AudioPermissionService {
  FakeAudioPermissionService({
    this.current = AudioAccess.granted,
    AudioAccess? onRequest,
  }) : onRequest = onRequest ?? AudioAccess.granted;

  /// What [status] reports.
  AudioAccess current;

  /// What the system dialog answers; also becomes [current].
  AudioAccess onRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<AudioAccess> status() async => current;

  @override
  Future<AudioAccess> request() async {
    requests++;
    return current = onRequest;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

/// An in-memory database that closes its streams synchronously, so widget
/// tests don't end with pending timers. Closed when the test ends.
ZemaDatabase memoryDatabase() {
  final database = ZemaDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(database.close);
  return database;
}

/// Provider overrides that replace the device library with fakes.
List<Override> libraryOverrides({
  LibraryScanner? scanner,
  AudioPermissionService? permissions,
  ZemaDatabase? database,
}) => [
  libraryScannerProvider.overrideWithValue(scanner ?? FakeLibraryScanner()),
  audioPermissionServiceProvider.overrideWithValue(
    permissions ?? FakeAudioPermissionService(),
  ),
  databaseProvider.overrideWithValue(database ?? memoryDatabase()),
];

/// A scan entry with sensible defaults, for tests.
ScannedAudio scannedAudio(
  int mediaStoreId,
  String path, {
  String? title,
  String? artist,
  String? album,
  int durationMs = 60000,
  int sizeBytes = 1000,
}) {
  final name = path.substring(path.lastIndexOf('/') + 1);
  return ScannedAudio(
    mediaStoreId: mediaStoreId,
    uri: 'content://media/external/audio/media/$mediaStoreId',
    path: path,
    displayName: name,
    title: title,
    artist: artist,
    album: album,
    duration: Duration(milliseconds: durationMs),
    sizeBytes: sizeBytes,
    dateAdded: DateTime.utc(2026, 10, 1),
  );
}
