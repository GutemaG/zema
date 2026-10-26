import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/album_grouping.dart';
import '../application/library_groups.dart';
import 'widgets/album_tile.dart';

/// S12: a grid of album covers with name and artist, sortable by name,
/// artist or year. Two columns on phones, more on wider screens.
class AlbumsView extends ConsumerWidget {
  const AlbumsView({super.key});

  /// Tiles are at most this wide; the column count follows from it.
  static const maxTileWidth = 220.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(albumsProvider)) {
      AsyncData(:final value) when value.isNotEmpty => Column(
        children: [
          _Header(count: value.length),
          Expanded(child: _Grid(albums: value)),
        ],
      ),
      AsyncData() => EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.album_outlined,
        title: l10n.albumsEmptyTitle,
        message: l10n.albumsEmptyMessage,
      ),
      AsyncError() => EmptyState(
        kind: EmptyStateKind.error,
        title: l10n.libraryScanFailedTitle,
        message: l10n.libraryScanFailedMessage,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.albums});

  final List<Album> albums;

  @override
  Widget build(BuildContext context) {
    final textHeight = AlbumTile.textHeight(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const side = ZemaSpacing.screenSide;
        const gap = AlbumsView._gap;
        final available = constraints.maxWidth - 2 * side;
        final columns = ((available + gap) / (AlbumsView.maxTileWidth + gap))
            .ceil()
            .clamp(2, 8);
        final tileWidth = (available - gap * (columns - 1)) / columns;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(side, 4, side, side),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: 16,
            mainAxisExtent: tileWidth + textHeight,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return AlbumTile(
              album: album,
              width: tileWidth,
              onTap: () => unawaited(context.push(AppRoutes.album(album.id))),
            );
          },
        );
      },
    );
  }
}

/// Count and sort menu.
class _Header extends ConsumerWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final sort = ref.watch(albumSortProvider);
    final fieldNames = {
      AlbumSortField.name: l10n.sortAlbumName,
      AlbumSortField.artist: l10n.sortArtist,
      AlbumSortField.year: l10n.sortYear,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(ZemaSpacing.screenSide, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.albumCount(count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colors.muted),
            ),
          ),
          PopupMenuButton<Object>(
            tooltip: l10n.librarySortTooltip,
            icon: Icon(Icons.sort, color: colors.text),
            onSelected: (choice) =>
                ref.read(albumSortProvider.notifier).set(switch (choice) {
                  AlbumSortField field => AlbumSort(
                    field,
                    descending: sort.descending,
                  ),
                  final bool descending => AlbumSort(
                    sort.field,
                    descending: descending,
                  ),
                  _ => sort,
                }),
            itemBuilder: (context) => [
              for (final MapEntry(key: field, value: name)
                  in fieldNames.entries)
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
          ),
        ],
      ),
    );
  }
}
