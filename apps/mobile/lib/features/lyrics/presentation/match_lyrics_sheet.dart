import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../library/presentation/widgets/library_search_field.dart';
import '../application/lyrics_links.dart';

/// Opens the lyrics picker for [track]. Picking a song links it by hand and
/// closes the sheet; returns the song picked, if any.
Future<Song?> showMatchLyricsSheet(BuildContext context, Track track) {
  return showModalBottomSheet<Song>(
    context: context,
    isScrollControlled: true,
    builder: (_) => MatchLyricsSheet(track: track),
  );
}

/// Every lyrics song, searchable, with the one [track] is linked to
/// checked.
class MatchLyricsSheet extends ConsumerStatefulWidget {
  const MatchLyricsSheet({super.key, required this.track});

  /// Share of the screen height the sheet may take.
  static const maxHeightFactor = 0.8;

  final Track track;

  @override
  ConsumerState<MatchLyricsSheet> createState() => _MatchLyricsSheetState();
}

class _MatchLyricsSheetState extends ConsumerState<MatchLyricsSheet> {
  final _field = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _pick(Song song) async {
    await ref.read(lyricsLinksControllerProvider).link(widget.track, song);
    if (mounted) Navigator.of(context).pop(song);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final all = ref.watch(lyricsSongsProvider).value ?? const <Song>[];
    final linkedId = ref.watch(trackSongProvider(widget.track.id)).value?.id;
    final songs = _query.trim().isEmpty ? all : searchSongs(all, _query);
    return Padding(
      // Keeps the field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height *
              MatchLyricsSheet.maxHeightFactor,
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
                    l10n.songMatchLyrics,
                    style: textTheme.titleLarge,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZemaSpacing.screenSide,
                ),
                child: LibrarySearchField(
                  controller: _field,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () {
                    _field.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              Flexible(
                child: songs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.libraryNoResultsTitle,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          for (final song in songs)
                            ListTile(
                              key: ValueKey(song.id),
                              leading: Icon(
                                Icons.lyrics_outlined,
                                color: colors.text,
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  ?song.transliteration,
                                  ?song.artist,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                              trailing: song.id == linkedId
                                  ? Icon(Icons.check, color: colors.primaryText)
                                  : null,
                              selected: song.id == linkedId,
                              onTap: () => unawaited(_pick(song)),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
