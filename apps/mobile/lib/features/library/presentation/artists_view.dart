import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/artist_grouping.dart';
import '../application/library_groups.dart';
import 'widgets/artist_row.dart';

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
              itemBuilder: (context, index) => ArtistRow(artist: value[index]),
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
