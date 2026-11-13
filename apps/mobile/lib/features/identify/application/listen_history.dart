import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../catalog/application/catalog_index.dart';
import '../../library/application/library_providers.dart';

/// A History row: a library [track], or a catalog [song].
typedef HistoryEntry = ({
  int id,
  Track? track,
  CatalogEntry? song,
  DateTime at,
});

extension HistoryEntryText on HistoryEntry {
  String get title => track?.title ?? song!.title;

  String? get artist => track == null ? song!.artist : track!.artist;
}

final listenHistoryProvider = StreamProvider.autoDispose<List<HistoryEntry>>((
  ref,
) async* {
  final tracksLoaded = ref.watch(libraryTracksProvider.future);
  final songsLoaded = ref.watch(catalogEntriesProvider.future);
  final history = ref.watch(databaseProvider).identifiedDao;
  final trackById = {for (final t in await tracksLoaded) t.id: t};
  final songById = {for (final s in await songsLoaded) s.id: s};
  yield* history.watchAll().map(
    (rows) => [
      for (final row in rows)
        if (trackById[row.trackId] case final track?)
          (id: row.id, track: track, song: null, at: row.identifiedAt)
        else if (songById[row.songId] case final song?)
          (id: row.id, track: null, song: song, at: row.identifiedAt),
    ],
  );
});
