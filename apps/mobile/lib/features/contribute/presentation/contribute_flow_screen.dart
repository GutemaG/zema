import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/drafts.dart';

/// The four-step flow (S19–S22) for draft [id], opened at its step. Every
/// change is saved on the phone as it is made.
class ContributeFlowScreen extends ConsumerWidget {
  const ContributeFlowScreen({super.key, required this.id});

  /// Null when the route had no valid id.
  final int? id;

  static void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.contribute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = this.id;
    final draft = id == null
        ? const AsyncData<ContributionDraft?>(null)
        : ref.watch(draftEditorProvider(id));
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(onPressed: () => _close(context)),
        title: Text(l10n.contributeAddLyrics),
      ),
      body: SafeArea(
        top: false,
        child: switch (draft) {
          // Only step 1 exists so far; drafts open there.
          AsyncData(value: final draft?) => _LyricsStep(id: id!, draft: draft),
          AsyncData() || AsyncError() => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.contributeDraftGone,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// S19, step 1: the song's details. The block editor and play order come
/// below them.
class _LyricsStep extends ConsumerStatefulWidget {
  const _LyricsStep({required this.id, required this.draft});

  final int id;
  final ContributionDraft draft;

  @override
  ConsumerState<_LyricsStep> createState() => _LyricsStepState();
}

class _LyricsStepState extends ConsumerState<_LyricsStep> {
  late final _title = TextEditingController(text: widget.draft.song.title);
  late final _transliteration = TextEditingController(
    text: widget.draft.song.transliteration,
  );
  late final _artist = TextEditingController(text: widget.draft.song.artist);
  late final _album = TextEditingController(text: widget.draft.song.album);

  @override
  void dispose() {
    for (final c in [_title, _transliteration, _artist, _album]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() {
    ref
        .read(draftEditorProvider(widget.id).notifier)
        .edit(
          (draft) => draft.copyWith(
            song: Song(
              id: draft.song.id,
              title: _title.text,
              transliteration: _transliteration.text,
              artist: _artist.text,
              album: _album.text,
              sections: draft.song.sections,
              playOrder: draft.song.playOrder,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final errors = widget.draft.lyricsErrors;
    final titleTyped = _title.text.isNotEmpty;

    Widget field(
      TextEditingController controller,
      String label, {
      String? error,
      TextCapitalization capitalization = TextCapitalization.words,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onChanged: (_) => _changed(),
        textCapitalization: capitalization,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          border: const OutlineInputBorder(),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        8,
        ZemaSpacing.screenSide,
        24,
      ),
      children: [
        field(
          _title,
          l10n.contributeFieldTitle,
          error: !titleTyped
              ? null
              : errors.contains(ContributionError.titleRequired)
              ? l10n.contributeTitleRequired
              : errors.contains(ContributionError.titleTooLong)
              ? l10n.contributeTitleTooLong
              : null,
        ),
        field(_transliteration, l10n.contributeFieldTransliteration),
        field(_artist, l10n.contributeFieldArtist),
        field(_album, l10n.contributeFieldAlbum),
        if (errors.contains(ContributionError.fieldTooLong))
          Text(
            l10n.contributeFieldTooLong,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.save_outlined, size: 16, color: colors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.contributeSavedOnPhone,
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
