import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../features/identify/application/track_sound_links.dart';
import '../features/detection/application/detected_song.dart';
import '../features/detection/application/lyrics_overlay_sync.dart';
import '../features/detection/presentation/choose_detected_song_sheet.dart';
import '../features/account/application/account_providers.dart';
import '../features/contribute/application/my_contributions.dart';
import '../features/contribute/application/recording.dart';
import '../features/contribute/presentation/my_contributions_screen.dart';
import '../features/contribute/data/shared_audio.dart';
import '../features/identify/application/listen_controller.dart';
import '../features/identify/application/offline_catalog.dart';
import '../features/identify/application/pending_lookups.dart';
import '../features/identify/application/quick_listen.dart';
import '../features/identify/application/shared_fingerprints.dart';
import '../features/identify/data/quick_launch.dart';
import '../features/library/application/library_providers.dart';
import '../features/library/application/library_sync_controller.dart';
import '../features/library/application/play_history.dart';
import '../features/catalog/application/catalog_index.dart';
import '../features/catalog/application/report_sender.dart';
import '../features/lyrics/application/lyrics_links.dart';
import '../features/player/application/player_providers.dart';
import '../features/player/presentation/mini_player.dart';
import '../l10n/generated/app_localizations.dart';
import 'routes.dart';
import 'zema_nav_bar.dart';

/// The main app frame: the current tab above the bottom navigation.
///
/// Each tab is a branch of a stateful shell route, so switching tabs keeps
/// their state and scroll position.
///
/// The shell also keeps the library sync and the player session (restore and
/// autosave of the queue) running from app start, shows the mini player above
/// the navigation, and reports songs that couldn't be played. An audio file
/// shared to Zema starts a contribution with it (after C09 for a guest), and
/// a message tells about each contribution reviewed since the last check.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int homeIndex = 0;

  void _select(int index) {
    // Tapping the active tab again pops it back to its root screen.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  static Future<void> _contributeShared(
    BuildContext context,
    WidgetRef ref,
    SharedAudio audio,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!ref.read(accountsAvailableProvider)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contributeShareNeedsBackend)));
      return deleteSharedAudio(audio.path);
    }
    final id = await startSharedDraft(ref, audio);
    if (context.mounted) await context.push<void>(AppRoutes.draft(id));
  }

  static Future<void> _openLaunch(
    BuildContext context,
    WidgetRef ref,
    LaunchRequest request,
  ) async {
    switch (request) {
      case OpenListenHistory():
        await context.push<void>(AppRoutes.listenHistory);
      case final OpenListenMatch match:
        final tracks = await ref.read(libraryTracksProvider.future);
        final track = tracks.where((t) => t.id == match.trackId).firstOrNull;
        if (track == null || !context.mounted) return;
        ref
            .read(pendingMatchProvider.notifier)
            .set(
              ListenFound(
                track: track,
                match: AudioMatch(
                  recordingId: '${track.id}',
                  position: match.position,
                  score: match.score,
                  playbackSpeed: match.speed,
                  ambiguousPosition: !match.sure,
                ),
                startedAt: match.startedAt,
                sure: match.sure,
              ),
            );
        await context.push<void>(AppRoutes.listen);
      case OpenKeepListening():
        final to = ref.read(listenControllerProvider) is ListenFound
            ? AppRoutes.listenLyrics
            : AppRoutes.listen;
        final at = GoRouter.of(context)
            .routerDelegate
            .currentConfiguration
            .uri
            .path;
        if (at != to) await context.push<void>(to);
      case OpenSong(:final songId):
        await context.push<void>(AppRoutes.song(songId));
      case OpenDetected(:final key, :final ask):
        final detected = await _detected(ref, key);
        if (detected == null || !context.mounted) return;
        switch (ask) {
          case DetectedAsk.choose:
            await showChooseDetectedSongSheet(context, detected);
          case DetectedAsk.listen:
            ref.read(listeningForProvider.notifier).set(detected.playback);
            await context.push<void>(AppRoutes.listen);
        }
    }
  }

  static Future<DetectedSong?> _detected(WidgetRef ref, String key) async {
    for (var i = 0; i < 30; i++) {
      final song = ref.read(detectedSongProvider);
      if (song != null && song.key == key) return song;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(incomingLaunchesProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        unawaited(_openLaunch(context, ref, value));
      }
    });
    ref.listen(homeWidgetSyncProvider, (_, _) {});
    ref.listen(listenedMatchSyncProvider, (_, _) {});
    ref.listen(lyricsOverlaySyncProvider, (_, _) {});
    ref.listen(incomingSharesProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        unawaited(_contributeShared(context, ref, value));
      }
    });
    // Listening (not watching) keeps these alive without rebuilding.
    ref.listen(librarySyncProvider, (_, _) {});
    ref.listen(playerSessionProvider, (_, _) {});
    ref.listen(playbackOptionsSyncProvider, (_, _) {});
    ref.listen(playHistoryProvider, (_, _) {});
    ref.listen(catalogStartupRefreshProvider, (_, _) {});
    ref.listen(reportStartupFlushProvider, (_, _) {});
    ref.listen(pendingLookupFlushProvider, (_, _) {});
    ref.listen(fingerprintShareSyncProvider, (_, _) {});
    ref.listen(trackPrintShareSyncProvider, (_, _) {});
    ref.listen(offlineCatalogUpdatesProvider, (_, _) {});
    ref.listen(askShareFingerprintsProvider, (_, next) {
      if (next case AsyncData(value: true)) {
        unawaited(_askShareFingerprints(context, ref));
      }
    });
    ref.listen(lyricsLinkSyncProvider, (_, _) {});
    ref.listen(soundLinkSyncProvider, (_, _) {});
    ref.listen(myContributionsProvider, (_, _) {});
    final l10n = AppLocalizations.of(context);
    ref.listen(contributionChangesProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        final messenger = ScaffoldMessenger.of(context);
        for (final c in value) {
          final title = contributionTitle(ref, c);
          messenger.showSnackBar(
            SnackBar(
              content: Text(switch (c.status) {
                ContributionStatus.approved => l10n.contributionApprovedMessage(
                  title,
                ),
                ContributionStatus.rejected => l10n.contributionRejectedMessage(
                  title,
                ),
                _ => l10n.contributionNeedsChangesMessage(title),
              }),
              action: SnackBarAction(
                label: l10n.actionView,
                onPressed: () => context.push(AppRoutes.myContributions),
              ),
            ),
          );
        }
      }
    });
    ref.listen(lateMatchFoundProvider, (_, next) {
      if (next case AsyncData(value: final song)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listenFoundLater(song.title)),
            action: SnackBarAction(
              label: l10n.actionView,
              onPressed: () => context.push(AppRoutes.listenHistory),
            ),
          ),
        );
      }
    });
    ref.listen(unplayableTrackProvider, (_, next) {
      if (next case AsyncData(value: SkippedTrack(:final track))) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.playerUnplayable(track.title))),
          );
      }
    });
    final onHome = navigationShell.currentIndex == homeIndex;
    return PopScope(
      // Back on another tab's root goes to Home; back on Home exits.
      canPop: onHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          navigationShell.goBranch(homeIndex);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            ZemaNavBar(
              selectedIndex: navigationShell.currentIndex,
              onSelected: _select,
              items: [
                ZemaNavItem(icon: Icons.home_outlined, label: l10n.navHome),
                ZemaNavItem(icon: Icons.search, label: l10n.navSearch),
                ZemaNavItem(
                  icon: Icons.library_music_outlined,
                  label: l10n.navLibrary,
                ),
                ZemaNavItem(
                  icon: Icons.edit_outlined,
                  label: l10n.navContribute,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks once whether to share library fingerprints (intent 009, FR-2).
Future<void> _askShareFingerprints(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final share = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.shareFingerprintsTitle),
      content: Text(l10n.shareFingerprintsMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.shareFingerprintsNo),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.shareFingerprintsYes),
        ),
      ],
    ),
  );
  await ref.read(shareFingerprintsProvider.notifier).set(share ?? false);
}
