import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../library/presentation/widgets/track_row.dart';
import '../application/player_providers.dart';
import '../data/player_snapshot.dart';

/// Opens C02, the queue sheet.
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const QueueSheet(),
  );
}

/// C02: the whole queue in play order (the shuffled order when shuffle is
/// on). Earlier songs are dimmed and the current one is highlighted; the
/// list opens scrolled to it. Drag to reorder, swipe to remove (with undo),
/// tap to play, or clear everything after the current song.
class QueueSheet extends ConsumerStatefulWidget {
  const QueueSheet({super.key});

  /// Share of the screen height the sheet takes.
  static const heightFactor = 0.8;

  @override
  ConsumerState<QueueSheet> createState() => _QueueSheetState();
}

typedef _Entry = ({int key, Track track});

class _QueueSheetState extends ConsumerState<QueueSheet> {
  late final ScrollController _scroll;

  /// The sheet's own messenger, so the undo snackbar shows above the sheet
  /// rather than on the page behind it.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  /// The order shown right after a drag or swipe, until the player publishes
  /// the change. A dismissed row must leave the tree at once, and a dropped
  /// row shouldn't jump back for a frame.
  List<_Entry>? _pending;
  int? _pendingIndex;
  PlayerSnapshot? _pendingFor;

  @override
  void initState() {
    super.initState();
    final index = ref.read(playerStateProvider).value?.index ?? 0;
    _scroll = ScrollController(
      initialScrollOffset: index < 0 ? 0 : index * TrackRow.height,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _showPending(PlayerSnapshot snapshot, List<_Entry> entries, int index) {
    setState(() {
      _pending = entries;
      _pendingIndex = index;
      _pendingFor = snapshot;
    });
  }

  void _move(PlayerSnapshot snapshot, List<_Entry> entries, int from, int to) {
    final current = entries[snapshot.index];
    final moved = [...entries];
    moved.insert(to, moved.removeAt(from));
    _showPending(snapshot, moved, moved.indexOf(current));
    unawaited(ref.read(playerControllerProvider).moveInQueue(from, to));
  }

  Future<void> _remove(
    PlayerSnapshot snapshot,
    List<_Entry> entries,
    int index,
  ) async {
    final l10n = AppLocalizations.of(context);
    final removed = entries[index];
    _showPending(
      snapshot,
      [...entries]..removeAt(index),
      index < snapshot.index ? snapshot.index - 1 : snapshot.index,
    );
    final undo = await ref
        .read(playerControllerProvider)
        .removeFromQueue(index);
    final messenger = _messenger.currentState;
    if (undo == null || messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Undo is only offered briefly.
          persist: false,
          content: Text(l10n.queueRemoved(removed.track.title)),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => unawaited(undo()),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final snapshot =
        ref.watch(playerStateProvider).value ?? PlayerSnapshot.empty;
    final upToDate = !identical(snapshot, _pendingFor);
    final entries = upToDate || _pending == null
        ? [
            for (var i = 0; i < snapshot.queue.length; i++)
              (key: snapshot.queueKeys[i], track: snapshot.queue[i]),
          ]
        : _pending!;
    final currentIndex = upToDate ? snapshot.index : _pendingIndex!;
    final upcoming = entries.length - currentIndex - 1;
    final player = ref.read(playerControllerProvider);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * QueueSheet.heightFactor,
      child: ScaffoldMessenger(
        key: _messenger,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ZemaSpacing.screenSide + 8,
                  0,
                  8,
                  4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.queueTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            l10n.queueUpNext(upcoming < 0 ? 0 : upcoming),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: upcoming > 0
                          ? () => unawaited(player.clearUpcoming())
                          : null,
                      child: Text(l10n.queueClear),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.line),
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: _scroll,
                  itemExtent: TrackRow.height,
                  buildDefaultDragHandles: false,
                  itemCount: entries.length,
                  onReorderItem: (from, to) =>
                      _move(snapshot, entries, from, to),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isCurrent = index == currentIndex;
                    return _QueueRow(
                      key: ValueKey(entry.key),
                      track: entry.track,
                      index: index,
                      isCurrent: isCurrent,
                      isPlayed: index < currentIndex,
                      onTap: () => unawaited(player.playQueueItem(index)),
                      onRemove: isCurrent
                          ? null
                          : () => unawaited(_remove(snapshot, entries, index)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One queue entry: swipe it away to remove it (not the current one), or
/// drag the handle to move it.
class _QueueRow extends StatelessWidget {
  const _QueueRow({
    super.key,
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.isPlayed,
    required this.onTap,
    required this.onRemove,
  });

  final Track track;
  final int index;
  final bool isCurrent;
  final bool isPlayed;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final row = TrackRow(
      track: track,
      isCurrent: isCurrent,
      onTap: onTap,
      trailing: ReorderableDragStartListener(
        index: index,
        child: Tooltip(
          message: l10n.queueReorder,
          child: SizedBox.square(
            dimension: ZemaSpacing.minTap,
            child: Icon(Icons.drag_handle, color: colors.muted),
          ),
        ),
      ),
    );
    return Semantics(
      customSemanticsActions: onRemove == null
          ? null
          : {CustomSemanticsAction(label: l10n.queueRemove): onRemove!},
      child: Dismissible(
        key: ValueKey('dismiss-$key'),
        direction: onRemove == null
            ? DismissDirection.none
            : DismissDirection.endToStart,
        onDismissed: (_) => onRemove?.call(),
        background: ColoredBox(
          color: colors.soft,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 24),
              child: Icon(Icons.delete_outline, color: colors.text),
            ),
          ),
        ),
        child: Opacity(opacity: isPlayed ? 0.55 : 1, child: row),
      ),
    );
  }
}
