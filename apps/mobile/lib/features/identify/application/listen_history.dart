import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../library/application/library_providers.dart';

typedef HistoryEntry = ({int id, Track track, DateTime at});

final listenHistoryProvider = StreamProvider.autoDispose<List<HistoryEntry>>((
  ref,
) async* {
  final tracks = await ref.watch(libraryTracksProvider.future);
  final byId = {for (final t in tracks) t.id: t};
  yield* ref
      .watch(databaseProvider)
      .identifiedDao
      .watchAll()
      .map(
        (rows) => [
          for (final row in rows)
            if (byId[row.trackId] case final track?)
              (id: row.id, track: track, at: row.identifiedAt),
        ],
      );
});
