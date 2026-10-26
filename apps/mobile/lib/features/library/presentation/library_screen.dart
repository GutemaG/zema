import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/tab_page.dart';
import '../application/library_tab_request.dart';
import 'albums_view.dart';
import 'artists_view.dart';
import 'favorites_view.dart';
import 'folders_view.dart';
import 'library_access_gate.dart';
import 'playlists_view.dart';
import 'tracks_view.dart';

/// The Library tab: audio access first, then the phone's tracks.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPage(
      title: AppLocalizations.of(context).navLibrary,
      child: const LibraryAccessGate(child: _LibraryTabs()),
    );
  }
}

/// The top tabs. Opens on the tab Home asked for ([libraryTabRequestProvider]),
/// and switches to it when asked again.
class _LibraryTabs extends ConsumerStatefulWidget {
  const _LibraryTabs();

  @override
  ConsumerState<_LibraryTabs> createState() => _LibraryTabsState();
}

class _LibraryTabsState extends ConsumerState<_LibraryTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: LibraryTab.values.length,
    initialIndex: ref.read(libraryTabRequestProvider)?.tab.index ?? 0,
    vsync: this,
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    ref.listen(libraryTabRequestProvider, (_, request) {
      if (request == null) return;
      // The request comes while the Library tab is still off screen, where
      // its tab bar has no size to scroll; switch once it is shown.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabs.index = request.tab.index;
      });
    });
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          labelColor: colors.primaryText,
          unselectedLabelColor: colors.muted,
          indicatorColor: colors.primary,
          dividerColor: colors.line,
          tabs: [
            Tab(text: l10n.libraryTabTracks),
            Tab(text: l10n.libraryTabFolders),
            Tab(text: l10n.libraryTabAlbums),
            Tab(text: l10n.libraryTabArtists),
            Tab(text: l10n.libraryTabFavorites),
            Tab(text: l10n.libraryTabPlaylists),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              TracksView(),
              FoldersView(),
              AlbumsView(),
              ArtistsView(),
              FavoritesView(),
              PlaylistsView(),
            ],
          ),
        ),
      ],
    );
  }
}
