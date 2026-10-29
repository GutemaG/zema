import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/not_found_screen.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/format_duration.dart';
import '../../catalog/application/report_sender.dart';
import '../../library/application/favorites.dart';
import '../../library/presentation/add_to_playlist_sheet.dart';
import '../../player/application/player_providers.dart';
import '../application/lyrics_links.dart';
import '../application/lyrics_prefs.dart';
import '../application/track_lyrics.dart';
import 'lyrics_view.dart';
import 'report_lyrics_sheet.dart';

/// S07: one song's title, transliteration, artist and album, Play,
/// favorite and add to playlist (for its first linked track), tabs with
/// the full lyrics, the song's recordings and its info, and for catalog
/// songs Report wrong lyrics in the menu. Opening it downloads the
/// lyrics if needed. An unknown [songId] shows C07 not found; lyrics that
/// can't be downloaded show C07 with Try again.
class SongDetailScreen extends ConsumerWidget {
  const SongDetailScreen({super.key, required this.songId});

  final String? songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = songId;
    if (id == null) return const NotFoundScreen();
    return switch (ref.watch(songProvider(id))) {
      // Kept on screen while a newer version downloads.
      AsyncValue(value: final song?) => _SongDetail(song: song),
      AsyncData() => const NotFoundScreen(),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(child: LyricsUnavailable(error: error)),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
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
      length: 3,
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
            if (ref.watch(canReportProvider(song.id)))
              PopupMenuButton<void>(
                tooltip: l10n.songDetailMoreOptions,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: () => unawaited(
                      showReportLyricsSheet(context, songId: song.id),
                    ),
                    child: Text(l10n.reportLyrics),
                  ),
                ],
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
                  Tab(text: l10n.songDetailRecordingsTab),
                  Tab(text: l10n.songDetailInfoTab),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _LyricsTab(song: song, display: display),
              _RecordingsTab(song: song),
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

/// The song's recordings: artist, source, duration and whether its lyrics
/// are synced. The one the lyrics view uses ([usedRecording]) is marked.
class _RecordingsTab extends ConsumerWidget {
  const _RecordingsTab({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final info = ref.watch(songRecordingsInfoProvider(song.id));
    final used = usedRecording([
      for (final r in info.value ?? const <RecordingInfo>[]) r.recording,
    ]);
    return switch (info) {
      AsyncData(value: []) => Padding(
        padding: const EdgeInsets.all(ZemaSpacing.screenSide),
        child: Text(
          l10n.songRecordingsEmpty,
          style: textTheme.bodyMedium?.copyWith(color: colors.muted),
        ),
      ),
      AsyncData(value: final recordings) => ListView(
        children: [
          for (final (:recording, :synced) in recordings)
            ListTile(
              title: Text(recording.artist ?? l10n.unknownArtist),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      _sourceName(l10n, recording.source),
                      if (recording.duration case final duration?)
                        formatDuration(duration),
                    ].join(' · '),
                  ),
                  if (recording.id == used?.id)
                    Text(
                      l10n.songRecordingUsed,
                      style: TextStyle(color: colors.accentText),
                    ),
                ],
              ),
              trailing: synced
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.soft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          l10n.songRecordingSynced,
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.accentText,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      l10n.songRecordingTextOnly,
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.muted,
                      ),
                    ),
            ),
        ],
      ),
      AsyncError(:final error) => LyricsUnavailable(error: error),
      _ => const Center(child: CircularProgressIndicator()),
    };
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
            subtitle: Text(sources.map((s) => _sourceName(l10n, s)).join(', ')),
          ),
      ],
    );
  }
}

String _sourceName(AppLocalizations l10n, RecordingSource source) =>
    switch (source) {
      RecordingSource.bundled => l10n.songSourceBundled,
      RecordingSource.localFile => l10n.songSourceLocal,
      RecordingSource.youtube => 'YouTube',
      RecordingSource.telegram => 'Telegram',
    };
