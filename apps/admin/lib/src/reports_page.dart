import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import 'app.dart';
import 'catalog_page.dart';
import 'choice.dart';
import 'format.dart';
import 'session.dart';
import 'strings.dart';

/// Which reports are listed; null for all.
final reportStatusProvider =
    NotifierProvider<Choice<ReportStatus?>, ReportStatus?>(
      () => Choice(ReportStatus.open),
    );

final reportsProvider = FutureProvider.autoDispose<List<ModeratorReport>>(
  (ref) => ref
      .watch(moderationRepositoryProvider)
      .reports(ref.watch(reportStatusProvider)),
);

String reasonLabel(ReportReason reason) => switch (reason) {
  ReportReason.wrongWords => Strings.wrongWords,
  ReportReason.wrongTiming => Strings.wrongTiming,
  ReportReason.wrongSong => Strings.wrongSong,
  ReportReason.other => Strings.otherReason,
};

String _statusLabel(ReportStatus? status) => switch (status) {
  null => Strings.all,
  ReportStatus.open => Strings.open,
  ReportStatus.resolved => Strings.resolved,
  ReportStatus.dismissed => Strings.dismissed,
};

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  Future<void> _close(
    BuildContext context,
    WidgetRef ref,
    ModeratorReport report,
    ReportStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(moderationRepositoryProvider)
          .resolveReport(report.id, status);
    } on ZemaFailure catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e is NetworkFailure ? Strings.offline : e.message),
        ),
      );
    }
    ref.invalidate(reportsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(reportStatusProvider);
    final muted = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in [...ReportStatus.values, null])
                ChoiceChip(
                  label: Text(_statusLabel(s)),
                  selected: status == s,
                  onSelected: (_) =>
                      ref.read(reportStatusProvider.notifier).pick(s),
                ),
              IconButton(
                tooltip: Strings.reload,
                onPressed: () => ref.invalidate(reportsProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (ref.watch(reportsProvider)) {
            AsyncData(value: final reports) when reports.isEmpty =>
              const Center(child: Text(Strings.reportsEmpty)),
            AsyncData(value: final reports) => ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final report in reports)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.songTitle ?? Strings.songRemoved,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            [
                              reasonLabel(report.reason),
                              formatAge(report.createdAt),
                              if (report.status != ReportStatus.open)
                                _statusLabel(report.status),
                            ].join(' · '),
                            style: muted,
                          ),
                          if (report.note case final note?)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SelectableText(note),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (report.songId case final songId?)
                                TextButton(
                                  onPressed: () => showSong(ref, songId),
                                  child: const Text(Strings.openSong),
                                ),
                              if (report.status != ReportStatus.dismissed)
                                OutlinedButton(
                                  onPressed: () => _close(
                                    context,
                                    ref,
                                    report,
                                    ReportStatus.dismissed,
                                  ),
                                  child: const Text(Strings.dismiss),
                                ),
                              if (report.status != ReportStatus.resolved)
                                FilledButton(
                                  onPressed: () => _close(
                                    context,
                                    ref,
                                    report,
                                    ReportStatus.resolved,
                                  ),
                                  child: const Text(Strings.resolve),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            AsyncError(:final error) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error is NetworkFailure ? Strings.offline : '$error'),
                  TextButton(
                    onPressed: () => ref.invalidate(reportsProvider),
                    child: const Text(Strings.retry),
                  ),
                ],
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

/// Opens the catalog page on song [songId].
void showSong(WidgetRef ref, String songId) {
  ref.read(catalogQueryProvider.notifier).pick(songId);
  ref.read(selectedSongProvider.notifier).pick(songId);
  ref.read(adminPageProvider.notifier).show(AdminPage.catalog);
}
