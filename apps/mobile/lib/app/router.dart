import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});

/// Builds the route tree. [initialLocation] is overridable for tests.
GoRouter buildRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, _) => const SearchScreen(),
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
                  GoRoute(
                    path: AppRoutes.albumPath,
                    builder: (_, state) => AlbumScreen(
                      id: AlbumId.fromQuery(state.uri.queryParameters),
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.artistPath,
                    builder: (_, state) {
                      final query = state.uri.queryParameters;
                      return ArtistScreen(
                        name: query['name'],
                        known: query['unknown'] != '1',
                      );
                    },
                  ),
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
