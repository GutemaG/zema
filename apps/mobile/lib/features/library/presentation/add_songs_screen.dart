import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/library_providers.dart';
import '../application/playlists.dart';
import '../application/tracks_query.dart';
import 'widgets/library_search_field.dart';
import 'widgets/track_row.dart';

/// S18: every visible song with a checkbox and a search field. Songs
/// already in the playlist are checked and can't be picked again. The
/// sticky "Add N songs" button adds the picked songs, in the order they
/// were picked, to the end and goes back.
class AddSongsScreen extends ConsumerStatefulWidget {
  const AddSongsScreen({super.key, required this.playlistId});

  final int? playlistId;

  @override
  ConsumerState<AddSongsScreen> createState() => _AddSongsScreenState();
}

class _AddSongsScreenState extends ConsumerState<AddSongsScreen> {
  final _search = TextEditingController();
  var _query = '';

  /// Picked track IDs in the order they were picked. Kept by ID, so a new
  /// search doesn't lose them.
  final _picked = <int>{};
  var _adding = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(int trackId) => setState(() {
    if (!_picked.remove(trackId)) _picked.add(trackId);
  });

  Future<void> _add(Playlist playlist) async {
    setState(() => _adding = true);
    await ref
        .read(playlistsControllerProvider)
        .add(playlist.id, _picked.toList());
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.playlistId;
    final playlist = id == null ? null : ref.watch(playlistProvider(id)).value;
    final tracks = ref.watch(libraryTracksProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playlistAddSongs),
        bottom: playlist == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: context.zemaColors.muted),
                  ),
                ),
              ),
      ),
      body: switch ((playlist, tracks)) {
        (final playlist?, final tracks?) => _buildList(playlist, tracks),
        (null, _) when ref.watch(playlistsProvider).hasValue || id == null =>
          EmptyState(
            kind: EmptyStateKind.empty,
            icon: Icons.queue_music,
            title: l10n.playlistGoneTitle,
            message: l10n.playlistGoneMessage,
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: playlist == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ZemaSpacing.screenSide,
                  8,
                  ZemaSpacing.screenSide,
                  12,
                ),
                child: FilledButton(
                  onPressed: _picked.isEmpty || _adding
                      ? null
                      : () => unawaited(_add(playlist)),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.zemaColors.primary,
                    foregroundColor: context.zemaColors.onPrimary,
                    minimumSize: const Size.fromHeight(ZemaSpacing.minTap),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l10n.playlistAddCount(_picked.length)),
                ),
              ),
            ),
    );
  }

  Widget _buildList(Playlist playlist, List<Track> all) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final visible = filterTracks(all, _query);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            8,
            ZemaSpacing.screenSide,
            8,
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
                    final inPlaylist = playlist.contains(track.id);
                    final checked = inPlaylist || _picked.contains(track.id);
                    return MergeSemantics(
                      key: ValueKey(track.id),
                      child: Semantics(
                        checked: checked,
                        enabled: !inPlaylist,
                        value: inPlaylist ? l10n.playlistInPlaylist : null,
                        child: Opacity(
                          opacity: inPlaylist ? 0.55 : 1,
                          child: TrackRow(
                            track: track,
                            onTap: inPlaylist ? null : () => _toggle(track.id),
                            trailing: Checkbox(
                              value: checked,
                              activeColor: colors.primary,
                              checkColor: colors.onPrimary,
                              onChanged: inPlaylist
                                  ? null
                                  : (_) => _toggle(track.id),
                            ),
                          ),
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
