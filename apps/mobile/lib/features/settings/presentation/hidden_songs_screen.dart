import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../library/application/library_providers.dart';
import '../../library/presentation/widgets/track_row.dart';

/// Settings → Hidden songs: each hidden song with Unhide, which brings it
/// back to every list.
class HiddenSongsScreen extends ConsumerWidget {
  const HiddenSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final library = ref.read(libraryRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsHiddenSongs)),
      body: switch (ref.watch(hiddenTracksProvider)) {
        AsyncData(value: final tracks) when tracks.isEmpty => EmptyState(
          kind: EmptyStateKind.empty,
          icon: Icons.visibility_off_outlined,
          title: l10n.hiddenSongsEmptyTitle,
          message: l10n.hiddenSongsEmptyMessage,
        ),
        AsyncData(value: final tracks) => ListView.builder(
          itemExtent: TrackRow.height,
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return TrackRow(
              key: ValueKey(track.id),
              track: track,
              onTap: null,
              trailing: TextButton(
                onPressed: () => unawaited(library.unhideTrack(track.id)),
                child: Text(l10n.actionUnhide),
              ),
            );
          },
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
