import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/database/catalog_dao.dart';
import '../../../app/database/database_provider.dart';
import '../../../app/preferences_provider.dart';
import '../../contribute/application/my_contributions.dart';

final _log = Logger('catalog.index');

/// What [CatalogIndexRefresher.refresh] did.
enum IndexRefresh {
  /// Fetched and saved.
  refreshed,

  /// Skipped: the saved index is recent enough.
  fresh,

  /// Skipped: this build has no backend.
  notConfigured,
}

/// Keeps the phone's copy of the catalog's song index up to date.
class CatalogIndexRefresher {
  CatalogIndexRefresher({
    required this._catalog,
    required this._dao,
    required this._preferences,
  });

  /// How old the index may get before Zema starting or coming back to the
  /// front fetches it again.
  static const maxAge = Duration(minutes: 30);

  /// Where the time of the last refresh is kept (milliseconds since epoch).
  static const refreshedAtKey = 'catalog.indexRefreshedAt';

  final CatalogRepository? _catalog;
  final CatalogDao _dao;
  final SharedPreferences _preferences;
  Future<IndexRefresh>? _running;

  /// When the index was last refreshed, or null if never.
  DateTime? get refreshedAt => switch (_preferences.getInt(refreshedAtKey)) {
    final ms? => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
    null => null,
  };

  /// Fetches the index and replaces the saved one, unless it is younger than
  /// [maxAge] (ignored when [force]). Calls made while one runs share it.
  ///
  /// Throws the catalog's [ZemaFailure] when fetching fails; the saved index
  /// is then left as it was.
  Future<IndexRefresh> refresh({bool force = false}) =>
      _running ??= _refresh(force).whenComplete(() => _running = null);

  Future<IndexRefresh> _refresh(bool force) async {
    final catalog = _catalog;
    if (catalog == null) return IndexRefresh.notConfigured;
    final last = refreshedAt;
    if (!force && last != null && clock.now().difference(last) < maxAge) {
      return IndexRefresh.fresh;
    }
    final entries = await catalog.index();
    await _dao.replaceAll(entries);
    await _preferences.setInt(
      refreshedAtKey,
      clock.now().millisecondsSinceEpoch,
    );
    _log.info('Song index refreshed: ${entries.length} songs');
    return IndexRefresh.refreshed;
  }
}

final catalogIndexRefresherProvider = Provider<CatalogIndexRefresher>(
  (ref) => CatalogIndexRefresher(
    catalog: ref.watch(catalogRepositoryProvider),
    dao: ref.watch(databaseProvider).catalogDao,
    preferences: ref.watch(sharedPreferencesProvider),
  ),
);

/// The phone's copy of the catalog's song index, by ID. Empty until the
/// first refresh.
final catalogEntriesProvider = StreamProvider<List<CatalogEntry>>(
  (ref) => ref.watch(databaseProvider).catalogDao.watchEntries(),
);

/// The songs most recently approved in the catalog, newest first (ties by
/// title), for Home's community row. Updates whenever the index does.
final newLyricsProvider = Provider<List<CatalogEntry>>((ref) {
  const count = 10;
  final entries = [...?ref.watch(catalogEntriesProvider).value]
    ..sort((a, b) {
      final newer = b.approvedAt.compareTo(a.approvedAt);
      return newer != 0 ? newer : a.title.compareTo(b.title);
    });
  return entries.take(count).toList();
});

/// Refreshes the index when the app starts or comes back to the front, if
/// it is stale, and at once when one of the user's contributions is
/// approved, so its song can be matched. Failing is normal offline, so it is
/// only logged. Kept alive by the app shell.
final catalogStartupRefreshProvider = Provider<void>((ref) {
  void refresh({bool force = false}) => unawaited(
    ref
        .read(catalogIndexRefresherProvider)
        .refresh(force: force)
        .then<void>((_) {})
        .catchError(
          (Object e) => _log.info('Song index not refreshed', e),
          test: (e) => e is ZemaFailure,
        ),
  );
  refresh();
  final lifecycle = AppLifecycleListener(onResume: refresh);
  ref.onDispose(lifecycle.dispose);
  ref.listen(contributionChangesProvider, (_, next) {
    if (next.value?.any((c) => c.status == ContributionStatus.approved) ??
        false) {
      refresh(force: true);
    }
  });
});
