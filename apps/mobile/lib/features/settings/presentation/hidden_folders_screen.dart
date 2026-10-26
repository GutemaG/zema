import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../library/application/library_providers.dart';
import '../../library/presentation/widgets/folder_row.dart';

/// Settings → Hidden folders: each hidden folder with Unhide, which brings
/// its songs back to every list.
class HiddenFoldersScreen extends ConsumerWidget {
  const HiddenFoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final library = ref.read(libraryRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsHiddenFolders)),
      body: switch (ref.watch(hiddenFoldersProvider)) {
        AsyncData(value: final folders) when folders.isEmpty => EmptyState(
          kind: EmptyStateKind.empty,
          icon: Icons.folder_off_outlined,
          title: l10n.hiddenFoldersEmptyTitle,
          message: l10n.hiddenFoldersEmptyMessage,
        ),
        AsyncData(value: final folders) => ListView.builder(
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final path = folders[index];
            return Padding(
              key: ValueKey(path),
              padding: const EdgeInsetsDirectional.only(
                start: ZemaSpacing.screenSide,
                end: 8,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ZemaSpacing.listRow,
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_off_outlined, color: colors.muted),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            folderName(l10n, path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.text,
                            ),
                          ),
                          Text(
                            folderDisplayPath(l10n, path),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => unawaited(library.unhideFolder(path)),
                      child: Text(l10n.actionUnhide),
                    ),
                  ],
                ),
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
