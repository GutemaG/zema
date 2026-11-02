import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/drafts.dart';

/// The label of a block: its kind, numbered when [sections] has more than
/// one of that kind (verses are always numbered).
String sectionLabel(
  AppLocalizations l10n,
  List<LyricSection> sections,
  LyricSection section,
) {
  final same = sections.where((s) => s.kind == section.kind).toList();
  final n = same.indexOf(section) + 1;
  final numbered = section.kind == SectionKind.verse || same.length > 1;
  return switch (section.kind) {
    SectionKind.verse => l10n.contributeBlockVerse(n),
    SectionKind.chorus =>
      numbered ? l10n.contributeBlockChorusN(n) : l10n.lyricsChorus,
    SectionKind.bridge =>
      numbered ? l10n.contributeBlockBridgeN(n) : l10n.contributeBlockBridge,
    SectionKind.other =>
      numbered ? l10n.contributeBlockOtherN(n) : l10n.contributeBlockOther,
  };
}

String _kindName(AppLocalizations l10n, SectionKind kind) => switch (kind) {
  SectionKind.verse => l10n.lyricsVerse,
  SectionKind.chorus => l10n.lyricsChorus,
  SectionKind.bridge => l10n.contributeBlockBridge,
  SectionKind.other => l10n.contributeBlockOther,
};

/// An unused id for a new block of [kind]: v1, c1, b1, o1, then the next
/// number.
String newSectionId(List<LyricSection> sections, SectionKind kind) {
  final prefix = kind.name[0];
  final ids = {for (final s in sections) s.id};
  var n = 1;
  while (ids.contains('$prefix$n')) {
    n++;
  }
  return '$prefix$n';
}

/// The lines typed in a block, one per row; empty rows at the end are left
/// out. Row i of [transliteration] belongs to line i.
List<LyricLine> linesFromText(String text, String transliteration) {
  final rows = text.split('\n');
  while (rows.isNotEmpty && rows.last.trim().isEmpty) {
    rows.removeLast();
  }
  final latin = transliteration.split('\n');
  return [
    for (var i = 0; i < rows.length; i++)
      LyricLine(
        rows[i].trim(),
        transliteration: i < latin.length && latin[i].trim().isNotEmpty
            ? latin[i].trim()
            : null,
      ),
  ];
}

/// Whether [song]'s play order is each block once, in order (as it starts).
bool _defaultOrder(Song song) =>
    song.playOrder.length == song.sections.length &&
    [
      for (var i = 0; i < song.sections.length; i++)
        song.playOrder[i] == song.sections[i].id,
    ].every((same) => same);

/// S19, step 1: the song's details, its blocks and their play order.
class LyricsStep extends ConsumerStatefulWidget {
  const LyricsStep({super.key, required this.id, required this.draft});

  final int id;
  final ContributionDraft draft;

  @override
  ConsumerState<LyricsStep> createState() => _LyricsStepState();
}

class _LyricsStepState extends ConsumerState<LyricsStep> {
  late final _title = TextEditingController(text: widget.draft.song.title);
  late final _transliteration = TextEditingController(
    text: widget.draft.song.transliteration,
  );
  late final _artist = TextEditingController(text: widget.draft.song.artist);
  late final _album = TextEditingController(text: widget.draft.song.album);

  /// Each block's lines and their transliteration, by block id.
  final _lines = <String, TextEditingController>{};
  final _latin = <String, TextEditingController>{};

  /// Blocks whose transliteration field is open.
  final _showLatin = <String>{};

  /// Changes when pasting replaces the blocks, so their fields start over.
  var _generation = 0;

  Song get _song => widget.draft.song;

  @override
  void dispose() {
    for (final c in [
      _title,
      _transliteration,
      _artist,
      _album,
      ..._lines.values,
      ..._latin.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _linesOf(LyricSection s) => _lines.putIfAbsent(
    s.id,
    () => TextEditingController(text: s.lines.map((l) => l.text).join('\n')),
  );

  TextEditingController _latinOf(LyricSection s) => _latin.putIfAbsent(
    s.id,
    () => TextEditingController(
      text: s.lines.map((l) => l.transliteration ?? '').join('\n'),
    ),
  );

  void _forgetFields() {
    for (final c in [..._lines.values, ..._latin.values]) {
      c.dispose();
    }
    _lines.clear();
    _latin.clear();
    _showLatin.clear();
    _generation++;
  }

  void _edit(Song Function(Song song) change) => ref
      .read(draftEditorProvider(widget.id).notifier)
      .edit((draft) => draft.copyWith(song: change(draft.song)));

  Song _with(
    Song song, {
    List<LyricSection>? sections,
    List<String>? playOrder,
  }) => Song(
    id: song.id,
    title: _title.text,
    transliteration: _transliteration.text,
    artist: _artist.text,
    album: _album.text,
    sections: sections ?? song.sections,
    playOrder: playOrder ?? song.playOrder,
  );

  void _detailsChanged() => _edit(_with);

  /// Replaces the blocks with [sections]; while the play order is still the
  /// default, it follows them.
  void _setSections(Song song, List<LyricSection> sections) {
    final follows = _defaultOrder(song);
    final ids = {for (final s in sections) s.id};
    _edit(
      (song) => _with(
        song,
        sections: sections,
        playOrder: follows
            ? [for (final s in sections) s.id]
            : [
                for (final id in song.playOrder)
                  if (ids.contains(id)) id,
              ],
      ),
    );
  }

  void _linesChanged(LyricSection section) => _edit((song) {
    final sections = [
      for (final s in song.sections)
        s.id == section.id
            ? LyricSection(
                id: s.id,
                kind: s.kind,
                lines: linesFromText(
                  _lines[s.id]?.text ?? '',
                  _latin[s.id]?.text ?? '',
                ),
              )
            : s,
    ];
    return _with(song, sections: sections);
  });

  void _addBlock() {
    // A new block is a verse; its menu changes that.
    final song = _song;
    _setSections(song, [
      ...song.sections,
      LyricSection(
        id: newSectionId(song.sections, SectionKind.verse),
        kind: SectionKind.verse,
        lines: const [],
      ),
    ]);
  }

  void _setKind(LyricSection section, SectionKind kind) => _setSections(_song, [
    for (final s in _song.sections)
      s.id == section.id
          ? LyricSection(id: s.id, kind: kind, lines: s.lines)
          : s,
  ]);

  void _move(LyricSection section, int by) {
    final sections = [..._song.sections];
    final i = sections.indexOf(section);
    final j = i + by;
    if (i < 0 || j < 0 || j >= sections.length) return;
    sections
      ..removeAt(i)
      ..insert(j, section);
    _setSections(_song, sections);
  }

  Future<void> _delete(LyricSection section) async {
    final l10n = AppLocalizations.of(context);
    final song = _song;
    final label = sectionLabel(l10n, song.sections, section);
    final inOrder = song.playOrder.where((id) => id == section.id).length;
    final hasText = section.lines.any((l) => l.text.isNotEmpty);
    if (hasText || (inOrder > 0 && !_defaultOrder(song))) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.contributeBlockDeleteTitle(label)),
          content: Text(l10n.contributeBlockDeleteMessage(inOrder)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.contributeBlockDelete),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    _lines.remove(section.id)?.dispose();
    _latin.remove(section.id)?.dispose();
    _showLatin.remove(section.id);
    _setSections(_song, [
      for (final s in _song.sections)
        if (s.id != section.id) s,
    ]);
  }

  Future<void> _paste() async {
    final l10n = AppLocalizations.of(context);
    final replaces = _song.sections.isNotEmpty;
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _PasteDialog(replaces: replaces),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    final pasted = splitPastedLyrics(text);
    setState(_forgetFields);
    _edit(
      (song) =>
          _with(song, sections: pasted.sections, playOrder: pasted.playOrder),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.contributePasted(pasted.sections.length))),
    );
  }

  void _setOrder(List<String> order) =>
      _edit((song) => _with(song, playOrder: order));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;
    final song = _song;
    final errors = widget.draft.lyricsErrors;
    final titleTyped = _title.text.isNotEmpty;

    Widget field(
      TextEditingController controller,
      String label, {
      String? error,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onChanged: (_) => _detailsChanged(),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          border: const OutlineInputBorder(),
        ),
      ),
    );

    // Shown once there is something to fix; Next stays off until then.
    final orderError = song.sections.isEmpty
        ? null
        : errors.contains(ContributionError.playOrderEmpty)
        ? l10n.contributePlayOrderEmpty
        : null;
    final tooMany = errors.contains(ContributionError.tooManyLines);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              8,
              ZemaSpacing.screenSide,
              16,
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.contributeFieldTooLong,
                    style: textTheme.bodySmall?.copyWith(color: error),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.soft,
                  borderRadius: BorderRadius.circular(ZemaRadius.small),
                ),
                child: Text(l10n.contributeChorusHint),
              ),
              const SizedBox(height: 12),
              for (final section in song.sections)
                _BlockCard(
                  key: ValueKey('$_generation/${section.id}'),
                  label: sectionLabel(l10n, song.sections, section),
                  section: section,
                  lines: _linesOf(section),
                  latin: _latinOf(section),
                  showLatin:
                      _showLatin.contains(section.id) ||
                      section.lines.any((l) => l.transliteration != null),
                  first: section == song.sections.first,
                  last: section == song.sections.last,
                  onLinesChanged: () => _linesChanged(section),
                  onKind: (kind) => _setKind(section, kind),
                  onMove: (by) => _move(section, by),
                  onToggleLatin: () => setState(() {
                    if (!_showLatin.remove(section.id)) {
                      _showLatin.add(section.id);
                    }
                  }),
                  onDelete: () => _delete(section),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addBlock,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.contributeAddBlock),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _paste,
                      icon: const Icon(Icons.content_paste),
                      label: Text(l10n.contributePasteAll),
                    ),
                  ),
                ],
              ),
              if (tooMany)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.contributeTooManyLines(maxWrittenLines),
                    style: textTheme.bodySmall?.copyWith(color: error),
                  ),
                ),
              if (song.sections.isNotEmpty) ...[
                const SizedBox(height: 20),
                _PlayOrder(
                  sections: song.sections,
                  order: song.playOrder,
                  error: orderError,
                  onChanged: _setOrder,
                ),
              ],
              const SizedBox(height: 16),
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            8,
            ZemaSpacing.screenSide,
            12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: errors.isEmpty
                  ? () => ref
                        .read(draftEditorProvider(widget.id).notifier)
                        .edit(
                          (draft) => draft.copyWith(step: DraftStep.recording),
                        )
                  : null,
              child: Text(l10n.contributeNextRecording),
            ),
          ),
        ),
      ],
    );
  }
}

/// One block: its kind, a menu, its lines and (when open) their
/// transliteration.
class _BlockCard extends StatelessWidget {
  const _BlockCard({
    super.key,
    required this.label,
    required this.section,
    required this.lines,
    required this.latin,
    required this.showLatin,
    required this.first,
    required this.last,
    required this.onLinesChanged,
    required this.onKind,
    required this.onMove,
    required this.onToggleLatin,
    required this.onDelete,
  });

  final String label;
  final LyricSection section;
  final TextEditingController lines;
  final TextEditingController latin;
  final bool showLatin;
  final bool first;
  final bool last;
  final VoidCallback onLinesChanged;
  final ValueChanged<SectionKind> onKind;
  final ValueChanged<int> onMove;
  final VoidCallback onToggleLatin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final chorus = section.kind == SectionKind.chorus;
    final typed = lines.text.trim().isNotEmpty;
    final blankLine = section.lines.any((l) => l.text.isEmpty);
    final longLine = section.lines.any(
      (l) =>
          l.text.length > maxLineLength ||
          (l.transliteration?.length ?? 0) > maxLineLength,
    );
    final error = !typed
        ? null
        : blankLine
        ? l10n.contributeBlockBlankLine
        : longLine
        ? l10n.contributeLineTooLong(maxLineLength)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ZemaRadius.medium),
        border: Border.all(color: chorus ? colors.primary : colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PopupMenuButton<SectionKind>(
                    tooltip: l10n.contributeBlockKind,
                    initialValue: section.kind,
                    onSelected: onKind,
                    itemBuilder: (context) => [
                      for (final kind in SectionKind.values)
                        PopupMenuItem(
                          value: kind,
                          child: Text(_kindName(l10n, kind)),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelLarge?.copyWith(
                                color: chorus
                                    ? colors.primaryText
                                    : colors.muted,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: chorus ? colors.primaryText : colors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.contributeBlockMenu,
                icon: const Icon(Icons.more_horiz),
                onSelected: (action) => switch (action) {
                  'up' => onMove(-1),
                  'down' => onMove(1),
                  'latin' => onToggleLatin(),
                  _ => onDelete(),
                },
                itemBuilder: (context) => [
                  if (!first)
                    PopupMenuItem(
                      value: 'up',
                      child: Text(l10n.contributeBlockMoveUp),
                    ),
                  if (!last)
                    PopupMenuItem(
                      value: 'down',
                      child: Text(l10n.contributeBlockMoveDown),
                    ),
                  if (!section.lines.any((l) => l.transliteration != null))
                    PopupMenuItem(
                      value: 'latin',
                      child: Text(
                        showLatin
                            ? l10n.contributeBlockHideLatin
                            : l10n.contributeBlockShowLatin,
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.contributeBlockDelete),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TextField(
              controller: lines,
              onChanged: (_) => onLinesChanged(),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 2,
              decoration: InputDecoration(
                hintText: l10n.contributeBlockHint,
                errorText: error,
                errorMaxLines: 3,
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          if (showLatin)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8, top: 8),
              child: TextField(
                controller: latin,
                onChanged: (_) => onLinesChanged(),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.contributeBlockLatin,
                  helperText: l10n.contributeBlockLatinHelp,
                  helperMaxLines: 2,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The order the blocks are sung in: tap an entry to move or remove it.
class _PlayOrder extends StatelessWidget {
  const _PlayOrder({
    required this.sections,
    required this.order,
    required this.error,
    required this.onChanged,
  });

  final List<LyricSection> sections;
  final List<String> order;
  final String? error;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final byId = {for (final s in sections) s.id: s};

    void moveOrRemove(int i, String action) {
      final next = [...order];
      final id = next.removeAt(i);
      switch (action) {
        case 'left':
          next.insert(i - 1, id);
        case 'right':
          next.insert(i + 1, id);
      }
      onChanged(next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.contributePlayOrder.toUpperCase(),
          style: textTheme.labelLarge?.copyWith(
            color: colors.muted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.contributePlayOrderHelp,
          style: textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < order.length; i++)
              if (byId[order[i]] case final section?)
                PopupMenuButton<String>(
                  tooltip: l10n.contributePlayOrderEntry(i + 1),
                  onSelected: (action) => moveOrRemove(i, action),
                  itemBuilder: (context) => [
                    if (i > 0)
                      PopupMenuItem(
                        value: 'left',
                        child: Text(l10n.contributePlayOrderEarlier),
                      ),
                    if (i < order.length - 1)
                      PopupMenuItem(
                        value: 'right',
                        child: Text(l10n.contributePlayOrderLater),
                      ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(l10n.contributePlayOrderRemove),
                    ),
                  ],
                  child: _Pill(
                    label: sectionLabel(l10n, sections, section),
                    chorus: section.kind == SectionKind.chorus,
                  ),
                ),
            PopupMenuButton<String>(
              tooltip: l10n.contributePlayOrderAdd,
              onSelected: (id) => onChanged([...order, id]),
              itemBuilder: (context) => [
                for (final s in sections)
                  PopupMenuItem(
                    value: s.id,
                    child: Text(sectionLabel(l10n, sections, s)),
                  ),
              ],
              child: _Pill(label: l10n.contributePlayOrderAdd, add: true),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.chorus = false, this.add = false});

  final String label;
  final bool chorus;
  final bool add;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Container(
      constraints: const BoxConstraints(minHeight: ZemaSpacing.minTap),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: add ? null : (chorus ? colors.soft : colors.tile),
        borderRadius: BorderRadius.circular(ZemaRadius.pill),
        border: add ? Border.all(color: colors.primary) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (add) Icon(Icons.add, size: 18, color: colors.primaryText),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: chorus || add ? colors.primaryText : colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasteDialog extends StatefulWidget {
  const _PasteDialog({required this.replaces});

  /// Whether there are blocks the paste replaces.
  final bool replaces;

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.contributePasteAll),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.replaces
                  ? '${l10n.contributePasteHelp} ${l10n.contributePasteReplaces}'
                  : l10n.contributePasteHelp,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              autofocus: true,
              keyboardType: TextInputType.multiline,
              maxLines: 8,
              minLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _text.text),
          child: Text(l10n.contributePasteSplit),
        ),
      ],
    );
  }
}
