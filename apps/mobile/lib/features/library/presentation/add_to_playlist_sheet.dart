import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/playlists.dart';
import 'playlist_dialog.dart';
import 'widgets/playlist_collage.dart';

/// Opens C04 for [track].
Future<void> showAddToPlaylistSheet(BuildContext context, Track track) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AddToPlaylistSheet(track: track),
  );
}

/// C04: "New playlist", then every playlist with a checkmark when it holds
/// [track]. A tap adds or removes the song at once; the sheet stays open.
class AddToPlaylistSheet extends ConsumerWidget {
  const AddToPlaylistSheet({super.key, required this.track});

  /// Share of the screen height the sheet may take.
  static const maxHeightFactor = 0.7;

  final Track track;

  Future<void> _newPlaylist(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(playlistsControllerProvider);
    final id = await showPlaylistDialog(context);
    if (id != null) await controller.add(id, [track.id]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final playlists = ref.watch(playlistsProvider).value ?? const [];
    final controller = ref.read(playlistsControllerProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height *
            AddToPlaylistSheet.maxHeightFactor,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ZemaSpacing.screenSide,
                0,
                ZemaSpacing.screenSide,
                8,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.songAddToPlaylist,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.soft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox.square(
                        dimension: 46,
                        child: Icon(Icons.add, color: colors.primaryText),
                      ),
                    ),
                    title: Text(l10n.playlistNew),
                    onTap: () => unawaited(_newPlaylist(context, ref)),
                  ),
                  for (final playlist in playlists)
                    CheckboxListTile(
                      key: ValueKey(playlist.id),
                      secondary: PlaylistCollage(playlist: playlist, size: 46),
                      title: Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        l10n.librarySongCount(playlist.tracks.length),
                      ),
                      value: playlist.contains(track.id),
                      activeColor: colors.primary,
                      checkColor: colors.onPrimary,
                      onChanged: (_) =>
                          unawaited(controller.toggle(playlist, track.id)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
