import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../library/presentation/widgets/track_art.dart';
import '../../player/application/player_providers.dart';
import '../application/listen_history.dart';

class ListenHistoryScreen extends ConsumerWidget {
  const ListenHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(listenHistoryProvider);
    final hasEntries = entries.value?.isNotEmpty ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listenHistoryTitle),
        actions: [
          if (hasEntries)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: Text(l10n.listenHistoryClear),
            ),
        ],
      ),
      body: switch (entries) {
        AsyncData(value: final list) when list.isEmpty => EmptyState(
          kind: EmptyStateKind.empty,
          icon: Icons.history_rounded,
          title: l10n.listenHistoryEmptyTitle,
          message: l10n.listenHistoryEmptyMessage,
        ),
        AsyncData(value: final list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) => _Row(entry: list[i]),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.listenHistoryClearTitle),
        content: Text(l10n.listenHistoryClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.listenHistoryClear),
          ),
        ],
      ),
    );
    if (clear ?? false) await ref.read(databaseProvider).identifiedDao.clear();
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final material = MaterialLocalizations.of(context);
    final local = entry.at.toLocal();
    final when = l10n.listenHistoryAt(
      local.year == clock.now().year
          ? material.formatMediumDate(local)
          : material.formatShortDate(local),
      material.formatTimeOfDay(TimeOfDay.fromDateTime(local)),
    );
    final track = entry.track;
    return ListTile(
      leading: track == null
          ? Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.soft,
                borderRadius: BorderRadius.circular(ZemaRadius.small),
              ),
              child: Icon(Icons.lyrics_rounded, color: colors.accentText),
            )
          : TrackArt(track: track, size: 48),
      title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [?entry.artist, when].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.muted),
      ),
      trailing: IconButton(
        tooltip: l10n.listenHistoryRemove,
        icon: Icon(Icons.close_rounded, color: colors.muted),
        onPressed: () =>
            ref.read(databaseProvider).identifiedDao.remove(entry.id),
      ),
      onTap: () async {
        if (track == null) {
          context.go(AppRoutes.song(entry.song!.id));
          return;
        }
        await ref.read(playerControllerProvider).playList([track]);
        if (context.mounted) unawaited(context.push(AppRoutes.nowPlaying));
      },
    );
  }
}
