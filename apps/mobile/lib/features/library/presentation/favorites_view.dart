import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../player/application/player_providers.dart';
import '../application/favorites.dart';
import '../application/tracks_query.dart';
import 'song_menu.dart';
import 'widgets/library_search_field.dart';
import 'widgets/play_shuffle_bar.dart';
import 'widgets/swipe_remove_background.dart';
import 'widgets/track_row.dart';

/// S14: favorited songs, newest first, with search and Play / Shuffle.
/// Swipe a song away to unfavorite it; Undo puts it back in place.
class FavoritesView extends ConsumerStatefulWidget {
  const FavoritesView({super.key});

  @override
  ConsumerState<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends ConsumerState<FavoritesView> {
  final _search = TextEditingController();
  var _query = '';

  /// The list shown right after a swipe, until the database reports the
  /// change: a dismissed row must leave the tree at once.
  List<Track>? _pending;
  List<Track>? _pendingFor;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _remove(List<Track> all, Track track) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _pending = [...all]..removeWhere((t) => t.id == track.id);
      _pendingFor = ref.read(favoritesProvider).value;
    });
    final undo = await ref.read(favoritesControllerProvider).remove(track.id);
    if (undo == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Undo is only offered briefly.
          persist: false,
          content: Text(l10n.songUnfavorited(track.title)),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => unawaited(undo()),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    return switch (favorites) {
      AsyncData(:final value) => _buildList(
        identical(value, _pendingFor) ? _pending! : value,
      ),
      AsyncError() => EmptyState(
        kind: EmptyStateKind.error,
        title: l10n.libraryScanFailedTitle,
        message: l10n.libraryScanFailedMessage,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildList(List<Track> all) {
    final l10n = AppLocalizations.of(context);
    if (all.isEmpty) {
      return EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.favorite_border,
        title: l10n.favoritesEmptyTitle,
        message: l10n.favoritesEmptyMessage,
      );
    }
    final currentId = ref.watch(currentTrackProvider.select((t) => t?.id));
    final player = ref.read(playerControllerProvider);
    final visible = filterTracks(all, _query);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            8,
            ZemaSpacing.screenSide,
            0,
          ),
          child: LibrarySearchField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _search.clear();
              setState(() => _query = '');
            },
          ),
        ),
        PlayShuffleBar(
          label: l10n.librarySongCount(visible.length),
          tracks: visible,
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyState(
                  kind: EmptyStateKind.empty,
                  icon: Icons.search_off,
                  title: l10n.libraryNoResultsTitle,
                  message: l10n.libraryNoResultsMessage,
                )
              : ListView.builder(
                  itemExtent: TrackRow.height,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final track = visible[index];
                    void remove() => unawaited(_remove(all, track));
                    return Semantics(
                      key: ValueKey(track.id),
                      customSemanticsActions: {
                        CustomSemanticsAction(label: l10n.songUnfavorite):
                            remove,
                      },
                      child: Dismissible(
                        key: ValueKey('dismiss-${track.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => remove(),
                        background: const SwipeRemoveBackground(),
                        child: TrackRow(
                          track: track,
                          isCurrent: track.id == currentId,
                          onTap: () =>
                              unawaited(player.playList(visible, start: index)),
                          trailing: SongMenuButton(track: track),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
