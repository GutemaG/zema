import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/preferences_provider.dart';
import '../../settings/application/settings_controller.dart';
import '../data/backup_builder.dart';
import '../data/backup_status.dart';
import 'account_providers.dart';
import 'backup_service.dart';

final backupBuilderProvider = Provider<BackupBuilder>(
  (ref) => backupBuilderOf(
    ref.watch(databaseProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

final backupStatusStoreProvider = Provider<BackupStatusStore>(
  (ref) => BackupStatusStore(ref.watch(sharedPreferencesProvider)),
);

/// Backing up, or null when the build has no backend.
final backupServiceProvider = Provider<BackupService?>((ref) {
  final repository = ref.watch(backupRepositoryProvider);
  if (repository == null) return null;
  return BackupService(
    repository: repository,
    builder: ref.watch(backupBuilderProvider),
    store: ref.watch(backupStatusStoreProvider),
    settings: () => ref.read(settingsProvider),
  );
});

/// S25b's state: the signed-in user's [BackupStatus] (null for a guest)
/// and whether a backup is running.
@immutable
class BackupState {
  const BackupState({this.status, this.running = false});

  final BackupStatus? status;
  final bool running;
}

final backupProvider = NotifierProvider<BackupController, BackupState>(
  BackupController.new,
);

class BackupController extends Notifier<BackupState> {
  @override
  BackupState build() {
    final user = ref.watch(authUserProvider).value;
    if (user == null) return const BackupState();
    return BackupState(
      status: ref.read(backupStatusStoreProvider).readCached(user.id),
    );
  }

  String? get _userId => ref.read(authUserProvider).value?.id;

  /// Backs up now, on any network. A cloud backup from another phone is
  /// replaced only with [replace]. Null when signed out or already running.
  Future<BackupResult?> backUpNow({bool replace = false}) async {
    final userId = _userId;
    final service = ref.read(backupServiceProvider);
    if (userId == null || service == null || state.running) return null;
    state = BackupState(status: state.status, running: true);
    try {
      return await service.backUp(userId, replace: replace);
    } finally {
      if (ref.mounted) await _reload(userId);
    }
  }

  /// Turns daily auto backup on or off.
  Future<void> setAutoBackup(bool on) async {
    final userId = _userId;
    if (userId == null) return;
    final store = ref.read(backupStatusStoreProvider);
    await store.write(
      userId,
      (await store.read(userId)).copyWith(autoBackup: on),
    );
    if (ref.mounted) await _reload(userId);
  }

  /// Reads the status again, e.g. after a background backup.
  Future<void> refresh() async {
    final userId = _userId;
    if (userId != null) await _reload(userId);
  }

  Future<void> _reload(String userId) async {
    final status = await ref.read(backupStatusStoreProvider).read(userId);
    if (ref.mounted && _userId == userId) state = BackupState(status: status);
  }
}
