import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/format_duration.dart';
import '../../contribute/presentation/start_contribution.dart';
import '../../library/presentation/widgets/track_art.dart';
import '../application/library_fingerprints.dart';
import '../application/listen_controller.dart';
import '../application/quick_listen.dart';
import 'listen_lyrics_screen.dart';
import 'listen_visuals.dart';

/// Listen (intent 009 FR-5): identifies the song playing nearby among the
/// library's songs, and plays it from the same moment.
///
/// One stage that changes with the state: a breathing button at rest;
/// ripples that follow the sound, dancing bars and a filling ring while
/// listening; a burst and the song's artwork when found; a shake when not.
class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({super.key});

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
  @override
  void initState() {
    super.initState();
    final controller = ref.read(listenControllerProvider.notifier);
    if (ref.read(quickListenHostProvider) != null) {
      unawaited(controller.listen());
      return;
    }
    // Songs added since the last visit get their fingerprints.
    unawaited(ref.read(libraryFingerprintsProvider.notifier).start());
    unawaited(controller.prepare());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final state = ref.watch(listenControllerProvider);
    final controller = ref.read(listenControllerProvider.notifier);
    return Scaffold(
      backgroundColor: colors.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.listenTitle),
        centerTitle: true,
        leading: switch (ref.watch(quickListenHostProvider)) {
          final host? => IconButton(
            tooltip: l10n.playerClose,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => unawaited(host.close()),
          ),
          null => null,
        },
        actions: [
          if (ref.watch(quickListenHostProvider) == null)
            IconButton(
              tooltip: l10n.listenHistoryTitle,
              icon: const Icon(Icons.history_rounded),
              onPressed: () => context.push(AppRoutes.listenHistory),
            ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.25),
            radius: 0.95,
            colors: [
              Color.lerp(
                colors.soft,
                colors.bg,
                state is ListenFound || state is Listening ? 0 : 0.5,
              )!,
              colors.bg,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ZemaSpacing.screenSide,
            ),
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const _LibraryChip(),
                        const Spacer(),
                        _Stage(
                          state: state,
                          // At rest while songs are being prepared, so the
                          // animation doesn't take the CPU they need.
                          calm: ref.watch(
                            libraryFingerprintsProvider.select(
                              (p) => p.running,
                            ),
                          ),
                          onTap: state is Listening || state is ListenLoading
                              ? controller.cancel
                              : controller.listen,
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 210),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            // The old words leave in the first part and the new
                            // ones arrive after, so they never overlap.
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: animation,
                                    curve: const Interval(
                                      0.45,
                                      1,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0, 0.08),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.topCenter,
                              children: [...previous, ?current],
                            ),
                            child: _Words(
                              key: ValueKey(_wordsKey(state)),
                              state: state,
                              onListen: controller.listen,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _Privacy(text: l10n.listenPrivacy),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Text changes animate only when the message changes, not on every tick.
  static Object _wordsKey(ListenState state) => switch (state) {
    Listening(:final heard) => 'listening-${_hintStep(heard)}',
    final ListenFound found => found,
    _ => state.runtimeType,
  };
}

/// 0: just started, 1: still listening, 2: almost done.
int _hintStep(Duration heard) => heard < listenCheckpoints[0]
    ? 0
    : heard < listenCheckpoints[1]
    ? 1
    : 2;

/// The button and everything drawn around it.
class _Stage extends StatefulWidget {
  const _Stage({required this.state, required this.onTap, this.calm = false});

  final ListenState state;
  final VoidCallback onTap;

  /// No idle breathing (listening still animates).
  final bool calm;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with TickerProviderStateMixin {
  static const _size = 300.0;
  static const _button = 150.0;
  static const _artwork = 196.0;

  /// Repeats, for the ripples and bars.
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// One-off: the burst and artwork entrance on a match.
  late final _found = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// One-off: the shake when nothing was found.
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  /// The level eases toward the latest reading, so ripples don't jump.
  double _level = 0;

  @override
  void initState() {
    super.initState();
    if (widget.state is ListenFound) _found.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(_Stage old) {
    super.didUpdateWidget(old);
    final state = widget.state;
    if (state is ListenFound && old.state is! ListenFound) {
      if (_reduceMotion) {
        _found.value = 1;
      } else {
        unawaited(_found.forward(from: 0));
      }
    }
    if (state is ListenNotFound &&
        old.state is! ListenNotFound &&
        !_reduceMotion) {
      unawaited(_shake.forward(from: 0));
    }
    _syncLoop();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _syncLoop() {
    final listening = widget.state is Listening;
    final duration = Duration(milliseconds: listening ? 1600 : 2400);
    final moving =
        !_reduceMotion &&
        widget.state is! ListenFound &&
        (listening || !widget.calm);
    if (_loop.duration != duration) {
      _loop.duration = duration;
      if (_loop.isAnimating) unawaited(_loop.repeat());
    }
    if (moving && !_loop.isAnimating) {
      unawaited(_loop.repeat());
    } else if (!moving && _loop.isAnimating) {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _found.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final listening = state is Listening;
    return SizedBox.square(
      dimension: _size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _found, _shake]),
        builder: (context, _) {
          final target = state is Listening ? state.level : 0.0;
          _level += (target - _level) * 0.2;
          final shake =
              math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 14;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (state is! ListenFound)
                CustomPaint(
                  size: const Size.square(_size),
                  painter: RipplesPainter(
                    t: _loop.value,
                    level: _level,
                    color: colors.primary,
                    listening: listening,
                    innerRadius: _button / 2,
                  ),
                ),
              if (state is Listening)
                CustomPaint(
                  size: const Size.square(_size),
                  painter: ListenArcPainter(
                    fraction:
                        (state.heard.inMilliseconds /
                                listenCheckpoints.last.inMilliseconds)
                            .clamp(0.0, 1.0),
                    marks: [
                      for (final c in listenCheckpoints.take(
                        listenCheckpoints.length - 1,
                      ))
                        c.inMilliseconds /
                            listenCheckpoints.last.inMilliseconds,
                    ],
                    color: colors.accent,
                    track: colors.line,
                    radius: _button / 2 + 14,
                  ),
                ),
              if (state is ListenFound) ...[
                Transform.scale(
                  scale: Curves.elasticOut.transform(
                    (_found.value / 0.8).clamp(0.0, 1.0),
                  ),
                  child: _Artwork(found: state),
                ),
                CustomPaint(
                  size: const Size.square(_size),
                  painter: BurstPainter(
                    t: _found.value,
                    colors: [colors.primary, colors.accent, colors.tileFg],
                    from: _artwork / 2,
                    ring: colors.primary,
                  ),
                ),
              ] else
                Transform.translate(
                  offset: Offset(shake, 0),
                  child: _Button(
                    state: state,
                    t: _loop.value,
                    level: _level,
                    size: _button,
                    label: listening ? l10n.listenStop : l10n.listenStart,
                    onTap: widget.onTap,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.state,
    required this.t,
    required this.level,
    required this.size,
    required this.label,
    required this.onTap,
  });

  final ListenState state;
  final double t;
  final double level;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final listening = state is Listening;
    final icon = switch (state) {
      ListenNotFound() => Icons.music_off_rounded,
      ListenDenied() || ListenFailed() => Icons.mic_off_rounded,
      _ => Icons.mic_rounded,
    };
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.primary,
        shape: const CircleBorder(),
        elevation: listening ? 10 : 4,
        shadowColor: colors.primary.withValues(alpha: 0.6),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: listening
                    ? LevelBars(
                        key: const ValueKey('bars'),
                        t: t,
                        level: level,
                        color: colors.onPrimary,
                      )
                    : Icon(
                        icon,
                        key: ValueKey(icon),
                        size: 68,
                        color: colors.onPrimary,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.found});

  final ListenFound found;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    const radius = ZemaRadius.large + 4;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: switch (found.track) {
        final track? => TrackArt(
          track: track,
          size: _StageState._artwork,
          radius: radius,
        ),
        null => Container(
          width: _StageState._artwork,
          height: _StageState._artwork,
          decoration: BoxDecoration(
            color: colors.soft,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Icon(
            Icons.lyrics_rounded,
            size: _StageState._artwork / 2.5,
            color: colors.accentText,
          ),
        ),
      },
    );
  }
}

/// The words under the stage, for each state.
class _Words extends ConsumerWidget {
  const _Words({super.key, required this.state, required this.onListen});

  final ListenState state;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = context.zemaColors;
    Widget message(String title, String? body, {Widget? action}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: text.titleLarge, textAlign: TextAlign.center),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body,
            style: text.bodyMedium?.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action],
      ],
    );
    return switch (state) {
      ListenIdle() => message(l10n.listenIdleTitle, l10n.listenIdleMessage),
      ListenLoading() => message(l10n.listenLoading, null),
      Listening(:final heard) => message(switch (_hintStep(heard)) {
        0 => l10n.listenListening,
        1 => l10n.listenHintCloser,
        _ => l10n.listenHintAlmost,
      }, null),
      ListenNotFound() => message(
        l10n.listenNotFoundTitle,
        l10n.listenNotFoundMessage,
        action: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: onListen,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.actionTryAgain),
            ),
            if (ref.watch(quickListenHostProvider) == null)
              OutlinedButton.icon(
                onPressed: () => unawaited(startContribution(context, ref)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.text,
                  side: BorderSide(color: colors.line),
                ),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(l10n.listenAddThisSong),
              ),
          ],
        ),
      ),
      ListenDenied() => message(
        l10n.listenDeniedTitle,
        l10n.listenDeniedMessage,
        action: OutlinedButton(
          onPressed: openAppSettings,
          child: Text(l10n.listenOpenSettings),
        ),
      ),
      ListenNothingToMatch() => message(
        l10n.listenNothingTitle,
        l10n.listenNothingMessage,
      ),
      ListenFailed() => message(
        l10n.listenFailedTitle,
        l10n.listenFailedMessage,
        action: FilledButton.tonalIcon(
          onPressed: onListen,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.actionTryAgain),
        ),
      ),
      final ListenFound found => _Found(found: found, onListen: onListen),
    };
  }
}

class _Found extends ConsumerWidget {
  const _Found({required this.found, required this.onListen});

  final ListenFound found;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = context.zemaColors;
    Future<void> playFromHere() async {
      await playMatch(ref, found);
      if (context.mounted) unawaited(context.push(AppRoutes.nowPlaying));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          found.title,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (found.artist case final artist?) ...[
          const SizedBox(height: 4),
          Text(
            artist,
            style: text.titleSmall?.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 10),
        _LivePosition(found: found),
        if (!found.sure) ...[
          const SizedBox(height: 8),
          Text(
            l10n.listenUnsure,
            style: text.bodySmall?.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            if (ref.watch(quickListenHostProvider) case final host?) ...[
              if (found.toLaunch() case final launch?)
                FilledButton.icon(
                  onPressed: () => unawaited(host.openApp(launch)),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l10n.listenOpenInApp),
                ),
            ] else ...[
              FilledButton.icon(
                onPressed: () =>
                    unawaited(context.push(AppRoutes.listenLyrics)),
                icon: const Icon(Icons.lyrics_rounded),
                label: Text(l10n.listenShowLyrics),
              ),
              if (found.track != null)
                FilledButton.tonalIcon(
                  onPressed: playFromHere,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.listenPlayFromHere),
                ),
            ],
            OutlinedButton.icon(
              onPressed: onListen,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.text,
                side: BorderSide(color: colors.line),
              ),
              icon: const Icon(Icons.mic_rounded),
              label: Text(l10n.listenAgain),
            ),
          ],
        ),
      ],
    );
  }
}

/// "Now at 1:47", ticking each second: where the song is if it kept
/// playing.
class _LivePosition extends StatefulWidget {
  const _LivePosition({required this.found});

  final ListenFound found;

  @override
  State<_LivePosition> createState() => _LivePositionState();
}

class _LivePositionState extends State<_LivePosition> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final end = widget.found.duration;
    var now = widget.found.positionAt(clock.now());
    if (end > Duration.zero && now > end) now = end;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(ZemaRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded, size: 16, color: colors.accentText),
            const SizedBox(width: 6),
            Text(
              l10n.listenNowAt(formatDuration(now)),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.accentText,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How many library songs can be identified; a small progress ring while
/// they're being prepared.
class _LibraryChip extends ConsumerWidget {
  const _LibraryChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progress = ref.watch(libraryFingerprintsProvider);
    final colors = context.zemaColors;
    if (progress.total == 0) return const SizedBox(height: 32);
    final label = switch (progress.left) {
      final left? when progress.running => l10n.listenLibraryReadyLeft(
        progress.ready,
        progress.total,
        left.inMinutes + 1,
      ),
      _ when progress.running => l10n.listenLibraryReady(
        progress.ready,
        progress.total,
      ),
      _ => l10n.listenLibraryAllReady(progress.ready),
    };
    return Material(
      color: colors.surface,
      shape: StadiumBorder(side: BorderSide(color: colors.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (progress.running)
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value:
                        (progress.ready + progress.unreadable) / progress.total,
                    color: colors.accent,
                    backgroundColor: colors.line,
                  ),
                )
              else
                Icon(
                  Icons.library_music_rounded,
                  size: 16,
                  color: colors.accentText,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: colors.text),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.info_outline_rounded, size: 14, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) => unawaited(
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _PreparingDetails(),
    ),
  );
}

/// How preparing the songs goes on this phone: the pace, and what slows it.
class _PreparingDetails extends ConsumerWidget {
  const _PreparingDetails();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(libraryFingerprintsProvider);
    final timings = progress.timings;
    final device = timings.device;
    String seconds(Duration d) =>
        l10n.listenDetailsSeconds((d.inMilliseconds / 1000).toStringAsFixed(1));
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(label, style: text.bodyMedium)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: text.bodyMedium?.copyWith(
                color: colors.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.listenDetailsTitle, style: text.titleLarge),
            const SizedBox(height: 6),
            Text(
              l10n.listenDetailsMessage,
              style: text.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 12),
            row(
              l10n.listenDetailsReady,
              l10n.listenDetailsReadyCount(progress.ready, progress.total),
            ),
            if (progress.unreadable > 0)
              row(l10n.listenDetailsUnreadable, '${progress.unreadable}'),
            if (timings.songs > 0) ...[
              row(l10n.listenDetailsReading, seconds(timings.decodingEach)),
              row(
                l10n.listenDetailsFingerprinting,
                seconds(timings.fingerprintingEach),
              ),
            ],
            row(l10n.listenDetailsAtOnce, '${timings.workers}'),
            if (device != null) ...[
              row(l10n.listenDetailsCores, '${device.cores}'),
              row(
                l10n.listenDetailsBatterySaver,
                device.powerSave ? l10n.listenDetailsOn : l10n.listenDetailsOff,
              ),
            ],
            if (timings.codecs.isNotEmpty)
              row(l10n.listenDetailsDecoder, timings.codecs.join(', ')),
            if (device?.powerSave ?? false) ...[
              const SizedBox(height: 8),
              Text(
                l10n.listenDetailsBatterySaverTip,
                style: text.bodySmall?.copyWith(color: colors.accentText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Privacy extends StatelessWidget {
  const _Privacy({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: colors.muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
