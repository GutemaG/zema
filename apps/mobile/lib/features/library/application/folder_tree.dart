import 'package:zema_core/zema_core.dart';

/// Which kind of storage a folder is on; the UI names the root after it.
enum StorageKind { phone, sdCard }

/// A folder's storage root and its path below that root.
class FolderLocation {
  const FolderLocation({
    required this.root,
    required this.kind,
    required this.segments,
  });

  /// The volume's path, e.g. `/storage/emulated/0`.
  final String root;
  final StorageKind kind;

  /// Folder names from the root down; empty for the root itself.
  final List<String> segments;

  /// Paths from the root down to the folder, one per breadcrumb segment
  /// (the root first).
  List<String> get breadcrumb => [
    root,
    for (var i = 1; i <= segments.length; i++) _join(root, segments.take(i)),
  ];
}

final _phoneRoot = RegExp(r'^/storage/emulated/\d+');
final _volumeRoot = RegExp(r'^/storage/[^/]+');

/// Where [folder] sits: internal storage (`/storage/emulated/<n>`) is the
/// phone, any other `/storage/<id>` volume an SD card. Paths outside
/// `/storage` are treated as phone storage rooted at `/`.
FolderLocation locateFolder(String folder) {
  final String root;
  final StorageKind kind;
  if (_phoneRoot.firstMatch(folder) case final match?) {
    root = match[0]!;
    kind = StorageKind.phone;
  } else if (_volumeRoot.firstMatch(folder) case final match?
      when match[0] != '/storage/emulated' && match[0] != '/storage/self') {
    root = match[0]!;
    kind = StorageKind.sdCard;
  } else {
    root = '/';
    kind = StorageKind.phone;
  }
  final rest = folder.substring(root == '/' ? 0 : root.length);
  return FolderLocation(
    root: root,
    kind: kind,
    segments: [
      for (final s in rest.split('/'))
        if (s.isNotEmpty) s,
    ],
  );
}

String _join(String root, Iterable<String> segments) =>
    root == '/' ? '/${segments.join('/')}' : '$root/${segments.join('/')}';

/// A folder in a list: its path, its own name, and how many songs it holds
/// (directly in S11; including all subfolders in S11a).
class FolderEntry {
  const FolderEntry({
    required this.path,
    required this.name,
    required this.songCount,
  });

  final String path;
  final String name;
  final int songCount;

  @override
  bool operator ==(Object other) =>
      other is FolderEntry &&
      other.path == path &&
      other.name == name &&
      other.songCount == songCount;

  @override
  int get hashCode => Object.hash(path, name, songCount);

  @override
  String toString() => 'FolderEntry($path, $songCount)';
}

/// What's inside one folder: subfolders first, then its own songs.
class FolderContents {
  const FolderContents({required this.subfolders, required this.tracks});

  /// Direct subfolders that have songs somewhere below them, by name.
  final List<FolderEntry> subfolders;

  /// Songs directly in the folder, by title.
  final List<Track> tracks;

  bool get isEmpty => subfolders.isEmpty && tracks.isEmpty;

  /// Every song in the folder and below it.
  int get totalCount =>
      tracks.length + subfolders.fold(0, (sum, f) => sum + f.songCount);
}

/// The folders of the visible tracks, derived from their paths.
class FolderIndex {
  FolderIndex._(this._byFolder);

  factory FolderIndex.from(List<Track> tracks) {
    final byFolder = <String, List<Track>>{};
    for (final track in tracks) {
      (byFolder[track.folder] ??= []).add(track);
    }
    for (final list in byFolder.values) {
      list.sort(_byTitle);
    }
    return FolderIndex._(byFolder);
  }

  final Map<String, List<Track>> _byFolder;

  /// Folders that directly contain songs, by name (then path).
  late final List<FolderEntry> folders = [
    for (final MapEntry(key: path, value: tracks) in _byFolder.entries)
      FolderEntry(path: path, name: _nameOf(path), songCount: tracks.length),
  ]..sort(_byName);

  /// The subfolders and songs of [path]. Empty when nothing visible is
  /// there (e.g. the folder was hidden).
  FolderContents contentsOf(String path) {
    final prefix = path == '/' ? '/' : '$path/';
    final counts = <String, int>{};
    for (final MapEntry(key: folder, value: tracks) in _byFolder.entries) {
      if (!folder.startsWith(prefix) || folder.length == prefix.length) {
        continue;
      }
      final slash = folder.indexOf('/', prefix.length);
      final child = slash < 0 ? folder : folder.substring(0, slash);
      counts[child] = (counts[child] ?? 0) + tracks.length;
    }
    return FolderContents(
      subfolders: [
        for (final MapEntry(key: child, value: count) in counts.entries)
          FolderEntry(path: child, name: _nameOf(child), songCount: count),
      ]..sort(_byName),
      tracks: _byFolder[path] ?? const [],
    );
  }

  /// Every song in [path] and below it: its own songs first, then each
  /// subfolder's, in the order S11a lists them.
  List<Track> tracksUnder(String path) {
    final contents = contentsOf(path);
    return [
      ...contents.tracks,
      for (final sub in contents.subfolders) ...tracksUnder(sub.path),
    ];
  }

  static String _nameOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash < 0 ? path : path.substring(slash + 1);
  }

  static int _byName(FolderEntry a, FolderEntry b) {
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName != 0 ? byName : a.path.compareTo(b.path);
  }

  static int _byTitle(Track a, Track b) {
    final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
  }
}
