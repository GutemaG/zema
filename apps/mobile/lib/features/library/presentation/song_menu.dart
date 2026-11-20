import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../clips/application/test_clip.dart';
import '../../detection/application/lyrics_overlay_sync.dart';
import '../../detection/application/player_overlay.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../../lyrics/presentation/match_lyrics_sheet.dart';
import '../../player/application/player_providers.dart';
import '../application/album_grouping.dart';
import '../application/favorites.dart';
import '../application/library_providers.dart';
import 'add_to_playlist_sheet.dart';
import 'widgets/track_art.dart';

/// Opens C03, the song menu, for [track].
Future<void> showSongMenu(BuildContext context, Track track) {
  return showModalBottomSheet<void>(
    context: context,
    // As tall as the menu needs: the default 9/16 cap hides the last items
    // on most phones. It still scrolls when the screen is shorter.
    isScrollControlled: true,
    builder: (_) => SongMenu(track: track, host: context),
  );
}

/// The "More" button on a track row (and Now Playing) that opens C03.
class SongMenuButton extends StatelessWidget {
  const SongMenuButton({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.songMenu(track.title),
      icon: Icon(Icons.more_vert, color: context.zemaColors.muted),
      onPressed: () => unawaited(showSongMenu(context, track)),
    );
  }
}

/// C03: what can be done with one song. Each action closes the menu first;
/// snackbars and navigation then happen on [host], the page that opened it.
/// View lyrics and edit info come with intent 003.
class SongMenu extends ConsumerWidget {
  const SongMenu({super.key, required this.track, required this.host});

  final Track track;
  final BuildContext host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final favorite = ref.watch(isFavoriteProvider(track.id));
    final sharing = ref.watch(audioShareServiceProvider);
    final messenger = ScaffoldMessenger.of(host);
    final router = GoRouter.of(host);

    /// Closes the menu, then runs [action].
    VoidCallback close(Future<void> Function() action) => () {
      Navigator.of(context).pop();
      unawaited(action());
    };

    void notify(String message, {SnackBarAction? action}) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          // Undo is only offered briefly.
          SnackBar(content: Text(message), action: action, persist: false),
        );
    }

    Widget item(IconData icon, String label, VoidCallback onTap) => ListTile(
      leading: Icon(icon, color: colors.text),
      title: Text(label),
      onTap: onTap,
    );

    // Read up front: the actions run after the menu is gone.
    final player = ref.read(playerControllerProvider);
    final library = ref.read(libraryRepositoryProvider);
    final favorites = ref.read(favoritesControllerProvider);
    final lyrics = ref.read(lyricsLinksControllerProvider);
    final linkedSong = ref.watch(trackSongProvider(track.id)).value;
    final linked = linkedSong != null;
    final overlay = ref.read(lyricsOverlayProvider);
    final choices = ref.read(overlayChoicesProvider.notifier);
    final queue = ref.read(playerStateProvider).value;
    final container = ProviderScope.containerOf(context, listen: false);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ZemaSpacing.screenSide,
                0,
                ZemaSpacing.screenSide,
                12,
              ),
              child: Row(
                children: [
                  TrackArt(track: track, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            track.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.text,
                            ),
                          ),
                        ),
                        Text(
                          track.artist ?? l10n.unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.line),
            item(
              Icons.playlist_play,
              l10n.songPlayNext,
              close(() async {
                await player.playNext(track);
                notify(l10n.songPlayingNext(track.title));
              }),
            ),
            item(
              Icons.queue_music,
              l10n.songAddToQueue,
              close(() async {
                await player.addToQueue(track);
                notify(l10n.songAddedToQueue(track.title));
              }),
            ),
            item(
              Icons.playlist_add,
              l10n.songAddToPlaylist,
              close(() async {
                if (host.mounted) await showAddToPlaylistSheet(host, track);
              }),
            ),
            item(
              favorite ? Icons.favorite : Icons.favorite_border,
              favorite ? l10n.songUnfavorite : l10n.songFavorite,
              close(() async {
                await favorites.set(track.id, favorite: !favorite);
                notify(
                  favorite
                      ? l10n.songUnfavorited(track.title)
                      : l10n.songFavorited(track.title),
                );
              }),
            ),
            if (linkedSong != null)
              item(
                Icons.article_outlined,
                l10n.songViewLyrics,
                close(
                  () async => router.go(
                    AppRoutes.song(
                      linkedSong.id,
                      base: AppRoutes.detailBase(
                        router.routerDelegate.currentConfiguration.uri.path,
                      ),
                    ),
                  ),
                ),
              ),
            if (linked && Platform.isAndroid)
              item(
                Icons.picture_in_picture_alt_outlined,
                l10n.songFloatLyrics,
                close(() async {
                  if (!await overlay.canShow()) {
                    await overlay.openSettings();
                    notify(l10n.songFloatLyricsAllow);
                    return;
                  }
                  choices.open(playerOverlayKey(track.id));
                  if (queue?.current?.id != track.id) {
                    if (queue == null || queue.queue.isEmpty) {
                      await player.playList([track]);
                    } else {
                      await player.playNext(track);
                      await player.next();
                    }
                  }
                  notify(l10n.songFloatLyricsOn);
                }),
              ),
            if (linked && ref.watch(clipEncoderProvider).isSupported)
              item(
                Icons.movie_outlined,
                l10n.songTestClip,
                close(() async {
                  var shown = -1;
                  try {
                    final made = await makeTestClip(
                      container,
                      track,
                      onProgress: (f) {
                        final percent = (f * 100).floor();
                        if (percent ~/ 10 == shown ~/ 10) return;
                        shown = percent;
                        notify(l10n.songTestClipMaking(percent));
                      },
                    );
                    final seconds = (made.clip.took.inMilliseconds / 1000)
                        .toStringAsFixed(1);
                    notify(
                      made.saved
                          ? l10n.songTestClipDone(
                              seconds,
                              made.clip.width,
                              made.clip.height,
                            )
                          : l10n.songTestClipNotSaved(
                              seconds,
                              made.clip.width,
                              made.clip.height,
                            ),
                    );
                  } on Exception {
                    notify(l10n.songTestClipFailed);
                  }
                }),
              ),
            item(
              Icons.lyrics_outlined,
              linked ? l10n.songChangeLyrics : l10n.songMatchLyrics,
              close(() async {
                if (!host.mounted) return;
                final song = await showMatchLyricsSheet(host, track);
                if (song != null) notify(l10n.songLyricsLinked(song.title));
              }),
            ),
            if (linked)
              item(
                Icons.link_off,
                l10n.songUnlinkLyrics,
                close(() async {
                  await lyrics.unlink(track);
                  notify(l10n.songLyricsUnlinked(track.title));
                }),
              ),
            item(
              Icons.album_outlined,
              l10n.songGoToAlbum,
              close(() async => router.go(AppRoutes.album(AlbumId.of(track)))),
            ),
            item(
              Icons.person_outline,
              l10n.songGoToArtist,
              close(() async => router.go(AppRoutes.artist(track.artist))),
            ),
            item(
              Icons.visibility_off_outlined,
              l10n.songHide,
              close(() async {
                await library.hideTrack(track.id);
                notify(
                  l10n.songHidden(track.title),
                  action: SnackBarAction(
                    label: l10n.actionUndo,
                    onPressed: () => unawaited(library.unhideTrack(track.id)),
                  ),
                );
              }),
            ),
            if (sharing.isSupported)
              item(
                Icons.share_outlined,
                l10n.songShare,
                close(() async {
                  if (!await sharing.share(track)) {
                    notify(l10n.songShareFailed);
                  }
                }),
              ),
          ],
        ),
      ),
    );
  }
}
