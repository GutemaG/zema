import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../application/recent_searches.dart';

/// What Search shows before anything is typed: the recent searches, or a
/// hint when there are none.
class RecentSearchesView extends ConsumerWidget {
  const RecentSearchesView({super.key, required this.onPick});

  /// Searches again for a recent query.
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final recent = ref.watch(recentSearchesProvider);
    final searches = ref.read(recentSearchesProvider.notifier);
    if (recent.isEmpty) {
      return EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.search,
        title: l10n.searchHintTitle,
        message: l10n.searchHintMessage,
      );
    }
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Padding(
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
                    l10n.searchRecentHeading,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: colors.muted),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(searches.clear()),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primaryText,
                  minimumSize: const Size(
                    ZemaSpacing.minTap,
                    ZemaSpacing.minTap,
                  ),
                ),
                child: Text(l10n.searchClearRecent),
              ),
            ],
          ),
        ),
        for (final query in recent)
          InkWell(
            key: ValueKey(query),
            onTap: () => onPick(query),
            child: Padding(
              padding: const EdgeInsets.only(left: ZemaSpacing.screenSide),
              child: Row(
                children: [
                  Icon(Icons.history, color: colors.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: colors.text),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.searchRemoveRecent(query),
                    constraints: const BoxConstraints(
                      minWidth: ZemaSpacing.minTap,
                      minHeight: ZemaSpacing.minTap,
                    ),
                    icon: Icon(Icons.close, color: colors.muted),
                    onPressed: () => unawaited(searches.remove(query)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
