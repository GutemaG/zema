import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../player/application/player_providers.dart';
import '../application/playlists.dart';
import 'album_screen.dart';
import 'playlist_dialog.dart';
import 'song_menu.dart';
import 'widgets/play_shuffle_bar.dart';
import 'widgets/playlist_collage.dart';
import 'widgets/swipe_remove_background.dart';
import 'widgets/track_row.dart';

/// S17: collage, name, description, "songs · duration", Add songs, Play
/// and Shuffle, then the songs: drag to reorder, swipe to remove (with
/// undo). The menu renames or deletes the playlist. Shows C07 when the
/// playlist no longer exists (or [id] is null: a malformed link).
class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key, required this.id});

  final int? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = this.id;
    final playlist = id == null
        ? const AsyncData<Playlist?>(null)
        : ref.watch(playlistProvider(id));
    final found = playlist.value;
    return Scaffold(
      appBar: AppBar(
        actions: [if (found != null) _PlaylistMenu(playlist: found)],
      ),
      body: switch (playlist) {
        AsyncData() when found != null => _PlaylistBody(playlist: found),
        AsyncData() => EmptyState(
          kind: EmptyStateKind.empty,
          icon: Icons.queue_music,
          title: l10n.playlistGoneTitle,
          message: l10n.playlistGoneMessage,
        ),
        AsyncError() => EmptyState(
          kind: EmptyStateKind.error,
          title: l10n.libraryScanFailedTitle,
          message: l10n.libraryScanFailedMessage,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Rename (S16) and Delete (after confirming).
class _PlaylistMenu extends ConsumerWidget {
  const _PlaylistMenu({required this.playlist});

  final Playlist playlist;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(playlistsControllerProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.playlistDeleteTitle),
        content: Text(l10n.playlistDeleteMessage(playlist.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Leave first, so the page doesn't flash "not found".
    context.pop();
    await controller.delete(playlist.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<void>(
      tooltip: l10n.playlistMenu(playlist.name),
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () =>
              unawaited(showPlaylistDialog(context, editing: playlist)),
          child: Text(l10n.playlistRename),
        ),
        PopupMenuItem(
          onTap: () => unawaited(_delete(context, ref)),
          child: Text(l10n.playlistDelete),
        ),
      ],
    );
  }
}

class _PlaylistBody extends ConsumerStatefulWidget {
  const _PlaylistBody({required this.playlist});

  final Playlist playlist;

  @override
  ConsumerState<_PlaylistBody> createState() => _PlaylistBodyState();
}

class _PlaylistBodyState extends ConsumerState<_PlaylistBody> {
  /// The order shown right after a drag or swipe, until the database
  /// reports the change: a dismissed row must leave the tree at once, and a
  /// dropped row shouldn't jump back for a frame.
  List<Track>? _pending;
  Playlist? _pendingFor;

  List<Track> get _tracks => identical(widget.playlist, _pendingFor)
      ? _pending!
      : widget.playlist.tracks;

  void _showPending(List<Track> tracks) => setState(() {
    _pending = tracks;
    _pendingFor = widget.playlist;
  });

  void _move(int from, int to) {
    final tracks = [..._tracks];
    tracks.insert(to, tracks.removeAt(from));
    _showPending(tracks);
    unawaited(
      ref.read(playlistsControllerProvider).reorder(widget.playlist, [
        for (final t in tracks) t.id,
      ]),
    );
  }

  Future<void> _remove(Track track) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final playlist = widget.playlist;
    _showPending([..._tracks]..remove(track));
    final undo = await ref
        .read(playlistsControllerProvider)
        .remove(playlist.id, track.id);
    if (undo == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Undo is only offered briefly.
          persist: false,
          content: Text(l10n.playlistRemoved(track.title)),
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
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final playlist = widget.playlist;
    final tracks = _tracks;
    final currentId = ref.watch(currentTrackProvider.select((t) => t?.id));
    final player = ref.read(playerControllerProvider);
    final info = [
      l10n.librarySongCount(tracks.length),
      if (tracks.isNotEmpty) formatTotalDuration(l10n, playlist.duration),
    ].join(' · ');
    void addSongs() => unawaited(context.push(AppRoutes.addSongs(playlist.id)));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              0,
              ZemaSpacing.screenSide,
              4,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cover = min(200.0, constraints.maxWidth * 0.55);
                return Column(
                  children: [
                    PlaylistCollage(
                      playlist: playlist,
                      size: cover,
                      radius: 16,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        playlist.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.text,
                        ),
                      ),
                    ),
                    if (playlist.description case final description?) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      info,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: addSongs,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.playlistAddSongs),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (tracks.isEmpty)
          // EmptyState sizes itself with a LayoutBuilder (no intrinsic
          // height) and scrolls on its own when short of space.
          SliverFillRemaining(
            child: EmptyState(
              kind: EmptyStateKind.empty,
              icon: Icons.queue_music,
              title: l10n.playlistEmptyTitle,
              message: l10n.playlistEmptyMessage,
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: PlayShuffleBar(
              label: l10n.librarySongCount(tracks.length),
              tracks: tracks,
            ),
          ),
          SliverReorderableList(
            itemExtent: TrackRow.height,
            itemCount: tracks.length,
            onReorderItem: _move,
            proxyDecorator: (child, _, _) =>
                Material(color: colors.surface, elevation: 4, child: child),
            itemBuilder: (context, index) {
              final track = tracks[index];
              void remove() => unawaited(_remove(track));
              return Semantics(
                key: ValueKey(track.id),
                customSemanticsActions: {
                  CustomSemanticsAction(label: l10n.playlistRemove): remove,
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
                        unawaited(player.playList(tracks, start: index)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SongMenuButton(track: track),
                        ReorderableDragStartListener(
                          index: index,
                          child: Tooltip(
                            message: l10n.queueReorder,
                            child: SizedBox.square(
                              dimension: ZemaSpacing.minTap,
                              child: Icon(
                                Icons.drag_handle,
                                color: colors.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: ZemaSpacing.screenSide),
          ),
        ],
      ],
    );
  }
}
