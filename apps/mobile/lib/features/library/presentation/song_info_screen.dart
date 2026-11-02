import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../app/database/zema_database.dart';
import '../application/song_info.dart';
import '../data/cover_store.dart';
import 'widgets/track_art.dart';

/// S09: a local song's title, artist, album, track number and cover, kept
/// in Zema over the file's own tags (the file is never written). Reset to
/// file's info forgets them.
class SongInfoScreen extends ConsumerWidget {
  const SongInfoScreen({super.key, required this.trackId});

  final int? trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = trackId;
    final info = id == null ? null : ref.watch(songInfoProvider(id));
    final l10n = AppLocalizations.of(context);
    return switch (info?.value) {
      final value? => _Form(file: value.file, edit: value.edit),
      _ => Scaffold(
        appBar: AppBar(title: Text(l10n.songInfoTitle)),
        body: info == null || info.hasValue
            ? const SizedBox.shrink()
            : const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.file, this.edit});

  /// The track with its file's own tags.
  final Track file;
  final TrackOverrideRow? edit;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final _title = TextEditingController(
    text: widget.edit?.title ?? widget.file.title,
  );
  late final _artist = TextEditingController(
    text: widget.edit?.artist ?? widget.file.artist ?? '',
  );
  late final _album = TextEditingController(
    text: widget.edit?.album ?? widget.file.album ?? '',
  );
  late final _number = TextEditingController(
    text: '${widget.edit?.trackNumber ?? widget.file.trackNumber ?? ''}',
  );
  late String? _cover = widget.edit?.coverPath;

  /// Covers picked here and not saved, deleted when leaving.
  final _picked = <String>{};
  bool _saving = false;
  bool _tried = false;

  /// Kept for [dispose], which can't read providers.
  late final CoverStore _covers = ref.read(coverStoreProvider);

  @override
  void initState() {
    super.initState();
    _covers;
  }

  @override
  void dispose() {
    for (final path in _picked) {
      unawaited(_covers.delete(path));
    }
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final path = await _covers.pick(widget.file.id);
    if (path == null || !mounted) return;
    setState(() {
      if (_picked.remove(_cover)) {
        unawaited(_covers.delete(_cover));
      }
      _cover = path;
      _picked.add(path);
    });
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_title.text.trim().isEmpty || _saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    await saveSongInfo(ref, widget.file, (
      title: _title.text,
      artist: _artist.text,
      album: _album.text,
      trackNumber: int.tryParse(_number.text),
      coverPath: _cover,
    ), oldCover: widget.edit?.coverPath);
    _picked.remove(_cover);
    messenger.showSnackBar(SnackBar(content: Text(l10n.songInfoSaved)));
    router.pop();
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    await resetSongInfo(ref, widget.file.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.songInfoResetDone)));
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final cover = _cover;
    final titleMissing = _tried && _title.text.trim().isEmpty;
    InputDecoration field(String label, {String? error}) =>
        InputDecoration(labelText: label, errorText: error);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.songInfoTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.actionSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ZemaSpacing.screenSide,
          12,
          ZemaSpacing.screenSide,
          24,
        ),
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 96,
                child: cover == null
                    ? TrackArt(track: widget.file, size: 96, radius: 12)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(cover),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => LetterTile(
                            label: _title.text,
                            size: 96,
                            radius: 12,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _pickCover,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(l10n.songInfoChooseCover),
                    ),
                    if (cover != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _cover = null),
                        icon: const Icon(Icons.hide_image_outlined),
                        label: Text(l10n.songInfoRemoveCover),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: field(
              l10n.songInfoFieldTitle,
              error: titleMissing ? l10n.songInfoTitleRequired : null,
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _artist,
            decoration: field(l10n.songInfoFieldArtist),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _album,
            decoration: field(l10n.songInfoFieldAlbum),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _number,
            decoration: field(l10n.songInfoFieldTrackNumber),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.songInfoNote,
            style: textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
          if (widget.edit != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                onPressed: _saving ? null : _reset,
                child: Text(l10n.songInfoReset),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
