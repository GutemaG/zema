import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/library/application/library_sync_controller.dart';
import '../features/library/application/play_history.dart';
import '../features/player/application/player_providers.dart';
import '../features/player/presentation/mini_player.dart';
import '../l10n/generated/app_localizations.dart';
import 'zema_nav_bar.dart';

/// The main app frame: the current tab above the bottom navigation.
///
/// Each tab is a branch of a stateful shell route, so switching tabs keeps
/// their state and scroll position.
///
/// The shell also keeps the library sync and the player session (restore and
/// autosave of the queue) running from app start, shows the mini player above
/// the navigation, and reports songs that couldn't be played.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listening (not watching) keeps these alive without rebuilding.
    ref.listen(librarySyncProvider, (_, _) {});
    ref.listen(playerSessionProvider, (_, _) {});
    ref.listen(playbackOptionsSyncProvider, (_, _) {});
    ref.listen(playHistoryProvider, (_, _) {});
    final l10n = AppLocalizations.of(context);
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
