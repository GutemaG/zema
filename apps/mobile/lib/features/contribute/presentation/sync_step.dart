import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../app/database/database_provider.dart';
import '../../lyrics/application/lyrics_prefs.dart';
import '../../lyrics/presentation/lyrics_view.dart';
import '../../player/application/player_providers.dart';
import 'lyrics_step.dart';
import '../application/drafts.dart';
import '../application/recording.dart';
import '../data/sync_player.dart';

/// How far a nudge moves a start, and how often holding repeats it.
const nudgeStep = Duration(milliseconds: 100);
const _nudgeRepeat = Duration(milliseconds: 150);

/// The recording's audio on this phone: Zema's copy of a shared file, or
/// the library track the draft points at. Null when it's gone.
Future<Uri?> recordingAudio(WidgetRef ref, ContributionDraft draft) async {
  final recording = draft.recording;
  if (recording == null) return null;
  if (recording.source == RecordingSource.telegram) {
    final path = draft.audioPath;
    return path == null ? null : Uri.file(path);
  }
  if (recording.source != RecordingSource.localFile) return null;
  final trackId = draft.trackId;
  if (trackId == null) return null;
  final tracks = await ref.read(databaseProvider).libraryDao.tracksByIds([
    trackId,
  ]);
  final track = tracks.firstOrNull;
  return track == null ? null : Uri.parse(track.uri);
}

/// S21, step 3, the List view: the recording plays, and a tap times each
/// sung line in turn. A timed line can be nudged or redone from.
class SyncStep extends ConsumerStatefulWidget {
  const SyncStep({super.key, required this.id, required this.draft});

  final int id;
  final ContributionDraft draft;

  @override
  ConsumerState<SyncStep> createState() => _SyncStepState();
}

enum _Audio { loading, ready, missing }

/// S21's views: the List and Focus views time lines; Preview plays the
/// result in the shared lyrics view.
enum _View { list, focus, preview }

class _SyncStepState extends ConsumerState<SyncStep> {
  late final SyncPlayer _player = ref.read(syncPlayerProvider)();
  late final AppLifecycleListener _lifecycle;
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _currentKey = GlobalKey();

  var _audio = _Audio.loading;
  var _position = Duration.zero;
  Duration? _duration;
  var _playing = false;
  var _speed = 1.0;

  /// The timed line whose controls are open.
  int? _selected;

  var _view = _View.list;

  /// The timing view to go back to after Preview.
  var _timingView = _View.list;

  late final List<LineOccurrence> _lines = expandPlayOrder(widget.draft.song)
      .occurrences;

  List<Duration?> get _starts => startsFor(widget.draft.starts, _lines.length);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () => unawaited(_player.pause()),
    );
    _subscriptions
      ..add(_player.positions.listen((p) => setState(() => _position = p)))
      ..add(_player.playing.listen((p) => setState(() => _playing = p)));
    // After the first frame: loading changes providers (the draft's starts,
    // the main player), which isn't allowed while building.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    // Only one thing plays at a time.
    unawaited(ref.read(audioHandlerProvider).pause());
    if (widget.draft.starts.length != _lines.length) {
      _changeStarts((starts) => starts);
    }
    final uri = await recordingAudio(ref, widget.draft);
    if (!mounted) return;
    if (uri == null) {
      setState(() => _audio = _Audio.missing);
      return;
    }
    try {
      final duration = await _player.load(uri);
      // Coming back to a draft part-way synced: ready a little before the
      // next line to time.
      final starts = _starts;
      if (nextUntimed(starts) case final next? when next > 0) {
        await _player.seek(redoPosition(starts, next));
      }
      if (mounted) {
        setState(() {
          _duration = duration;
          _audio = _Audio.ready;
        });
        _revealCurrent();
      }
    } on Object {
      if (mounted) setState(() => _audio = _Audio.missing);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
  }

  void _edit(ContributionDraft Function(ContributionDraft draft) change) =>
      ref.read(draftEditorProvider(widget.id).notifier).edit(change);

  /// Changes the starts of the latest draft (holding a nudge repeats faster
  /// than the screen rebuilds).
  void _changeStarts(List<Duration?> Function(List<Duration?> starts) change) =>
      _edit(
        (draft) => draft.copyWith(
          starts: change(startsFor(draft.starts, _lines.length)),
        ),
      );

  void _tap() {
    final position = _player.position;
    _changeStarts((starts) => tapNext(starts, position));
    _selected = null;
    _revealCurrent();
  }

  void _undo() {
    _changeStarts(undoLastTap);
    _selected = null;
    _revealCurrent();
  }

  /// Opens the controls of timed line [index] and moves the recording to
  /// its start, or closes them when they are open.
  void _select(int index) {
    if (_selected == index) return setState(() => _selected = null);
    setState(() => _selected = index);
    if (_starts[index] case final start?) unawaited(_player.seek(start));
  }

  void _nudge(int index, Duration by) =>
      _changeStarts((starts) => nudgeStart(starts, index, by));

  Future<void> _redo(int index) async {
    final starts = _starts;
    final at = redoPosition(starts, index);
    _changeStarts((starts) => redoFrom(starts, index));
    setState(() => _selected = null);
    await _player.seek(at);
    await _player.play();
    _revealCurrent();
  }

  void _revealCurrent() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = _currentKey.currentContext;
    if (context != null && context.mounted) {
      unawaited(
        Scrollable.ensureVisible(
          context,
          alignment: 0.3,
          duration: const Duration(milliseconds: 200),
        ),
      );
    }
  });

  Future<void> _back5() async {
    final at = _player.position - const Duration(seconds: 5);
    await _player.seek(at < Duration.zero ? Duration.zero : at);
  }

  Future<void> _playPause() => _playing ? _player.pause() : _player.play();

  Future<void> _startPreview() async {
    setState(() {
      _timingView = _view;
      _view = _View.preview;
      _selected = null;
    });
    await _player.seek(Duration.zero);
    await _player.play();
  }

  Future<void> _endPreview() async {
    setState(() => _view = _timingView);
    await _player.pause();
    _revealCurrent();
  }

  Future<void> _toggleSpeed() async {
    final speed = _speed == 1.0 ? 0.75 : 1.0;
    setState(() => _speed = speed);
    await _player.setSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final starts = _starts;
    final current = nextUntimed(starts);
    final synced = current == null && starts.isNotEmpty;

    if (_audio == _Audio.missing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.contributeSyncNoAudio, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    _edit((d) => d.copyWith(step: DraftStep.recording)),
                child: Text(l10n.contributeSyncChooseRecording),
              ),
            ],
          ),
        ),
      );
    }

    final bar = _ViewBar(
      view: _view,
      canPreview: starts.any((s) => s != null) && _audio == _Audio.ready,
      onView: (view) => setState(() {
        _view = view;
        _selected = null;
      }),
      onPreview: () => unawaited(_startPreview()),
      onEndPreview: () => unawaited(_endPreview()),
      onSkip: () =>
          _edit((d) => d.copyWith(starts: const [], step: DraftStep.review)),
    );
    final playback = Padding(
      padding: const EdgeInsets.symmetric(horizontal: ZemaSpacing.screenSide),
      child: _PlaybackBar(
        position: _position,
        duration: _duration,
        playing: _playing,
        speed: _speed,
        ready: _audio == _Audio.ready,
        onPlayPause: () => unawaited(_playPause()),
        onBack5: () => unawaited(_back5()),
        onSpeed: () => unawaited(_toggleSpeed()),
        onSeek: (at) => unawaited(_player.seek(at)),
      ),
    );

    switch (_view) {
      case _View.preview:
        return Column(
          children: [
            bar,
            playback,
            Expanded(
              child: LyricsLines(
                lines: _lines,
                synced: true,
                current: lineAt(starts, _position),
                display: ref.watch(lyricsDisplayProvider),
                onTapLine: (i) {
                  if (starts[i] case final start?) {
                    unawaited(_player.seek(start));
                  }
                },
              ),
            ),
          ],
        );
      case _View.focus:
        return Column(
          children: [
            bar,
            Expanded(
              child: _FocusView(
                lines: _lines,
                sections: widget.draft.song.sections,
                starts: starts,
                position: _position,
                duration: _duration,
                playing: _playing,
                ready: _audio == _Audio.ready,
                onTap: synced
                    ? () => _edit((d) => d.copyWith(step: DraftStep.review))
                    : _playing
                    ? _tap
                    : () => unawaited(_player.play()),
                onUndo: starts.any((s) => s != null) ? _undo : null,
                onPlayPause: () => unawaited(_playPause()),
                onBack5: () => unawaited(_back5()),
              ),
            ),
          ],
        );
      case _View.list:
        break;
    }

    return Column(
      children: [
        bar,
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ZemaSpacing.screenSide,
          ),
          child: _PlaybackBar(
            position: _position,
            duration: _duration,
            playing: _playing,
            speed: _speed,
            ready: _audio == _Audio.ready,
            onPlayPause: () =>
                unawaited(_playing ? _player.pause() : _player.play()),
            onBack5: () => unawaited(_back5()),
            onSpeed: () => unawaited(_toggleSpeed()),
            onSeek: (at) => unawaited(_player.seek(at)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              ZemaSpacing.screenSide,
              8,
              ZemaSpacing.screenSide,
              8,
            ),
            itemCount: _lines.length,
            itemBuilder: (context, i) {
              final start = starts[i];
              final isCurrent = i == current;
              final selected = i == _selected && start != null;
              return Container(
                key: isCurrent ? _currentKey : ValueKey(i),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isCurrent || selected ? colors.surface : null,
                  borderRadius: BorderRadius.circular(ZemaRadius.small),
                  border: isCurrent || selected
                      ? Border.all(color: colors.primary)
                      : null,
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(ZemaRadius.small),
                      onTap: start == null ? null : () => _select(i),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: ZemaSpacing.minTap + 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _lines[i].line.text,
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: start != null || isCurrent
                                            ? colors.text
                                            : colors.muted,
                                        fontWeight: isCurrent
                                            ? FontWeight.w700
                                            : null,
                                      ),
                                    ),
                                    if (isCurrent)
                                      Text(
                                        l10n.contributeSyncTapHint,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colors.primaryText,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                start == null ? '—' : formatSyncTime(start),
                                style: textTheme.labelLarge?.copyWith(
                                  color: start == null
                                      ? colors.muted
                                      : colors.primaryText,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _HoldButton(
                              icon: Icons.remove,
                              label: l10n.contributeSyncEarlier,
                              onStep: () => _nudge(i, -nudgeStep),
                            ),
                            _HoldButton(
                              icon: Icons.add,
                              label: l10n.contributeSyncLater,
                              onStep: () => _nudge(i, nudgeStep),
                            ),
                            TextButton.icon(
                              onPressed: () => unawaited(_redo(i)),
                              icon: const Icon(Icons.replay),
                              label: Text(l10n.contributeSyncRedo),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            0,
            ZemaSpacing.screenSide,
            12,
          ),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: starts.any((s) => s != null) ? _undo : null,
                  icon: const Icon(Icons.undo),
                  label: Text(l10n.contributeSyncUndo),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: FilledButton(
                  onPressed: synced
                      ? () => _edit((d) => d.copyWith(step: DraftStep.review))
                      : _playing
                      ? _tap
                      : () => unawaited(_player.play()),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ZemaRadius.large),
                    ),
                    textStyle: textTheme.titleLarge,
                  ),
                  child: Text(
                    synced
                        ? l10n.contributeNextReview
                        : _playing
                        ? l10n.contributeSyncTap
                        : l10n.contributeSyncPressPlay,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// List or Focus, and Preview; during Preview, a way back.
class _ViewBar extends StatelessWidget {
  const _ViewBar({
    required this.view,
    required this.canPreview,
    required this.onView,
    required this.onPreview,
    required this.onEndPreview,
    required this.onSkip,
  });

  final _View view;
  final bool canPreview;
  final ValueChanged<_View> onView;
  final VoidCallback onPreview;
  final VoidCallback onEndPreview;

  /// Leaves without timings (text only).
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        0,
        ZemaSpacing.screenSide,
        8,
      ),
      child: view == _View.preview
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onEndPreview,
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.contributeSyncEndPreview),
              ),
            )
          : Row(
              children: [
                // Icons only, so the bar stays one row with large text.
                SegmentedButton<_View>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _View.list,
                      icon: const Icon(Icons.view_list),
                      tooltip: l10n.contributeSyncList,
                    ),
                    ButtonSegment(
                      value: _View.focus,
                      icon: const Icon(Icons.center_focus_strong),
                      tooltip: l10n.contributeSyncFocus,
                    ),
                  ],
                  selected: {view},
                  onSelectionChanged: (views) => onView(views.single),
                ),
                const Spacer(),
                Flexible(
                  child: TextButton.icon(
                    onPressed: canPreview ? onPreview : null,
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(
                      l10n.contributeSyncPreview,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.contributeSyncMore,
                  onSelected: (_) => onSkip(),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'skip',
                      child: Text(l10n.contributeSyncSkip),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// The Focus view: the line before with its time, the next line to time
/// large with its block, the one after, a big tap area, and Undo, Play or
/// Pause and −5 s.
class _FocusView extends StatelessWidget {
  const _FocusView({
    required this.lines,
    required this.sections,
    required this.starts,
    required this.position,
    required this.duration,
    required this.playing,
    required this.ready,
    required this.onTap,
    required this.onUndo,
    required this.onPlayPause,
    required this.onBack5,
  });

  final List<LineOccurrence> lines;
  final List<LyricSection> sections;
  final List<Duration?> starts;
  final Duration position;
  final Duration? duration;
  final bool playing;
  final bool ready;
  final VoidCallback onTap;
  final VoidCallback? onUndo;
  final VoidCallback onPlayPause;
  final VoidCallback onBack5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final current = nextUntimed(starts);
    final previous = (current ?? lines.length) - 1;
    final section = current == null
        ? null
        : sections.where((s) => s.id == lines[current].sectionId).firstOrNull;
    final total = duration;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        0,
        ZemaSpacing.screenSide,
        8,
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    if (previous >= 0) ...[
                      Text(
                        lines[previous].line.text,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                      if (starts[previous] case final start?)
                        Text(
                          l10n.contributeSyncTimedAt(formatSyncTime(start)),
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.primaryText,
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                    if (current == null)
                      Text(
                        l10n.contributeSyncAllTimed,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
                      )
                    else ...[
                      if (section != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              ZemaRadius.pill,
                            ),
                            border: Border.all(color: colors.primary),
                          ),
                          child: Text(
                            sectionLabel(l10n, sections, section).toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primaryText,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        lines[current].line.text,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (current + 1 < lines.length) ...[
                        const SizedBox(height: 24),
                        Text(
                          lines[current + 1].line.text,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Material(
              color: ready ? colors.primary : colors.tile,
              borderRadius: BorderRadius.circular(ZemaRadius.large),
              child: InkWell(
                borderRadius: BorderRadius.circular(ZemaRadius.large),
                onTap: ready ? onTap : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        current == null
                            ? l10n.contributeNextReview
                            : playing
                            ? l10n.contributeSyncHearIt
                            : l10n.contributeSyncPressPlay,
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total == null
                            ? formatSyncTime(position)
                            : '${formatSyncTime(position)} / '
                                  '${formatDurationText(total)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onUndo,
                icon: const Icon(Icons.undo),
                label: Text(l10n.contributeSyncUndo),
              ),
              TextButton.icon(
                onPressed: ready ? onPlayPause : null,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                label: Text(playing ? l10n.playerPause : l10n.playerPlay),
              ),
              TextButton(
                onPressed: ready ? onBack5 : null,
                child: Text(l10n.contributeSyncBack5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A start as m:ss.t, the way S21 shows it.
String formatSyncTime(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final tenths = d.inMilliseconds.remainder(1000) ~/ 100;
  return '$m:$s.$tenths';
}

/// Play/pause, the position over the length, −5 s and the speed.
class _PlaybackBar extends StatelessWidget {
  const _PlaybackBar({
    required this.position,
    required this.duration,
    required this.playing,
    required this.speed,
    required this.ready,
    required this.onPlayPause,
    required this.onBack5,
    required this.onSpeed,
    required this.onSeek,
  });

  final Duration position;
  final Duration? duration;
  final bool playing;
  final double speed;
  final bool ready;
  final VoidCallback onPlayPause;
  final VoidCallback onBack5;
  final VoidCallback onSpeed;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final total = duration;
    final max = total == null || total == Duration.zero
        ? 1.0
        : total.inMilliseconds.toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ZemaRadius.medium),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Slider(
            value: position.inMilliseconds.toDouble().clamp(0, max),
            max: max,
            onChanged: ready && total != null
                ? (v) => onSeek(Duration(milliseconds: v.round()))
                : null,
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: formatSyncTime(position),
                    children: [
                      if (total != null)
                        TextSpan(
                          text: ' / ${formatDurationText(total)}',
                          style: TextStyle(color: colors.muted),
                        ),
                    ],
                  ),
                  style: textTheme.labelLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              TextButton(
                onPressed: ready ? onBack5 : null,
                child: Text(l10n.contributeSyncBack5),
              ),
              TextButton(
                onPressed: ready ? onSpeed : null,
                child: Text(
                  speed == 1.0
                      ? l10n.contributeSyncSpeedNormal
                      : l10n.contributeSyncSpeedSlow,
                ),
              ),
              IconButton.filled(
                tooltip: playing ? l10n.playerPause : l10n.playerPlay,
                onPressed: ready ? onPlayPause : null,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A button that acts once when tapped and keeps acting while held.
class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.icon,
    required this.label,
    required this.onStep,
  });

  final IconData icon;
  final String label;
  final VoidCallback onStep;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  Timer? _timer;

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: (_) =>
        _timer = Timer.periodic(_nudgeRepeat, (_) => widget.onStep()),
    onLongPressEnd: (_) => _stop(),
    onLongPressCancel: _stop,
    // A label, not a tooltip: a tooltip's own long press would win.
    child: Semantics(
      label: widget.label,
      child: IconButton.outlined(
        onPressed: widget.onStep,
        icon: Icon(widget.icon),
      ),
    ),
  );
}
