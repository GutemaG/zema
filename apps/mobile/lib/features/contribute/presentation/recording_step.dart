import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../library/application/library_providers.dart';
import '../../library/application/tracks_query.dart';
import '../../library/presentation/widgets/library_search_field.dart';
import '../../library/presentation/widgets/track_row.dart';
import '../application/drafts.dart';
import '../application/recording.dart';

/// The name a shared file had, from Zema's copy at [path]
/// (`<millis>-<name>`).
String sharedFileName(String path) =>
    p.basename(path).replaceFirst(RegExp(r'^\d+-'), '');

/// S20, step 2: which recording the lyrics belong to — a song on the
/// phone, a YouTube video, or an audio file shared from Telegram. A new
/// song can skip it.
class RecordingStep extends ConsumerStatefulWidget {
  const RecordingStep({super.key, required this.id, required this.draft});

  final int id;
  final ContributionDraft draft;

  @override
  ConsumerState<RecordingStep> createState() => _RecordingStepState();
}

class _RecordingStepState extends ConsumerState<RecordingStep> {
  late RecordingSource? _choice = widget.draft.recording?.source;
  late final _link = TextEditingController(
    text: switch (widget.draft.recording) {
      Recording(source: RecordingSource.youtube, :final youtubeId?) =>
        'https://youtu.be/$youtubeId',
      _ => '',
    },
  );
  late final _videoTitle = TextEditingController(text: widget.draft.videoTitle);
  late final _duration = TextEditingController(
    text: switch (widget.draft.recording) {
      Recording(source: RecordingSource.youtube, :final duration?) =>
        formatDurationText(duration),
      _ => '',
    },
  );
  late final _artist = TextEditingController(
    text: widget.draft.recording?.artist ?? widget.draft.song.artist,
  );

  ContributionDraft get _draft => widget.draft;

  @override
  void dispose() {
    for (final c in [_link, _videoTitle, _duration, _artist]) {
      c.dispose();
    }
    super.dispose();
  }

  void _edit(ContributionDraft Function(ContributionDraft draft) change) =>
      ref.read(draftEditorProvider(widget.id).notifier).edit(change);

  /// The recording so far, with [source] and the artist typed.
  Recording _recording(
    RecordingSource source, {
    Duration? duration,
    String? youtubeId,
    String? fileName,
  }) => Recording(
    id: _draft.recording?.id ?? newRecordingId(),
    songId: '',
    source: source,
    artist: _artist.text,
    duration: duration,
    youtubeId: youtubeId,
    fileName: fileName,
  );

  void _fillArtist(String? artist) {
    if (_artist.text.trim().isEmpty && artist != null) _artist.text = artist;
  }

  Future<void> _chooseLocal() async {
    setState(() => _choice = RecordingSource.localFile);
    final track = await pickTrack(context, selected: _draft.trackId);
    if (track == null || !mounted) return;
    _fillArtist(track.artist);
    _edit(
      (draft) => draft.copyWith(
        recording: () => _recording(
          RecordingSource.localFile,
          duration: track.duration,
          fileName: p.basename(track.path),
        ),
        trackId: () => track.id,
      ),
    );
  }

  void _chooseYoutube() {
    setState(() => _choice = RecordingSource.youtube);
    _youtubeChanged();
  }

  void _youtubeChanged() {
    final id = youtubeVideoId(_link.text);
    _edit(
      (draft) => draft.copyWith(
        recording: () => id == null
            ? null
            : _recording(
                RecordingSource.youtube,
                youtubeId: id,
                duration: parseDurationText(_duration.text),
              ),
        trackId: () => null,
        videoTitle: () =>
            _videoTitle.text.trim().isEmpty ? null : _videoTitle.text.trim(),
      ),
    );
  }

  void _chooseShared() {
    final path = _draft.audioPath;
    if (path == null) return;
    setState(() => _choice = RecordingSource.telegram);
    final previous = _draft.recording;
    _edit(
      (draft) => draft.copyWith(
        recording: () => _recording(
          RecordingSource.telegram,
          fileName: sharedFileName(path),
          duration: previous?.source == RecordingSource.telegram
              ? previous!.duration
              : null,
        ),
        trackId: () => null,
      ),
    );
  }

  void _artistChanged() {
    final r = _draft.recording;
    if (r == null) return;
    _edit(
      (draft) => draft.copyWith(
        recording: () => _recording(
          r.source,
          duration: r.duration,
          youtubeId: r.youtubeId,
          fileName: r.fileName,
        ),
      ),
    );
  }

  /// Whether the recording can be sent: it passes the shared rules, and a
  /// typed duration reads.
  bool get _ready {
    final r = _draft.recording;
    if (r == null || r.source != _choice) return false;
    if (_duration.text.trim().isNotEmpty &&
        r.source == RecordingSource.youtube &&
        parseDurationText(_duration.text) == null) {
      return false;
    }
    const songId = 'song';
    return recordingErrors(
      Recording(
        id: r.id,
        songId: songId,
        source: r.source,
        artist: r.artist,
        duration: r.duration,
        youtubeId: r.youtubeId,
        fileName: r.fileName,
      ),
      songId: songId,
    ).isEmpty;
  }

  void _next() {
    final l10n = AppLocalizations.of(context);
    if (_draft.lyricsErrors.isNotEmpty) {
      _edit((draft) => draft.copyWith(step: DraftStep.lyrics));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.contributeLyricsFirst)));
      return;
    }
    final youtube = _draft.recording?.source == RecordingSource.youtube;
    _edit(
      (draft) =>
          draft.copyWith(step: youtube ? DraftStep.review : DraftStep.sync),
    );
  }

  // The song on the phone the lyrics were started from stays: they are
  // still for it, only without timings.
  void _skip() => _edit(
    (draft) => draft.copyWith(
      recording: () => null,
      starts: const [],
      step: DraftStep.review,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final draft = _draft;
    final recording = draft.recording;
    final videoId = _choice == RecordingSource.youtube
        ? youtubeVideoId(_link.text)
        : null;
    final linkTyped = _link.text.trim().isNotEmpty;
    final durationTyped = _duration.text.trim().isNotEmpty;
    final sharedAvailable = draft.audioPath != null || Platform.isAndroid;

    if (videoId != null) {
      // The channel name fills an empty artist once the info arrives.
      ref.listen(youtubeInfoProvider(videoId), (_, next) {
        if (next case AsyncData(value: final info?)) {
          _fillArtist(info.author);
          if (_draft.videoTitle != info.title) {
            _edit((draft) => draft.copyWith(videoTitle: () => info.title));
          }
          _artistChanged();
        }
      });
    }

    final track = draft.trackId == null
        ? null
        : ref
              .watch(libraryTracksProvider)
              .value
              ?.where((t) => t.id == draft.trackId)
              .firstOrNull;

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
              Text(l10n.contributeRecordingTitle, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l10n.contributeRecordingBody,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 16),
              _Choice(
                icon: Icons.library_music_outlined,
                title: l10n.contributeRecordingLocal,
                selected: _choice == RecordingSource.localFile,
                onTap: _chooseLocal,
                child: _choice == RecordingSource.localFile
                    ? _picked(
                        context,
                        recording?.source == RecordingSource.localFile
                            ? recording
                            : null,
                        title: track?.title,
                        onChange: _chooseLocal,
                      )
                    : null,
              ),
              _Choice(
                icon: Icons.smart_display_outlined,
                title: l10n.contributeRecordingYoutube,
                selected: _choice == RecordingSource.youtube,
                onTap: _chooseYoutube,
                child: _choice == RecordingSource.youtube
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _link,
                            onChanged: (_) => setState(_youtubeChanged),
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: l10n.contributeYoutubeLink,
                              errorText: linkTyped && videoId == null
                                  ? l10n.contributeYoutubeBadLink
                                  : null,
                              errorMaxLines: 2,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          if (videoId != null) ...[
                            const SizedBox(height: 12),
                            _VideoInfo(
                              videoId: videoId,
                              title: _videoTitle,
                              onTitleChanged: _youtubeChanged,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _duration,
                              onChanged: (_) => setState(_youtubeChanged),
                              keyboardType: TextInputType.datetime,
                              decoration: InputDecoration(
                                labelText: l10n.contributeYoutubeDuration,
                                hintText: '4:05',
                                errorText:
                                    durationTyped &&
                                        parseDurationText(_duration.text) ==
                                            null
                                    ? l10n.contributeYoutubeBadDuration
                                    : null,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _Note(text: l10n.contributeYoutubeNoSync),
                        ],
                      )
                    : null,
              ),
              if (sharedAvailable)
                _Choice(
                  icon: Icons.send_outlined,
                  title: l10n.contributeRecordingShared,
                  selected: _choice == RecordingSource.telegram,
                  onTap: draft.audioPath == null
                      ? () => setState(() => _choice = RecordingSource.telegram)
                      : _chooseShared,
                  child: _choice != RecordingSource.telegram
                      ? null
                      : draft.audioPath == null
                      ? _Note(text: l10n.contributeSharedHow)
                      : _picked(
                          context,
                          recording?.source == RecordingSource.telegram
                              ? recording
                              : null,
                        ),
                ),
              if (recording != null && recording.source == _choice) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _artist,
                  onChanged: (_) => _artistChanged(),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.contributeRecordingArtist,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
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
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _ready ? _next : null,
                  child: Text(
                    recording?.source == RecordingSource.youtube
                        ? l10n.contributeNextReview
                        : l10n.contributeNextSync,
                  ),
                ),
              ),
              // Side by side, or stacked when large text doesn't fit.
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.center,
                children: [
                  TextButton(
                    onPressed: () =>
                        _edit((d) => d.copyWith(step: DraftStep.lyrics)),
                    child: Text(l10n.contributeBack),
                  ),
                  if (draft.kind == ContributionKind.newSong)
                    TextButton(
                      onPressed: _skip,
                      child: Text(l10n.contributeSkipRecording),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The chosen file: its name and length, and (for a song on the phone)
  /// a button to choose another.
  Widget _picked(
    BuildContext context,
    Recording? recording, {
    String? title,
    VoidCallback? onChange,
  }) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    if (recording == null) {
      return onChange == null
          ? const SizedBox.shrink()
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                onPressed: onChange,
                child: Text(l10n.contributeChooseSong),
              ),
            );
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? recording.fileName ?? '',
                style: textTheme.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                [
                  if (title != null) ?recording.fileName,
                  if (recording.duration case final d?) formatDurationText(d),
                ].join(' · '),
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onChange != null)
          TextButton(onPressed: onChange, child: Text(l10n.contributeChange)),
      ],
    );
  }
}

/// One way to give the recording: a selectable card that opens its fields.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.child,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ZemaRadius.medium),
        border: Border.all(color: selected ? colors.primary : colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            selected: selected,
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(ZemaRadius.medium),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: selected ? colors.primaryText : colors.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected ? colors.primary : colors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (child case final child?)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(ZemaRadius.small),
      ),
      child: Text(text),
    );
  }
}

/// The video's thumbnail and title from YouTube; offline, a field for the
/// title.
class _VideoInfo extends ConsumerWidget {
  const _VideoInfo({
    required this.videoId,
    required this.title,
    required this.onTitleChanged,
  });

  final String videoId;
  final TextEditingController title;
  final VoidCallback onTitleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    return switch (ref.watch(youtubeInfoProvider(videoId))) {
      AsyncData(value: final info?) => Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ZemaRadius.small),
            child: SizedBox(
              width: 96,
              height: 54,
              child: info.thumbnail == null
                  ? ColoredBox(
                      color: colors.tile,
                      child: Icon(Icons.smart_display, color: colors.tileFg),
                    )
                  : Image.memory(info.thumbnail!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge,
                ),
                if (info.author case final author?)
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colors.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
      AsyncLoading() => const LinearProgressIndicator(),
      _ => TextField(
        controller: title,
        onChanged: (_) => onTitleChanged(),
        decoration: InputDecoration(
          labelText: l10n.contributeYoutubeTitle,
          helperText: l10n.contributeYoutubeOffline,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
      ),
    };
  }
}

/// A searchable list of the phone's songs; returns the one tapped.
/// Asks which song on the phone to use, [selected] marked; null when none
/// is chosen.
Future<Track?> pickTrack(BuildContext context, {int? selected}) =>
    showModalBottomSheet<Track>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TrackPicker(selected: selected),
    );

class _TrackPicker extends ConsumerStatefulWidget {
  const _TrackPicker({required this.selected});

  /// The track already chosen, marked.
  final int? selected;

  @override
  ConsumerState<_TrackPicker> createState() => _TrackPickerState();
}

class _TrackPickerState extends ConsumerState<_TrackPicker> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final tracks = ref.watch(libraryTracksProvider).value ?? const [];
    final visible = filterTracks(tracks, _query);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            12,
            ZemaSpacing.screenSide,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.contributeChooseSong,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LibrarySearchField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tracks.isEmpty
                          ? l10n.contributeNoSongs
                          : l10n.libraryNoResultsTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemExtent: TrackRow.height,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final track = visible[index];
                    final chosen = track.id == widget.selected;
                    return Semantics(
                      key: ValueKey(track.id),
                      selected: chosen,
                      child: TrackRow(
                        track: track,
                        onTap: () => Navigator.pop(context, track),
                        trailing: chosen
                            ? Icon(Icons.check, color: colors.primary)
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
