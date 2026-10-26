import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/application/player_providers.dart';
import '../../application/favorites.dart';
import '../../application/library_providers.dart';
import '../../application/track_selection.dart';
import '../add_to_playlist_sheet.dart';

/// Shown in Tracks while selecting, in place of the search field and the
/// Play / Shuffle bar: the count, Select all, and what can be done with
/// every selected song. Each action ends selection and confirms with a
/// snackbar.
class TrackSelectionBar extends ConsumerWidget {
  const TrackSelectionBar({
    super.key,
    required this.selected,
    required this.visible,
  });

  /// The selected songs in list order, including ones a search hides.
  final List<Track> selected;

  /// The list as shown (filtered), for Select all.
  final List<Track> visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final selection = ref.read(trackSelectionProvider.notifier);
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final allFavorite = selected.every((t) => favoriteIds.contains(t.id));
    final ids = [for (final t in selected) t.id];
    final messenger = ScaffoldMessenger.of(context);
    // Read up front: ending selection removes this bar before the actions
    // finish.
    final player = ref.read(playerControllerProvider);
    final favorites = ref.read(favoritesControllerProvider);
    final library = ref.read(libraryRepositoryProvider);

    void notify(String message, {SnackBarAction? action}) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), action: action, persist: false),
        );
    }

    Future<void> addToPlaylist() async {
      final result = await showAddTracksToPlaylistSheet(context, selected);
      if (result == null) return;
      selection.end();
      notify(l10n.selectionAddedToPlaylist(result.added, result.name));
    }

    Future<void> addToQueue() async {
      selection.end();
      await player.addAllToQueue(selected);
      notify(l10n.selectionAddedToQueue(selected.length));
    }

    Future<void> favorite() async {
      selection.end();
      await favorites.setAll(ids, favorite: !allFavorite);
      notify(
        allFavorite
            ? l10n.selectionUnfavorited(ids.length)
            : l10n.selectionFavorited(ids.length),
      );
    }

    Future<void> hide() async {
      selection.end();
      await library.hideTracks(ids);
      notify(
        l10n.selectionHidden(ids.length),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () => unawaited(library.unhideTracks(ids)),
        ),
      );
    }

    Widget action(IconData icon, String tooltip, Future<void> Function() run) =>
        IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: colors.text),
          onPressed: () => unawaited(run()),
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.selectionClose,
                icon: Icon(Icons.close, color: colors.text),
                onPressed: selection.end,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.selectionCount(selected.length),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    selection.selectAll([for (final t in visible) t.id]),
                child: Text(l10n.selectionSelectAll),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            action(Icons.playlist_add, l10n.songAddToPlaylist, addToPlaylist),
            action(Icons.queue_music, l10n.songAddToQueue, addToQueue),
            action(
              allFavorite ? Icons.favorite : Icons.favorite_border,
              allFavorite ? l10n.songUnfavorite : l10n.songFavorite,
              favorite,
            ),
            action(Icons.visibility_off_outlined, l10n.songHide, hide),
          ],
        ),
      ],
    );
  }
}
