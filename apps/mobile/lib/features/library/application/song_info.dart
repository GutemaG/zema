import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/database/zema_database.dart';
import '../data/cover_store.dart';

/// Picks and keeps song covers. Tests override it.
final coverStoreProvider = Provider<CoverStore>((ref) => PickerCoverStore());

/// The covers the user picked, by track id.
final coversProvider = StreamProvider<Map<int, String>>(
  (ref) => ref
      .watch(databaseProvider)
      .libraryDao
      .watchOverrides()
      .map((rows) => {for (final row in rows) row.trackId: ?row.coverPath}),
);

/// What S09 edits: the song info as shown, and the picked cover.
typedef SongInfo = ({
  String title,
  String? artist,
  String? album,
  int? trackNumber,
  String? coverPath,
});

/// Song info for S09: the file's own tags ([file]) and the user's edits.
final songInfoProvider = FutureProvider.autoDispose
    .family<({Track file, TrackOverrideRow? edit})?, int>((ref, trackId) async {
      final dao = ref.watch(databaseProvider).libraryDao;
      final file = await dao.fileTrack(trackId);
      if (file == null) return null;
      return (file: file, edit: await dao.overrideFor(trackId));
    });

/// Saves [info] over [file]'s tags: only what differs from them is kept,
/// and nothing at all when nothing does. A cover replaced or removed is
/// deleted.
Future<void> saveSongInfo(
  WidgetRef ref,
  Track file,
  SongInfo info, {
  String? oldCover,
}) async {
  final dao = ref.read(databaseProvider).libraryDao;
  String? clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? differs(String? value, String? own) =>
      clean(value) == clean(own) ? null : clean(value);
  final title = clean(info.title);
  if (title == null) throw ArgumentError.value(info.title, 'title', 'empty');
  final edit = TrackOverrideRow(
    trackId: file.id,
    title: title == file.title ? null : title,
    artist: differs(info.artist, file.artist),
    album: differs(info.album, file.album),
    trackNumber: info.trackNumber == file.trackNumber ? null : info.trackNumber,
    coverPath: info.coverPath,
    updatedAt: clock.now(),
  );
  if (edit.title == null &&
      edit.artist == null &&
      edit.album == null &&
      edit.trackNumber == null &&
      edit.coverPath == null) {
    await dao.clearOverride(file.id);
  } else {
    await dao.setOverride(edit);
  }
  if (oldCover != null && oldCover != info.coverPath) {
    await ref.read(coverStoreProvider).delete(oldCover);
  }
}

/// Forgets track [trackId]'s edits and its picked cover.
Future<void> resetSongInfo(WidgetRef ref, int trackId) async {
  final dao = ref.read(databaseProvider).libraryDao;
  final cover = (await dao.overrideFor(trackId))?.coverPath;
  await dao.clearOverride(trackId);
  await ref.read(coverStoreProvider).delete(cover);
}
