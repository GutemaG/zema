import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/not_found_screen.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../library/application/favorites.dart';
import '../../library/presentation/add_to_playlist_sheet.dart';
import '../../player/application/player_providers.dart';
import '../application/lyrics_links.dart';
import '../application/lyrics_prefs.dart';

/// S07: one song's title, transliteration, artist and album, Play,
/// favorite and add to playlist (for its first linked track), and tabs
/// with the full lyrics and the song's info. An unknown [songId] shows
/// C07.
class SongDetailScreen extends ConsumerWidget {
  const SongDetailScreen({super.key, required this.songId});

  final String? songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(lyricsSongsProvider);
    final song = songs.value?.where((s) => s.id == songId).firstOrNull;
    return switch (songs) {
      AsyncData() when song != null => _SongDetail(song: song),
      AsyncLoading() => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      _ => const NotFoundScreen(),
    };
  }
}

class _SongDetail extends ConsumerWidget {
  const _SongDetail({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final display = ref.watch(lyricsDisplayProvider);
    final displayController = ref.read(lyricsDisplayProvider.notifier);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: l10n.lyricsTextSmaller,
              icon: const Icon(Icons.text_decrease),
              onPressed: display.canShrink
                  ? () => unawaited(displayController.stepScale(-1))
                  : null,
            ),
            IconButton(
              tooltip: l10n.lyricsTextLarger,
              icon: const Icon(Icons.text_increase),
              onPressed: display.canGrow
                  ? () => unawaited(displayController.stepScale(1))
                  : null,
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _Header(song: song)),
            SliverToBoxAdapter(
              child: TabBar(
                tabs: [
                  Tab(text: l10n.songDetailLyricsTab),
                  Tab(text: l10n.songDetailInfoTab),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _LyricsTab(song: song, display: display),
              _InfoTab(song: song),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final track = ref.watch(songTracksProvider(song.id)).firstOrNull;
    final favorite = track != null && ref.watch(isFavoriteProvider(track.id));
    final byline = [song.artist ?? l10n.unknownArtist, ?song.album].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        0,
        ZemaSpacing.screenSide,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              song.title,
              style: textTheme.headlineSmall?.copyWith(color: colors.text),
            ),
          ),
          if (song.transliteration case final transliteration?)
            Text(
              transliteration,
              style: textTheme.titleMedium?.copyWith(color: colors.muted),
            ),
          const SizedBox(height: 4),
          Text(
            byline,
            style: textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 12),
          if (track == null)
            Text(
              l10n.songDetailNotOnPhone,
              style: textTheme.bodyMedium?.copyWith(color: colors.faint),
            )
          else
            Row(
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.playerPlay),
                  onPressed: () => unawaited(
                    ref.read(playerControllerProvider).playList([track]),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: favorite ? l10n.songUnfavorite : l10n.songFavorite,
                  isSelected: favorite,
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    color: favorite ? colors.primaryText : colors.muted,
                  ),
                  onPressed: () => unawaited(
                    ref
                        .read(favoritesControllerProvider)
                        .set(track.id, favorite: !favorite),
                  ),
                ),
                IconButton(
                  tooltip: l10n.songAddToPlaylist,
                  icon: Icon(Icons.playlist_add, color: colors.muted),
                  onPressed: () =>
                      unawaited(showAddToPlaylistSheet(context, track)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Each section once, in play order; a section sung again shows as a
/// "↻" marker.
class _LyricsTab extends StatelessWidget {
  const _LyricsTab({required this.song, required this.display});

  final Song song;
  final LyricsDisplay display;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final byId = {for (final s in song.sections) s.id: s};
    final order = song.playOrder.isEmpty
        ? [for (final s in song.sections) s.id]
        : song.playOrder;
    final shown = <String>{};
    final lineStyle = textTheme.titleMedium!;
    final trStyle = textTheme.bodyMedium!;
    String name(LyricSection s) =>
        s.kind == SectionKind.chorus ? l10n.lyricsChorus : l10n.lyricsVerse;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        12,
        ZemaSpacing.screenSide,
        32,
      ),
      children: [
        for (final id in order)
          if (byId[id] case final section?)
            if (shown.add(id))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: section.kind == SectionKind.chorus
                      ? const EdgeInsetsDirectional.only(start: 12)
                      : EdgeInsets.zero,
                  decoration: section.kind == SectionKind.chorus
                      ? BoxDecoration(
                          border: BorderDirectional(
                            start: BorderSide(color: colors.line, width: 3),
                          ),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.kind == SectionKind.chorus)
                        Text(
                          l10n.lyricsChorus,
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      for (final line in section.lines) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            line.text,
                            style: lineStyle.copyWith(
                              color: colors.text,
                              fontSize: lineStyle.fontSize! * display.textScale,
                            ),
                          ),
                        ),
                        if (display.showTransliteration &&
                            line.transliteration != null)
                          Text(
                            line.transliteration!,
                            style: trStyle.copyWith(
                              color: colors.muted,
                              fontSize: trStyle.fontSize! * display.textScale,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.lyricsRepeat(name(section)),
                  style: textTheme.labelLarge?.copyWith(color: colors.muted),
                ),
              ),
      ],
    );
  }
}

class _InfoTab extends ConsumerWidget {
  const _InfoTab({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recordings = ref.watch(songRecordingsProvider(song.id)).value;
    final sources = {
      for (final r in recordings ?? const <Recording>[]) r.source,
    };
    String sourceName(RecordingSource source) => switch (source) {
      RecordingSource.bundled => l10n.songSourceBundled,
      RecordingSource.localFile => l10n.songSourceLocal,
      RecordingSource.youtube => 'YouTube',
      RecordingSource.telegram => 'Telegram',
    };
    return ListView(
      children: [
        ListTile(
          title: Text(l10n.songDetailAlbum),
          subtitle: Text(song.album ?? l10n.unknownAlbum),
        ),
        ListTile(
          title: Text(l10n.songDetailArtist),
          subtitle: Text(song.artist ?? l10n.unknownArtist),
        ),
        if (sources.isNotEmpty)
          ListTile(
            title: Text(l10n.songDetailSource),
            subtitle: Text(sources.map(sourceName).join(', ')),
          ),
      ],
    );
  }
}
