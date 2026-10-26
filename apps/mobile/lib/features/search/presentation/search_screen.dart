import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';
import 'package:go_router/go_router.dart';

import '../../lyrics/application/lyrics_links.dart';
import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/tab_page.dart';
import '../../library/application/album_grouping.dart';
import '../../library/presentation/library_access_gate.dart';
import '../../library/presentation/song_menu.dart';
import '../../library/presentation/widgets/album_tile.dart';
import '../../library/presentation/widgets/artist_row.dart';
import '../../library/presentation/widgets/library_search_field.dart';
import '../../library/presentation/widgets/track_art.dart';
import '../../library/presentation/widgets/track_row.dart';
import '../../player/application/player_providers.dart';
import '../application/library_search.dart';
import '../application/recent_searches.dart';
import 'widgets/recent_searches_view.dart';

/// Which results Search shows.
enum SearchScope { all, songs, lyrics, artists, albums }

/// S06: songs, artists and albums on the phone, found while typing with
/// any keyboard (see `normalizeSearchText` and `matchScore`).
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPage(
      title: AppLocalizations.of(context).navSearch,
      child: const LibraryAccessGate(child: _SearchBody()),
    );
  }
}

class _SearchBody extends ConsumerStatefulWidget {
  const _SearchBody();

  @override
  ConsumerState<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends ConsumerState<_SearchBody> {
  /// Results per group under All; "See all" shows the rest.
  static const _preview = 4;

  final _field = TextEditingController();
  var _query = '';
  var _scope = SearchScope.all;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _setQuery(String value) => setState(() => _query = value);

  void _pickRecent(String query) {
    _field.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _setQuery(query);
  }

  void _remember() =>
      unawaited(ref.read(recentSearchesProvider.notifier).add(_query));

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            8,
            ZemaSpacing.screenSide,
            0,
          ),
          child: LibrarySearchField(
            controller: _field,
            onChanged: _setQuery,
            onClear: () {
              _field.clear();
              _setQuery('');
            },
            onSubmitted: (_) => _remember(),
          ),
        ),
        if (searching)
          _ScopeChips(
            scope: _scope,
            onSelected: (scope) => setState(() => _scope = scope),
          ),
        Expanded(
          child: searching
              ? _buildResults(context)
              : RecentSearchesView(onPick: _pickRecent),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = ref.watch(librarySearchIndexProvider);
    if (index == null) return const Center(child: CircularProgressIndicator());
    final results = index.search(_query);
    final lyricMatches =
        _scope == SearchScope.all || _scope == SearchScope.lyrics
        ? ref.watch(lyricsSearchIndexProvider)?.search(_query) ??
              const <LyricMatch>[]
        : const <LyricMatch>[];
    final shown = switch (_scope) {
      SearchScope.all => results,
      SearchScope.lyrics => const SearchResults(
        songs: [],
        artists: [],
        albums: [],
      ),
      SearchScope.songs => SearchResults(
        songs: results.songs,
        artists: const [],
        albums: const [],
      ),
      SearchScope.artists => SearchResults(
        songs: const [],
        artists: results.artists,
        albums: const [],
      ),
      SearchScope.albums => SearchResults(
        songs: const [],
        artists: const [],
        albums: results.albums,
      ),
    };
    if (shown.isEmpty && lyricMatches.isEmpty) {
      return EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.search_off,
        title: l10n.libraryNoResultsTitle,
        message: l10n.libraryNoResultsMessage,
      );
    }

    final all = _scope == SearchScope.all;
    List<T> limit<T>(List<T> items) =>
        all ? items.take(_preview).toList() : items;
    VoidCallback? seeAll(int count, SearchScope scope) =>
        all && count > _preview ? () => setState(() => _scope = scope) : null;
    final currentId = ref.watch(currentTrackProvider.select((t) => t?.id));
    final songs = limit(shown.songs);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (shown.songs.isNotEmpty) ...[
          _GroupHeader(
            title: l10n.searchScopeSongs,
            onSeeAll: seeAll(shown.songs.length, SearchScope.songs),
          ),
          for (final (i, track) in songs.indexed)
            TrackRow(
              key: ValueKey(track.id),
              track: track,
              isCurrent: track.id == currentId,
              onTap: () {
                _remember();
                unawaited(
                  ref
                      .read(playerControllerProvider)
                      .playList(shown.songs, start: i),
                );
              },
              trailing: SongMenuButton(track: track),
            ),
        ],
        if (lyricMatches.isNotEmpty) ...[
          _GroupHeader(
            title: l10n.searchScopeLyrics,
            onSeeAll: seeAll(lyricMatches.length, SearchScope.lyrics),
          ),
          for (final match in limit(lyricMatches))
            _LyricMatchRow(
              match: match,
              query: _query,
              onTap: () {
                _remember();
                context.go(
                  AppRoutes.song(match.song.id, base: AppRoutes.search),
                );
              },
            ),
        ],
        if (shown.artists.isNotEmpty) ...[
          _GroupHeader(
            title: l10n.searchScopeArtists,
            onSeeAll: seeAll(shown.artists.length, SearchScope.artists),
          ),
          for (final artist in limit(shown.artists))
            SizedBox(
              height: ZemaSpacing.listRow,
              child: ArtistRow(artist: artist, onTap: _remember),
            ),
        ],
        if (shown.albums.isNotEmpty) ...[
          _GroupHeader(
            title: l10n.searchScopeAlbums,
            onSeeAll: seeAll(shown.albums.length, SearchScope.albums),
          ),
          for (final album in limit(shown.albums))
            _AlbumRow(album: album, onTap: _remember),
        ],
      ],
    );
  }
}

class _ScopeChips extends StatelessWidget {
  const _ScopeChips({required this.scope, required this.onSelected});

  final SearchScope scope;
  final ValueChanged<SearchScope> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      SearchScope.all: l10n.searchScopeAll,
      SearchScope.songs: l10n.searchScopeSongs,
      SearchScope.lyrics: l10n.searchScopeLyrics,
      SearchScope.artists: l10n.searchScopeArtists,
      SearchScope.albums: l10n.searchScopeAlbums,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        8,
        ZemaSpacing.screenSide,
        0,
      ),
      child: Row(
        children: [
          for (final MapEntry(key: value, value: label) in labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: value == scope,
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final seeAll = onSeeAll;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        12,
        ZemaSpacing.screenSide - 4,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: colors.muted),
              ),
            ),
          ),
          if (seeAll != null)
            TextButton(
              onPressed: seeAll,
              style: TextButton.styleFrom(
                foregroundColor: colors.primaryText,
                minimumSize: const Size(ZemaSpacing.minTap, ZemaSpacing.minTap),
              ),
              child: Text(AppLocalizations.of(context).searchSeeAll),
            ),
        ],
      ),
    );
  }
}

/// An album with its cover, name and artist; opens the album page in the
/// Search tab.
class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.album, required this.onTap});

  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: () {
            onTap();
            unawaited(
              context.push(AppRoutes.album(album.id, base: AppRoutes.search)),
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: ZemaSpacing.listRow),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ZemaSpacing.screenSide,
                vertical: 6,
              ),
              child: Row(
                children: [
                  TrackArt(track: album.cover, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          albumTitle(l10n, album),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.text,
                          ),
                        ),
                        Text(
                          albumArtist(l10n, album),
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
          ),
        ),
      ),
    );
  }
}

/// A song found by a lyric line: its title and the line, with the words
/// that match the query in bold.
class _LyricMatchRow extends StatelessWidget {
  const _LyricMatchRow({
    required this.match,
    required this.query,
    required this.onTap,
  });

  final LyricMatch match;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final queryWords = [
      for (final word in query.split(RegExp(r'\s+')))
        if (SearchKey(word) case final key when !key.isEmpty) key,
    ];
    bool matches(String word) {
      final key = SearchKey(word);
      return !key.isEmpty &&
          queryWords.any((q) => matchScore(q, key) >= matchThreshold);
    }

    final style = textTheme.bodyMedium?.copyWith(color: colors.muted);
    return ListTile(
      leading: Icon(Icons.lyrics_outlined, color: colors.muted),
      title: Text(
        match.song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodyLarge?.copyWith(color: colors.text),
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            for (final (i, word) in match.line.text.split(' ').indexed)
              TextSpan(
                text: i == 0 ? word : ' $word',
                style: matches(word)
                    ? TextStyle(color: colors.text, fontWeight: FontWeight.w700)
                    : null,
              ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
      onTap: onTap,
    );
  }
}
