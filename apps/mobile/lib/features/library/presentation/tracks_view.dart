import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../player/application/player_providers.dart';
import '../application/library_providers.dart';
import '../application/library_sync_controller.dart';
import '../application/track_selection.dart';
import '../application/track_sort_provider.dart';
import '../application/tracks_query.dart';
import 'song_menu.dart';
import 'widgets/alphabet_scroller.dart';
import 'widgets/library_search_field.dart';
import 'widgets/play_shuffle_bar.dart';
import 'widgets/track_row.dart';
import 'widgets/track_selection_bar.dart';

/// S10: every track, with search, sort, an alphabet strip, and Play /
/// Shuffle. Also shows the first-scan progress and scan failures.
///
/// A long-press starts multi-select ([TrackSelectionBar]); back ends it.
class TracksView extends ConsumerStatefulWidget {
  const TracksView({super.key});

  @override
  ConsumerState<TracksView> createState() => _TracksViewState();
}

class _TracksViewState extends ConsumerState<TracksView> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _setQuery(String value) => setState(() => _query = value);

  void _clearQuery() {
    _search.clear();
    _setQuery('');
  }

  void _jumpTo(int index) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    _scroll.jumpTo(
      (index * TrackRow.height).clamp(0, position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sync = ref.watch(librarySyncProvider);
    final tracks = ref.watch(libraryTracksProvider);

    ref.listen(librarySyncProvider, (previous, next) {
      final hasTracks = ref.read(libraryTracksProvider).value?.isNotEmpty;
      if (next.hasFailed && previous?.hasFailed != true && hasTracks == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.libraryScanFailedSnack),
            action: SnackBarAction(
              label: l10n.actionTryAgain,
              onPressed: ref.read(librarySyncProvider.notifier).sync,
            ),
          ),
        );
      }
    });

    // Songs that leave the library (hidden elsewhere, a rescan) leave the
    // selection too.
    ref.listen(libraryTracksProvider, (_, next) {
      if (next.value case final tracks?) {
        ref.read(trackSelectionProvider.notifier).retain({
          for (final t in tracks) t.id,
        });
      }
    });

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (ref.read(trackSelectionProvider) == null) return false;
        ref.read(trackSelectionProvider.notifier).end();
        return true;
      },
      child: _buildBody(tracks, sync),
    );
  }

  Widget _buildBody(AsyncValue<List<Track>> tracks, LibrarySyncState sync) {
    final l10n = AppLocalizations.of(context);
    void retry() => ref.read(librarySyncProvider.notifier).sync();
    return switch (tracks) {
      AsyncData(:final value) when value.isNotEmpty => _buildList(value),
      AsyncData() when sync.hasFailed => EmptyState(
        kind: EmptyStateKind.error,
        title: l10n.libraryScanFailedTitle,
        message: l10n.libraryScanFailedMessage,
        actionLabel: l10n.actionTryAgain,
        onAction: retry,
      ),
      AsyncData() when sync.lastResult != null && !sync.isScanning =>
        EmptyState(
          kind: EmptyStateKind.empty,
          title: l10n.libraryEmptyTitle,
          message: l10n.libraryEmptyMessage,
        ),
      AsyncError() => EmptyState(
        kind: EmptyStateKind.error,
        title: l10n.libraryScanFailedTitle,
        message: l10n.libraryScanFailedMessage,
        actionLabel: l10n.actionTryAgain,
        onAction: () => ref.invalidate(libraryTracksProvider),
      ),
      // Loading, or nothing stored yet while the first scan runs.
      _ => _Scanning(label: l10n.libraryScanning),
    };
  }

  Widget _buildList(List<Track> all) {
    final l10n = AppLocalizations.of(context);
    final sort = ref.watch(trackSortProvider);
    final currentId = ref.watch(currentTrackProvider.select((t) => t?.id));
    final player = ref.read(playerControllerProvider);
    final selectedIds = ref.watch(trackSelectionProvider);
    final selection = ref.read(trackSelectionProvider.notifier);
    final visible = sortTracks(filterTracks(all, _query), sort);
    final sections = sort.isAlphabetical
        ? sectionStarts(visible, sort)
        : const <String, int>{};
    final showStrip = sections.length > 1;

    return Column(
      children: [
        if (selectedIds != null)
          TrackSelectionBar(
            selected: [
              for (final t in sortTracks(all, sort))
                if (selectedIds.contains(t.id)) t,
            ],
            visible: visible,
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              8,
              ZemaSpacing.screenSide,
              0,
            ),
            child: LibrarySearchField(
              controller: _search,
              onChanged: _setQuery,
              onClear: _clearQuery,
            ),
          ),
          PlayShuffleBar(
            label: l10n.librarySongCount(visible.length),
            tracks: visible,
            actions: [
              _SortMenu(
                sort: sort,
                onSort: (s) => ref.read(trackSortProvider.notifier).set(s),
              ),
            ],
          ),
        ],
        Expanded(
          child: visible.isEmpty
              ? EmptyState(
                  kind: EmptyStateKind.empty,
                  icon: Icons.search_off,
                  title: l10n.libraryNoResultsTitle,
                  message: l10n.libraryNoResultsMessage,
                )
              : Stack(
                  children: [
                    ListView.builder(
                      controller: _scroll,
                      itemExtent: TrackRow.height,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(right: showStrip ? 12 : 0),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final track = visible[index];
                        if (selectedIds != null) {
                          final selected = selectedIds.contains(track.id);
                          return TrackRow(
                            key: ValueKey(track.id),
                            track: track,
                            isCurrent: track.id == currentId,
                            selected: selected,
                            onTap: () => selection.toggle(track.id),
                            trailing: Checkbox(
                              value: selected,
                              onChanged: (_) => selection.toggle(track.id),
                            ),
                          );
                        }
                        return TrackRow(
                          key: ValueKey(track.id),
                          track: track,
                          isCurrent: track.id == currentId,
                          onTap: () =>
                              unawaited(player.playList(visible, start: index)),
                          onLongPress: () => selection.start(track.id),
                          trailing: SongMenuButton(track: track),
                        );
                      },
                    ),
                    if (showStrip)
                      Positioned(
                        top: 4,
                        bottom: 4,
                        right: 0,
                        child: AlphabetScroller(
                          letters: sections.keys.toList(),
                          onSelected: (letter) => _jumpTo(sections[letter]!),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Sort field and direction.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onSort});

  final TrackSort sort;
  final ValueChanged<TrackSort> onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final fieldNames = {
      TrackSortField.title: l10n.sortTitle,
      TrackSortField.artist: l10n.sortArtist,
      TrackSortField.album: l10n.sortAlbum,
      TrackSortField.dateAdded: l10n.sortDateAdded,
      TrackSortField.duration: l10n.sortDuration,
    };
    return PopupMenuButton<Object>(
      tooltip: l10n.librarySortTooltip,
      icon: Icon(Icons.sort, color: colors.text),
      onSelected: (choice) => onSort(switch (choice) {
        TrackSortField field => TrackSort(field, descending: sort.descending),
        final bool descending => TrackSort(sort.field, descending: descending),
        _ => sort,
      }),
      itemBuilder: (context) => [
        for (final MapEntry(key: field, value: name) in fieldNames.entries)
          CheckedPopupMenuItem<Object>(
            value: field,
            checked: field == sort.field,
            child: Text(name),
          ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem<Object>(
          value: false,
          checked: !sort.descending,
          child: Text(l10n.sortAscending),
        ),
        CheckedPopupMenuItem<Object>(
          value: true,
          checked: sort.descending,
          child: Text(l10n.sortDescending),
        ),
      ],
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    // Scrolls rather than overflowing on very short screens.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ZemaSpacing.screenSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.accent),
            const SizedBox(height: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
