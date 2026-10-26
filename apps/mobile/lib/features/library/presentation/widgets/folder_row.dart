import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/folder_tree.dart';
import '../../application/library_providers.dart';

/// The name to show for the root of [location]'s storage.
String storageName(AppLocalizations l10n, FolderLocation location) =>
    switch (location.kind) {
      StorageKind.phone => l10n.folderPhone,
      StorageKind.sdCard => l10n.folderSdCard,
    };

/// The name to show for the folder at [path] (the storage name for a root).
String folderName(AppLocalizations l10n, String path) {
  final location = locateFolder(path);
  return location.segments.isEmpty
      ? storageName(l10n, location)
      : location.segments.last;
}

/// [path] as the user sees it, e.g. `Phone/Music/Telegram`.
String folderDisplayPath(AppLocalizations l10n, String path) {
  final location = locateFolder(path);
  return [storageName(l10n, location), ...location.segments].join('/');
}

/// Hides [folder] from the whole library and offers Undo.
Future<void> hideFolderWithUndo(
  BuildContext context,
  WidgetRef ref,
  FolderEntry folder,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final repository = ref.read(libraryRepositoryProvider);
  await repository.hideFolder(folder.path);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        // Undo is only offered briefly.
        persist: false,
        content: Text(l10n.folderHidden(folderName(l10n, folder.path))),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () => unawaited(repository.unhideFolder(folder.path)),
        ),
      ),
    );
}

/// A folder in a list: icon, name, song count and (optionally) its path,
/// with a menu holding Hide.
class FolderRow extends ConsumerWidget {
  const FolderRow({
    super.key,
    required this.folder,
    required this.onTap,
    this.showPath = true,
  });

  final FolderEntry folder;
  final VoidCallback onTap;
  final bool showPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final count = l10n.librarySongCount(folder.songCount);
    final name = folderName(l10n, folder.path);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: ZemaSpacing.listRow,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: ZemaSpacing.screenSide,
            end: 4,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.tile,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox.square(
                    dimension: 46,
                    child: Icon(Icons.folder_outlined, color: colors.tileFg),
                  ),
                ),
              ),
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
                      showPath
                          ? '$count · ${folderDisplayPath(l10n, folder.path)}'
                          : count,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<void>(
                tooltip: l10n.folderMenu(name),
                icon: Icon(Icons.more_vert, color: colors.muted),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: () =>
                        unawaited(hideFolderWithUndo(context, ref, folder)),
                    child: Text(l10n.folderHide),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
