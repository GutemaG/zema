import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/application/sign_in.dart';
import '../features/account/presentation/account_choice_screen.dart';
import '../features/account/presentation/backup_screen.dart';
import '../features/account/presentation/profile_screen.dart';
import '../features/account/presentation/restore_screen.dart';
import '../features/account/presentation/sign_in_screen.dart';
import '../features/lyrics/presentation/song_detail_screen.dart';
import '../features/contribute/presentation/contribute_flow_screen.dart';
import '../features/contribute/presentation/my_contributions_screen.dart';
import '../features/contribute/presentation/review_item_screen.dart';
import '../features/contribute/presentation/review_queue_screen.dart';
import '../features/contribute/presentation/contribute_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/library/application/album_grouping.dart';
import '../features/library/application/play_history.dart';
import '../features/library/presentation/add_songs_screen.dart';
import '../features/library/presentation/album_screen.dart';
import '../features/library/presentation/artist_screen.dart';
import '../features/library/presentation/auto_playlist_screen.dart';
import '../features/library/presentation/folder_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/library/presentation/playlist_screen.dart';
import '../features/player/presentation/now_playing_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/hidden_folders_screen.dart';
import '../features/settings/presentation/hidden_songs_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';
import 'not_found_screen.dart';
import 'routes.dart';

/// The app's router, created once per [ProviderScope].
final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});

/// Builds the route tree. [initialLocation] is overridable for tests.
///
/// Home shows the account choice (S04) instead until it has been made.
GoRouter buildRouter(Ref ref, {String initialLocation = AppRoutes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (_, state) =>
        state.uri.path == AppRoutes.home &&
            ref.read(accountChoicePendingProvider)
        ? AppRoutes.accountChoice
        : null,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.home),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
                routes: _albumAndArtistRoutes(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, _) => const SearchScreen(),
                routes: _albumAndArtistRoutes(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                builder: (_, _) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.folderPath,
                    builder: (_, state) => FolderScreen(
                      path: state.uri.queryParameters['path'] ?? '/',
                    ),
                  ),
                  ..._albumAndArtistRoutes(),
                  GoRoute(
                    path: AppRoutes.playlistPath,
                    builder: (_, state) => PlaylistScreen(
                      id: int.tryParse(state.uri.queryParameters['id'] ?? ''),
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.autoPlaylistPath,
                    builder: (_, state) => AutoPlaylistScreen(
                      kind: AutoPlaylistKind.values
                          .asNameMap()[state.uri.queryParameters['kind']],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.contribute,
                builder: (_, _) => const ContributeScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.hiddenFoldersPath,
            builder: (_, _) => const HiddenFoldersScreen(),
          ),
          GoRoute(
            path: AppRoutes.hiddenSongsPath,
            builder: (_, _) => const HiddenSongsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.accountChoice,
        builder: (_, _) => const AccountChoiceScreen(),
      ),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(path: AppRoutes.backup, builder: (_, _) => const BackupScreen()),
      GoRoute(
        path: AppRoutes.myContributions,
        builder: (_, _) => const MyContributionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reviewQueue,
        builder: (_, _) => const ReviewQueueScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.reviewItemPath,
            builder: (_, state) =>
                ReviewItemScreen(id: state.uri.queryParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.draftPath,
        builder: (_, state) => ContributeFlowScreen(
          id: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.restore,
        builder: (_, _) => const RestoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.addSongsPath,
        builder: (_, state) => AddSongsScreen(
          playlistId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.nowPlaying,
        // Slides up over the tabs and slides back down when closed.
        pageBuilder: (_, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const NowPlayingScreen(),
          transitionsBuilder: (_, animation, _, child) => SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          ),
        ),
      ),
    ],
    errorBuilder: (_, _) => const NotFoundScreen(),
  );
}

/// S12a, S13a and S07, under Home, Search and Library, so a page keeps the
/// tab it was opened from (and, in Search, its results) underneath.
List<RouteBase> _albumAndArtistRoutes() => [
  GoRoute(
    path: AppRoutes.albumPath,
    builder: (_, state) =>
        AlbumScreen(id: AlbumId.fromQuery(state.uri.queryParameters)),
  ),
  GoRoute(
    path: AppRoutes.artistPath,
    builder: (_, state) {
      final query = state.uri.queryParameters;
      return ArtistScreen(name: query['name'], known: query['unknown'] != '1');
    },
  ),
  GoRoute(
    path: AppRoutes.songPath,
    builder: (_, state) =>
        SongDetailScreen(songId: state.uri.queryParameters['id']),
  ),
];
