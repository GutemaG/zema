import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../account/application/account_providers.dart';
import '../../contribute/application/contribution_starts.dart';
import '../../contribute/presentation/start_contribution.dart';
import '../../player/application/player_providers.dart';
import '../application/lyrics_links.dart';
import '../application/lyrics_prefs.dart';
import '../application/track_lyrics.dart';
import 'lyrics_options_sheet.dart';
import 'match_lyrics_sheet.dart';

/// The lyrics of [track] (C06): the line being sung highlighted and kept in
/// view, past lines faint, choruses marked; tapping a line seeks to it.
/// Plain lyrics show without highlight; an unlinked track offers Match
/// lyrics; lyrics that can't be downloaded show C07 with Try again.
class LyricsView extends ConsumerWidget {
  const LyricsView({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(trackLyricsProvider(track.id))) {
      AsyncData(value: final lyrics?) when lyrics.lines.isNotEmpty => Stack(
        children: [
          Positioned.fill(
            child: _Lines(track: track, lyrics: lyrics),
          ),
          if (lyrics.pending)
            const PositionedDirectional(
              top: 8,
              start: ZemaSpacing.screenSide,
              child: PendingReviewChip(),
            ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: _OptionsButton(lyrics: lyrics),
          ),
        ],
      ),
      AsyncData() => NoLyrics(track: track),
      AsyncError(:final error) => LyricsUnavailable(error: error),
      _ => const SizedBox.shrink(),
    };
  }
}

/// C07 for lyrics that couldn't be loaded: offline for a
/// [NetworkFailure], an error otherwise. Try again downloads again.
class LyricsUnavailable extends ConsumerWidget {
  const LyricsUnavailable({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final offline = error is NetworkFailure;
    return EmptyState(
      kind: offline ? EmptyStateKind.offline : EmptyStateKind.error,
      title: offline ? l10n.lyricsOfflineTitle : l10n.lyricsLoadFailedTitle,
      message: offline
          ? l10n.lyricsOfflineMessage
          : l10n.lyricsLoadFailedMessage,
      actionLabel: l10n.actionTryAgain,
      // Nothing remembers a failure, so this fetches again.
      onAction: () => ref.invalidate(songProvider),
    );
  }
}

/// The "No lyrics" state with a Match lyrics button, and Add lyrics (when
/// the build has a backend) to contribute them.
class NoLyrics extends ConsumerWidget {
  const NoLyrics({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ZemaSpacing.screenSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lyrics_outlined, size: 40, color: colors.faint),
            const SizedBox(height: 12),
            Text(
              l10n.playerNoLyrics,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.link),
              label: Text(l10n.songMatchLyrics),
              onPressed: () => unawaited(showMatchLyricsSheet(context, track)),
            ),
            if (ref.watch(accountsAvailableProvider)) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: Text(l10n.contributeAddLyrics),
                onPressed: () => unawaited(
                  startContribution(
                    context,
                    ref,
                    draft: newSongDraftFor(track),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Marks lyrics the user sent that a moderator hasn't checked yet.
class PendingReviewChip extends StatelessWidget {
  const PendingReviewChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(ZemaRadius.pill),
      ),
      child: Text(
        AppLocalizations.of(context).lyricsPendingReview,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colors.accentText),
      ),
    );
  }
}

class _OptionsButton extends StatelessWidget {
  const _OptionsButton({required this.lyrics});

  final TrackLyrics lyrics;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).lyricsOptions,
      icon: Icon(Icons.tune, color: context.zemaColors.muted),
      onPressed: () => unawaited(showLyricsOptionsSheet(context, lyrics)),
    );
  }
}

/// [lyrics] for [track], following the main player: the current line
/// lights up, and tapping a synced line seeks to it.
class _Lines extends ConsumerWidget {
  const _Lines({required this.track, required this.lyrics});

  final Track track;
  final TrackLyrics lyrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final synced = lyrics.synced;
    final shift = ref.watch(lyricsShiftProvider(lyrics));
    return LyricsLines(
      lines: lyrics.lines,
      synced: synced != null,
      current: ref.watch(currentLineProvider(track.id)),
      display: ref.watch(lyricsDisplayProvider),
      onTapLine: synced == null
          ? null
          : (i) => unawaited(
              ref
                  .read(playerControllerProvider)
                  .seek(synced.engine.startOf(i, offset: shift)),
            ),
    );
  }
}

/// The shared lyrics view (C06): [lines] scrolled so the [current] one sits
/// a third of the way down, past lines faint, choruses marked. Plain
/// lyrics ([synced] false) show without highlight. Used for a playing song
/// and for the sync editor's preview.
class LyricsLines extends StatefulWidget {
  const LyricsLines({
    super.key,
    required this.lines,
    required this.synced,
    required this.current,
    required this.display,
    this.onTapLine,
  });

  final List<LineOccurrence> lines;
  final bool synced;
  final int? current;
  final LyricsDisplay display;
  final ValueChanged<int>? onTapLine;

  @override
  State<LyricsLines> createState() => _LyricsLinesState();
}

class _LyricsLinesState extends State<LyricsLines> {
  /// How long auto-scroll waits after the user last scrolled.
  static const resumeAfter = Duration(seconds: 3);

  /// Where the current line is kept: a third of the way down.
  static const alignment = 0.33;

  /// Height of the fade at the top.
  static const fadeHeight = 48.0;

  final _scroll = ScrollController();
  late List<GlobalKey> _keys = _newKeys();
  Timer? _resume;
  var _userScrolling = false;

  List<GlobalKey> _newKeys() => [
    for (var i = 0; i < widget.lines.length; i++) GlobalKey(),
  ];

  @override
  void didUpdateWidget(LyricsLines old) {
    super.didUpdateWidget(old);
    if (old.lines.length != widget.lines.length) {
      _keys = _newKeys();
    }
    if (old.display.textScale != widget.display.textScale) {
      _followSoon(animate: false);
    } else if (old.current != widget.current) {
      _followSoon();
    }
  }

  @override
  void initState() {
    super.initState();
    _followSoon(animate: false);
  }

  @override
  void dispose() {
    _resume?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls the current line into place after this frame, unless the user
  /// is scrolling.
  void _followSoon({bool animate = true}) {
    // A frame may not be coming (e.g. paused after a manual scroll).
    WidgetsBinding.instance
      ..scheduleFrame()
      ..addPostFrameCallback((_) {
        if (!mounted || _userScrolling) return;
        final index = widget.current;
        if (index == null || index >= _keys.length) return;
        final line = _keys[index].currentContext;
        if (line == null) return;
        unawaited(
          Scrollable.ensureVisible(
            line,
            alignment: alignment,
            duration: animate
                ? const Duration(milliseconds: 300)
                : Duration.zero,
            curve: Curves.easeOutCubic,
          ),
        );
      });
  }

  bool _onScroll(UserScrollNotification n) {
    if (n.direction == ScrollDirection.idle) {
      _resume?.cancel();
      _resume = Timer(resumeAfter, () {
        _userScrolling = false;
        _followSoon();
      });
    } else {
      _resume?.cancel();
      _userScrolling = true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final synced = widget.synced;
    final current = widget.current;
    final onTapLine = widget.onTapLine;
    return LayoutBuilder(
      builder: (context, constraints) =>
          NotificationListener<UserScrollNotification>(
            onNotification: _onScroll,
            // Lines fade out at the top, under the title and options button.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [Colors.transparent, Colors.black],
                stops: [0, (fadeHeight / bounds.height).clamp(0, 1)],
              ).createShader(bounds),
              child: SingleChildScrollView(
                controller: _scroll,
                // Room above the first and below the last line so either can sit
                // where the current line is kept.
                padding: EdgeInsets.fromLTRB(
                  24,
                  constraints.maxHeight * alignment,
                  24,
                  constraints.maxHeight * (1 - alignment),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, line) in widget.lines.indexed)
                      _Line(
                        key: _keys[i],
                        line: line,
                        state: !synced || current == null
                            ? (!synced ? _LineState.plain : _LineState.ahead)
                            : i == current
                            ? _LineState.current
                            : i < current
                            ? _LineState.past
                            : _LineState.ahead,
                        display: widget.display,
                        onTap: onTapLine == null ? null : () => onTapLine(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

enum _LineState { plain, past, current, ahead }

class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.line,
    required this.state,
    required this.display,
    required this.onTap,
  });

  final LineOccurrence line;
  final _LineState state;
  final LyricsDisplay display;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final base = textTheme.titleLarge!;
    final color = switch (state) {
      _LineState.plain => colors.text,
      _LineState.past => colors.faint,
      _LineState.current => colors.primaryText,
      _LineState.ahead => colors.muted,
    };
    final transliteration = line.line.transliteration;
    final chorusStart =
        line.sectionKind == SectionKind.chorus && line.startsSection;
    return Semantics(
      selected: state == _LineState.current,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ZemaRadius.small),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chorusStart)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    l10n.lyricsChorus,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: base.copyWith(
                  color: color,
                  fontSize: base.fontSize! * display.textScale,
                  fontWeight: state == _LineState.current
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                child: Text(line.line.text),
              ),
              if (display.showTransliteration && transliteration != null)
                Text(
                  transliteration,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontSize:
                        textTheme.bodyMedium!.fontSize! * display.textScale,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The line being sung, or the first line, for the small panel under the
/// artwork; "No lyrics" when there are none, or why they couldn't load. Tapping it calls [onTap].
class LyricsPreview extends ConsumerWidget {
  const LyricsPreview({super.key, required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final state = ref.watch(trackLyricsProvider(track.id));
    final current = ref.watch(currentLineProvider(track.id));
    final line = switch (state.value) {
      final TrackLyrics l when l.lines.isNotEmpty =>
        l.lines[current ?? 0].line.text,
      _ => null,
    };
    final none = switch (state) {
      AsyncError(error: NetworkFailure()) => l10n.lyricsPreviewOffline,
      AsyncError() => l10n.lyricsLoadFailedTitle,
      _ => l10n.playerNoLyrics,
    };
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(ZemaRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(ZemaRadius.medium),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              line ?? none,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: line == null ? colors.muted : colors.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
