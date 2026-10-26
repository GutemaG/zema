import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/library_groups.dart';
import 'widgets/folder_row.dart';

/// S11: every folder that directly holds visible songs, with its song count
/// and path. Tapping one opens S11a; its menu hides it.
class FoldersView extends ConsumerWidget {
  const FoldersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(folderIndexProvider)) {
      AsyncData(:final value) when value.folders.isNotEmpty => ListView.builder(
        itemExtent: ZemaSpacing.listRow,
        itemCount: value.folders.length,
        itemBuilder: (context, index) {
          final folder = value.folders[index];
          return FolderRow(
            key: ValueKey(folder.path),
            folder: folder,
            onTap: () => unawaited(context.push(AppRoutes.folder(folder.path))),
          );
        },
      ),
      AsyncData() => EmptyState(
        kind: EmptyStateKind.empty,
        icon: Icons.folder_off_outlined,
        title: l10n.foldersEmptyTitle,
        message: l10n.foldersEmptyMessage,
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
