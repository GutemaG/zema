import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/artist_grouping.dart';
import '../application/library_groups.dart';
import 'widgets/track_art.dart';

/// The name to show for [artist].
String artistName(AppLocalizations l10n, Artist artist) =>
    artist.name ?? l10n.unknownArtist;

/// S13: every artist with a round avatar (one of their album covers, or
/// their initial) and a song count.
class ArtistsView extends ConsumerWidget {
  const ArtistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(artistsProvider)) {
      AsyncData(:final value) when value.isNotEmpty => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              12,
              ZemaSpacing.screenSide,
              4,
            ),
            child: Text(
              l10n.artistCount(value.length),
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: context.zemaColors.muted),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemExtent: ZemaSpacing.listRow,
              itemCount: value.length,
              itemBuilder: (context, index) => _ArtistRow(artist: value[index]),
            ),
          ),
        ],
      ),
      AsyncData() => EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.person_outline,
        title: l10n.artistsEmptyTitle,
        message: l10n.artistsEmptyMessage,
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

class _ArtistRow extends StatelessWidget {
  const _ArtistRow({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final name = artistName(l10n, artist);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => unawaited(context.push(AppRoutes.artist(artist.name))),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ZemaSpacing.screenSide,
          ),
          child: Row(
            children: [
              TrackArt(track: artist.cover, size: 46, radius: 23, label: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(color: colors.text),
                    ),
                    Text(
                      l10n.librarySongCount(artist.tracks.length),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
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
