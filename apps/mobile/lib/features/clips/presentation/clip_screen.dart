import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/clip_colors.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/format_duration.dart';
import '../application/clip_controller.dart';
import '../application/clip_look.dart';

/// Share clip: pick the part of the song (handles snap to lines, Play to
/// hear it with the preview following) and its look, then Make video,
/// Share and Save.
class ClipScreen extends ConsumerWidget {
  const ClipScreen({super.key, required this.trackId});

  final int? trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = trackId;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clipTitle)),
      body: id == null
          ? const SizedBox.shrink()
          : DefaultTabController(length: 2, child: _Body(trackId: id)),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.trackId});

  final int trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final clip = ref.watch(clipControllerProvider(trackId));
    final controller = ref.read(clipControllerProvider(trackId).notifier);
    final messenger = ScaffoldMessenger.of(context);
    final preview = clip.preview;

    void notify(String message) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    final making = clip.phase == ClipPhase.making;
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ZemaSpacing.screenSide,
                8,
                ZemaSpacing.screenSide,
                8,
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: preview == null
                        ? ColoredBox(
                            color: colors.surface,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Semantics(
                                image: true,
                                label: l10n.clipPreview,
                                child: Image.memory(
                                  preview,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              ),
                              if (!making)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: IconButton.filled(
                                      tooltip: clip.playing
                                          ? l10n.clipStop
                                          : l10n.clipPlay,
                                      icon: Icon(
                                        clip.playing
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                      ),
                                      onPressed: () =>
                                          unawaited(controller.togglePlay()),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: l10n.clipTabClip),
              Tab(text: l10n.clipTabLook),
            ],
          ),
          SizedBox(
            height: 220,
            child: TabBarView(
              children: [
                _RangeTab(trackId: trackId),
                _LookTab(trackId: trackId),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ZemaSpacing.screenSide,
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                if (making) ...[
                  LinearProgressIndicator(value: clip.progress),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.clipMaking((clip.progress * 100).floor()),
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => unawaited(controller.cancel()),
                        child: Text(l10n.actionCancel),
                      ),
                    ],
                  ),
                ] else if (clip.phase == ClipPhase.done) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.download_outlined),
                          label: Text(l10n.clipSave),
                          onPressed: () async {
                            final saved = await controller.save();
                            notify(
                              saved ? l10n.clipSaved : l10n.clipSaveFailed,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.share_outlined),
                          label: Text(l10n.clipShare),
                          onPressed: () async {
                            if (!await controller.share()) {
                              notify(l10n.clipShareFailed);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  if (clip.phase == ClipPhase.failed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.clipFailed,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.accentText,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.movie_outlined),
                      label: Text(l10n.clipMake),
                      onPressed: preview == null
                          ? null
                          : () => unawaited(controller.make()),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  l10n.clipCopyright,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colors.faint),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeTab extends ConsumerWidget {
  const _RangeTab({required this.trackId});

  final int trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final clip = ref.watch(clipControllerProvider(trackId));
    final controller = ref.read(clipControllerProvider(trackId).notifier);
    final track = clip.track;
    if (track == null) return const SizedBox.shrink();
    final making = clip.phase == ClipPhase.making;
    return ListView(
      key: const PageStorageKey('clip-range'),
      padding: const EdgeInsets.symmetric(
        horizontal: ZemaSpacing.screenSide,
        vertical: 8,
      ),
      children: [
        Row(
          children: [
            _Step(
              icon: Icons.chevron_left,
              tooltip: l10n.clipStartEarlier,
              onPressed: making
                  ? null
                  : () => controller.step(start: true, forward: false),
            ),
            _Step(
              icon: Icons.chevron_right,
              tooltip: l10n.clipStartLater,
              onPressed: making
                  ? null
                  : () => controller.step(start: true, forward: true),
            ),
            Expanded(
              child: Text(
                l10n.clipRange(
                  formatDuration(clip.start),
                  formatDuration(clip.end),
                  clip.length.inSeconds,
                ),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
            ),
            _Step(
              icon: Icons.chevron_left,
              tooltip: l10n.clipEndEarlier,
              onPressed: making
                  ? null
                  : () => controller.step(start: false, forward: false),
            ),
            _Step(
              icon: Icons.chevron_right,
              tooltip: l10n.clipEndLater,
              onPressed: making
                  ? null
                  : () => controller.step(start: false, forward: true),
            ),
          ],
        ),
        if (track.duration > Duration.zero)
          RangeSlider(
            max: track.duration.inMilliseconds.toDouble(),
            values: RangeValues(
              clip.start.inMilliseconds.toDouble(),
              clip.end.inMilliseconds
                  .clamp(0, track.duration.inMilliseconds)
                  .toDouble(),
            ),
            semanticFormatterCallback: (v) =>
                formatDuration(Duration(milliseconds: v.round())),
            onChanged: making
                ? null
                : (v) => controller.setRange(
                    Duration(milliseconds: v.start.round()),
                    Duration(milliseconds: v.end.round()),
                  ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
}

class _LookTab extends ConsumerWidget {
  const _LookTab({required this.trackId});

  final int trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final clip = ref.watch(clipControllerProvider(trackId));
    final controller = ref.read(clipControllerProvider(trackId).notifier);
    final track = clip.track;
    if (track == null) return const SizedBox.shrink();
    final look = clip.look;
    final enabled = clip.phase != ClipPhase.making;

    void set(ClipLook next) {
      if (enabled) unawaited(controller.setLook(next));
    }

    Future<String?> pick() => controller.pickPicture();

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(text, style: textTheme.titleSmall),
    );

    Future<void> edit(
      String label,
      String current,
      ClipLook Function(String?) apply,
    ) async {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => _EditName(label: label, initial: current),
      );
      if (value != null) set(apply(value.trim().isEmpty ? null : value));
    }

    Widget detail({
      required String label,
      required String? value,
      required bool on,
      required ValueChanged<bool> toggle,
      required ClipLook Function(String?) apply,
    }) => Row(
      children: [
        Expanded(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: value == null || value.isEmpty
                ? null
                : Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
            value: on,
            onChanged: enabled ? toggle : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: l10n.clipEditName(label),
          onPressed: enabled
              ? () => unawaited(edit(label, value ?? '', apply))
              : null,
        ),
      ],
    );

    return ListView(
      key: const PageStorageKey('clip-look'),
      padding: const EdgeInsets.symmetric(horizontal: ZemaSpacing.screenSide),
      children: [
        heading(l10n.clipBackground),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (kind, label) in [
              (ClipBackground.song, l10n.clipBackgroundSong),
              (ClipBackground.cover, l10n.clipBackgroundCover),
              (ClipBackground.photo, l10n.clipBackgroundPhoto),
              (ClipBackground.color, l10n.clipBackgroundColor),
            ])
              ChoiceChip(
                label: Text(label),
                selected: look.background == kind,
                onSelected: !enabled
                    ? null
                    : (_) async {
                        if (kind != ClipBackground.photo) {
                          set(look.copyWith(background: kind));
                          return;
                        }
                        final photo = await pick();
                        if (photo != null) {
                          set(
                            look.copyWith(
                              background: ClipBackground.photo,
                              photo: photo,
                            ),
                          );
                        }
                      },
              ),
          ],
        ),
        if (look.background == ClipBackground.color)
          _Swatches(
            colors: clipPlainColors,
            selected: look.color,
            label: l10n.clipColorNumber,
            onSelected: (i) => set(look.copyWith(color: i)),
          ),
        heading(l10n.clipDim),
        Slider(
          max: ClipLook.maxDim,
          divisions: 16,
          value: look.effectiveDim,
          label: l10n.clipDimPercent((look.effectiveDim * 100).round()),
          semanticFormatterCallback: (v) =>
              l10n.clipDimPercent((v * 100).round()),
          onChanged: enabled ? (v) => set(look.copyWith(dim: v)) : null,
        ),
        heading(l10n.clipText),
        SegmentedButton<ClipTextSize>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ClipTextSize.small,
              label: Text(l10n.clipTextSmall),
            ),
            ButtonSegment(
              value: ClipTextSize.medium,
              label: Text(l10n.clipTextMedium),
            ),
            ButtonSegment(
              value: ClipTextSize.large,
              label: Text(l10n.clipTextLarge),
            ),
          ],
          selected: {look.textSize},
          onSelectionChanged: enabled
              ? (v) => set(look.copyWith(textSize: v.single))
              : null,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ClipTextPosition>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ClipTextPosition.top,
              label: Text(l10n.clipTextTop),
            ),
            ButtonSegment(
              value: ClipTextPosition.center,
              label: Text(l10n.clipTextCenter),
            ),
            ButtonSegment(
              value: ClipTextPosition.bottom,
              label: Text(l10n.clipTextBottom),
            ),
          ],
          selected: {look.position},
          onSelectionChanged: enabled
              ? (v) => set(look.copyWith(position: v.single))
              : null,
        ),
        _Swatches(
          colors: clipTextColors,
          selected: look.textColor,
          label: l10n.clipTextColorNumber,
          onSelected: (i) => set(look.copyWith(textColor: i)),
        ),
        if (controller.hasTransliteration)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.clipTransliteration),
            value: look.transliteration,
            onChanged: enabled
                ? (v) => set(look.copyWith(transliteration: v))
                : null,
          ),
        heading(l10n.clipDetails),
        detail(
          label: l10n.clipDetailTitle,
          value: look.title ?? track.title,
          on: look.showTitle,
          toggle: (v) => set(look.copyWith(showTitle: v)),
          apply: (v) => look.copyWith(title: v),
        ),
        detail(
          label: l10n.clipDetailArtist,
          value: look.artist ?? track.artist,
          on: look.showArtist,
          toggle: (v) => set(look.copyWith(showArtist: v)),
          apply: (v) => look.copyWith(artist: v),
        ),
        detail(
          label: l10n.clipDetailAlbum,
          value: look.album ?? track.album,
          on: look.showAlbum,
          toggle: (v) => set(look.copyWith(showAlbum: v)),
          apply: (v) => look.copyWith(album: v, showAlbum: true),
        ),
        heading(l10n.clipPictures),
        _PictureRow(
          label: l10n.clipAlbumPicture,
          value: look.albumPicture == null
              ? l10n.clipPictureCover
              : l10n.clipPicturePhoto,
          onChoose: enabled
              ? () async {
                  final path = await pick();
                  if (path != null) set(look.copyWith(albumPicture: path));
                }
              : null,
          onClear: enabled && look.albumPicture != null
              ? () => set(look.copyWith(albumPicture: null))
              : null,
        ),
        _PictureRow(
          label: l10n.clipArtistPicture,
          value: look.artistPicture == null
              ? l10n.clipPictureNone
              : l10n.clipPicturePhoto,
          onChoose: enabled
              ? () async {
                  final path = await pick();
                  if (path != null) set(look.copyWith(artistPicture: path));
                }
              : null,
          onClear: enabled && look.artistPicture != null
              ? () => set(look.copyWith(artistPicture: null))
              : null,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.clipMark),
          value: look.mark,
          onChanged: enabled ? (v) => set(look.copyWith(mark: v)) : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({
    required this.colors,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<Color> colors;
  final int selected;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final zema = context.zemaColors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        children: [
          for (final (i, color) in colors.indexed)
            Semantics(
              button: true,
              selected: i == selected,
              label: label(i + 1),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onSelected(i),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == selected ? zema.primary : zema.line,
                        width: i == selected ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PictureRow extends StatelessWidget {
  const _PictureRow({
    required this.label,
    required this.value,
    required this.onChoose,
    required this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback? onChoose;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: l10n.clipPictureChoose,
            onPressed: onChoose,
          ),
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.clipPictureClear,
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}

class _EditName extends StatefulWidget {
  const _EditName({required this.label, required this.initial});

  final String label;
  final String initial;

  @override
  State<_EditName> createState() => _EditNameState();
}

class _EditNameState extends State<_EditName> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.label),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: 120,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _text.text),
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
