import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Library tab's top tabs, in order.
enum LibraryTab { tracks, folders, albums, artists, favorites, playlists }

/// A request from outside the Library (Home's quick actions) to show one of
/// its tabs. Each request is a new object, so asking for the same tab twice
/// still switches back to it.
class LibraryTabRequest {
  LibraryTabRequest(this.tab);

  final LibraryTab tab;
}

final libraryTabRequestProvider =
    NotifierProvider<LibraryTabRequests, LibraryTabRequest?>(
      LibraryTabRequests.new,
    );

class LibraryTabRequests extends Notifier<LibraryTabRequest?> {
  @override
  LibraryTabRequest? build() => null;

  void open(LibraryTab tab) => state = LibraryTabRequest(tab);
}
