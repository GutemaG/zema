import '../features/library/application/album_grouping.dart';

/// Route paths. The four tabs are branches of the shell; Settings and Now
/// Playing open above it. Library detail pages open inside the Library
/// branch, so the navigation bar and mini player stay visible.
abstract final class AppRoutes {
  static const String home = '/home';
  static const String search = '/search';
  static const String library = '/library';
  static const String contribute = '/contribute';
  static const String settings = '/settings';
  static const String nowPlaying = '/now-playing';

  /// Sub-paths of [library].
  static const String folderPath = 'folder';
  static const String albumPath = 'album';
  static const String artistPath = 'artist';

  /// S11a for the folder at [path].
  static String folder(String path) => Uri(
    path: '$library/$folderPath',
    queryParameters: {'path': path},
  ).toString();

  /// S12a for the album [id].
  static String album(AlbumId id) => Uri(
    path: '$library/$albumPath',
    queryParameters: id.toQuery(),
  ).toString();

  /// S13a for the artist [name]; null is "Unknown artist".
  static String artist(String? name) => Uri(
    path: '$library/$artistPath',
    queryParameters: name == null ? {'unknown': '1'} : {'name': name},
  ).toString();
}
