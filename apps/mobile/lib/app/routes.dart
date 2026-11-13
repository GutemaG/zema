import '../features/library/application/album_grouping.dart';
import '../features/library/application/play_history.dart';

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

  /// S04, the one-time account choice, shown instead of Home until made.
  static const String accountChoice = '/welcome';

  static const String onboarding = '/onboarding';

  /// S24, above everything; it returns to the screen it was opened from.
  static const String signIn = '/sign-in';

  /// S25, above the shell like Settings, which opens from it.
  static const String profile = '/profile';

  /// S25b, above the shell; opened from Settings and Profile.
  static const String backup = '/backup';

  /// S26, above everything: after a sign-in that found a backup, or from
  /// S25b. It returns to the screen it was opened from.
  static const String restore = '/restore';

  /// S18, above the shell so the mini player doesn't cover its button.
  static const String addSongsPath = '/playlist-add';

  /// S09 for track [id], above the shell.
  static const String songInfoPath = '/song-info';
  static String songInfo(int id) =>
      Uri(path: songInfoPath, queryParameters: {'id': '$id'}).toString();

  /// Listen (intent 009), above the shell; opened from Home.
  static const String listen = '/listen';

  static const String listenLyrics = '/listen/lyrics';
  static const String detectedLyrics = '/detected';

  static const String listenHistory = '/listen/history';

  /// S23, above the shell; opened from S05 and Profile.
  static const String myContributions = '/my-contributions';

  /// S23m, above the shell; moderators open it from S05 and Profile.
  static const String reviewQueue = '/review-queue';
  static const String reviewItemPath = 'item';

  /// S23m's contribution [id].
  static String reviewItem(String id) => Uri(
    path: '$reviewQueue/$reviewItemPath',
    queryParameters: {'id': id},
  ).toString();

  /// The contribution flow (S19–S22) for a draft, above the shell.
  static const String draftPath = '/contribute-draft';

  /// The flow for draft [id], at its step.
  static String draft(int id) =>
      Uri(path: draftPath, queryParameters: {'id': '$id'}).toString();

  /// Sub-paths of [library]; [albumPath] and [artistPath] also of [search].
  static const String folderPath = 'folder';
  static const String albumPath = 'album';
  static const String artistPath = 'artist';
  static const String songPath = 'song';
  static const String playlistPath = 'playlist';
  static const String autoPlaylistPath = 'auto-playlist';

  /// Sub-paths of [settings].
  static const String hiddenFoldersPath = 'hidden-folders';
  static const String hiddenSongsPath = 'hidden-songs';
  static const String hiddenFolders = '$settings/$hiddenFoldersPath';
  static const String hiddenSongs = '$settings/$hiddenSongsPath';
  static const String detectionSettingsPath = 'detection';
  static const String detectionSettings = '$settings/$detectionSettingsPath';

  /// S11a for the folder at [path].
  static String folder(String path) => Uri(
    path: '$library/$folderPath',
    queryParameters: {'path': path},
  ).toString();

  /// S12a for the album [id], inside the tab at [base] (Library or
  /// Search, see [detailBase]).
  static String album(AlbumId id, {String base = library}) =>
      Uri(path: '$base/$albumPath', queryParameters: id.toQuery()).toString();

  /// S13a for the artist [name]; null is "Unknown artist". Inside the tab
  /// at [base], like [album].
  static String artist(String? name, {String base = library}) => Uri(
    path: '$base/$artistPath',
    queryParameters: name == null ? {'unknown': '1'} : {'name': name},
  ).toString();

  /// S07 for the lyrics song [id], inside the tab at [base], like [album].
  static String song(String id, {String base = library}) =>
      Uri(path: '$base/$songPath', queryParameters: {'id': id}).toString();

  /// The tab that album and artist pages opened from [location] belong
  /// to: Search when the user is searching, otherwise Library.
  static String detailBase(String location) =>
      location.startsWith(search) ? search : library;

  /// S17 for the playlist [id].
  static String playlist(int id) => Uri(
    path: '$library/$playlistPath',
    queryParameters: {'id': '$id'},
  ).toString();

  /// The auto playlist [kind].
  static String autoPlaylist(AutoPlaylistKind kind) => Uri(
    path: '$library/$autoPlaylistPath',
    queryParameters: {'kind': kind.name},
  ).toString();

  /// S18, adding songs to the playlist [id].
  static String addSongs(int id) =>
      Uri(path: addSongsPath, queryParameters: {'id': '$id'}).toString();
}
