import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/database/database_provider.dart';
import '../../../app/database/fingerprints_dao.dart';
import '../../../app/preferences_provider.dart';
import '../../account/application/auto_backup.dart';
import '../../lyrics/application/lyrics_links.dart';

final _log = Logger('identify.offline');

/// How much room catalog fingerprints may take on the phone (intent 009,
/// FR-4); [libraryOnly] keeps only the library's songs, whatever their size.
enum OfflineBudget {
  libraryOnly(null),
  mb25(25),
  mb50(50),
  mb100(100);

  const OfflineBudget(this.megabytes);

  final int? megabytes;

  int? get bytes => megabytes == null ? null : megabytes! * 1000 * 1000;
}

final offlineBudgetProvider =
    NotifierProvider<OfflineBudgetSetting, OfflineBudget>(
      OfflineBudgetSetting.new,
    );

class OfflineBudgetSetting extends Notifier<OfflineBudget> {
  static const key = 'identify.offlineBudget';

  @override
  OfflineBudget build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(key);
    return OfflineBudget.values.where((b) => b.name == saved).firstOrNull ??
        OfflineBudget.mb50;
  }

  Future<void> set(OfflineBudget budget) async {
    state = budget;
    await ref.read(sharedPreferencesProvider).setString(key, budget.name);
  }
}

/// About how many bytes a catalog fingerprint takes per hash on the phone
/// (`AudioFingerprint.toBytes`).
const offlineBytesPerHash = 6;

/// The recordings to keep, in [entries]' order within each group: the
/// songs of [favoriteSongs], then of [librarySongs], then (unless the
/// budget is [OfflineBudget.libraryOnly]) the most identified, as long as
/// the total stays within [budget].
List<OfflineFingerprintEntry> chooseOffline(
  List<OfflineFingerprintEntry> entries, {
  required Set<String> favoriteSongs,
  required Set<String> librarySongs,
  required OfflineBudget budget,
}) {
  final limit = budget.bytes;
  final ordered = [
    ...entries.where((e) => favoriteSongs.contains(e.songId)),
    ...entries.where(
      (e) =>
          librarySongs.contains(e.songId) && !favoriteSongs.contains(e.songId),
    ),
    if (limit != null)
      ...entries.where(
        (e) =>
            !librarySongs.contains(e.songId) &&
            !favoriteSongs.contains(e.songId),
      ),
  ];
  final chosen = <OfflineFingerprintEntry>[];
  var bytes = 0;
  for (final entry in ordered) {
    final size = entry.hashCount * offlineBytesPerHash;
    if (limit != null && bytes + size > limit) continue;
    bytes += size;
    chosen.add(entry);
  }
  return chosen;
}

/// The library's songs, and the favorites' among them, by catalog song ID.
typedef OfflineSongs = ({Set<String> favorites, Set<String> library});

/// Keeps the chosen catalog fingerprints on the phone: removes what is no
/// longer chosen or has changed, and fetches only what is new.
class OfflineCatalogSync {
  OfflineCatalogSync({
    required this._catalog,
    required this._fingerprints,
    required this._songs,
  });

  final AudioCatalog _catalog;
  final FingerprintsDao _fingerprints;
  final Future<OfflineSongs> Function() _songs;
  Future<int>? _syncing;

  /// Brings the kept fingerprints in line with [budget]; returns how many
  /// were fetched. Throws [ZemaFailure]s (what was fetched stays).
  Future<int> sync(OfflineBudget budget) =>
      _syncing ??= _sync(budget).whenComplete(() => _syncing = null);

  Future<int> _sync(OfflineBudget budget) async {
    final songs = await _songs();
    final chosen = chooseOffline(
      await _catalog.offlineFingerprints(),
      favoriteSongs: songs.favorites,
      librarySongs: songs.library,
      budget: budget,
    );
    final wanted = {for (final e in chosen) e.recordingId: e};
    final kept = {
      for (final k in await _fingerprints.keptCatalog()) k.recordingId: k,
    };
    bool current(KeptFingerprint k) =>
        k.version == fingerprintVersion &&
        k.revision == wanted[k.recordingId]?.revision;
    await _fingerprints.removeCatalog([
      for (final k in kept.values)
        if (!current(k)) k.recordingId,
    ]);
    final missing = [
      for (final e in chosen)
        if (kept[e.recordingId] == null || !current(kept[e.recordingId]!)) e,
    ];
    var fetched = 0;
    for (var i = 0; i < missing.length; i += 20) {
      final batch = missing.skip(i).take(20).toList();
      final songOf = {for (final e in batch) e.recordingId: e.songId};
      for (final f in await _catalog.fingerprints(songOf.keys.toList())) {
        await _fingerprints.putCatalog(
          f.recordingId,
          songId: songOf[f.recordingId]!,
          revision: f.revision,
          version: fingerprintVersion,
          data: f.fingerprint.toBytes(),
        );
        fetched++;
      }
    }
    return fetched;
  }
}

/// The catalog songs linked to library files, and to favorites.
Future<OfflineSongs> offlineSongs(Ref ref) async {
  final links = await ref
      .read(lyricsLinksRepositoryProvider)
      .watchLinks()
      .first;
  final favorites = await ref
      .read(databaseProvider)
      .collectionsDao
      .watchFavorites()
      .first;
  return (
    favorites: {for (final f in favorites) ?links[f.trackId]?.songId},
    library: {for (final link in links.values) ?link.songId},
  );
}

final offlineCatalogSyncProvider = Provider<OfflineCatalogSync?>((ref) {
  final catalog = ref.watch(audioCatalogProvider);
  if (catalog == null) return null;
  return OfflineCatalogSync(
    catalog: catalog,
    fingerprints: ref.watch(databaseProvider).fingerprintsDao,
    songs: () => offlineSongs(ref),
  );
});

/// How long between updates of the offline index.
const offlineSyncInterval = Duration(hours: 12);

/// Updates the offline index on Wi-Fi when Zema starts, comes back to the
/// front (at most every [offlineSyncInterval]) and when the budget changes.
/// Kept alive by the app shell.
final offlineCatalogUpdatesProvider = Provider<void>((ref) {
  final budget = ref.watch(offlineBudgetProvider);
  final sync = ref.watch(offlineCatalogSyncProvider);
  if (sync == null) return;
  final preferences = ref.read(sharedPreferencesProvider);
  const lastKey = 'identify.offlineSyncedAt';
  const budgetKey = 'identify.offlineSyncedBudget';

  Future<void> run() async {
    final last = DateTime.tryParse(preferences.getString(lastKey) ?? '');
    final due =
        last == null ||
        preferences.getString(budgetKey) != budget.name ||
        clock.now().difference(last) >= offlineSyncInterval;
    if (!due || !await ref.read(unmeteredNetworkProvider)()) return;
    final fetched = await sync.sync(budget);
    _log.info('Offline index: $fetched fingerprints fetched');
    await _saveSynced(preferences, lastKey, budgetKey, budget);
  }

  void start() => unawaited(
    run().catchError(
      (Object e) => _log.warning('Offline index update failed', e),
    ),
  );
  start();
  final lifecycle = AppLifecycleListener(onResume: start);
  ref.onDispose(lifecycle.dispose);
});

Future<void> _saveSynced(
  SharedPreferences preferences,
  String lastKey,
  String budgetKey,
  OfflineBudget budget,
) async {
  await preferences.setString(lastKey, clock.now().toIso8601String());
  await preferences.setString(budgetKey, budget.name);
}

/// How many catalog songs the offline index covers, and its size in bytes.
final offlineCoverageProvider = StreamProvider<({int songs, int bytes})>(
  (ref) => ref.watch(databaseProvider).fingerprintsDao.watchCatalogCoverage(),
);
