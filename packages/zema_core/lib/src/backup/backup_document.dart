import 'dart:convert';

import '../failures.dart';
import 'track_identity.dart';

/// The backup format this app writes, and the newest it reads.
const backupFormat = 1;

/// A favorite song and when it was added.
class BackupFavorite {
  const BackupFavorite({required this.track, required this.addedAt});

  final TrackIdentity track;
  final DateTime addedAt;

  @override
  bool operator ==(Object other) =>
      other is BackupFavorite &&
      other.track == track &&
      other.addedAt == addedAt;

  @override
  int get hashCode => Object.hash(track, addedAt);
}

/// A playlist with its songs in order.
class BackupPlaylist {
  const BackupPlaylist({
    required this.name,
    required this.tracks,
    this.description,
    this.createdAt,
  });

  final String name;
  final String? description;
  final DateTime? createdAt;
  final List<TrackIdentity> tracks;

  @override
  bool operator ==(Object other) =>
      other is BackupPlaylist &&
      other.name == name &&
      other.description == description &&
      other.createdAt == createdAt &&
      _listEquals(other.tracks, tracks);

  @override
  int get hashCode =>
      Object.hash(name, description, createdAt, Object.hashAll(tracks));
}

/// Lyrics chosen by hand for a track: the lyrics song [songId], or null for
/// "no lyrics".
class BackupLyricsChoice {
  const BackupLyricsChoice({required this.track, this.songId});

  final TrackIdentity track;
  final String? songId;

  @override
  bool operator ==(Object other) =>
      other is BackupLyricsChoice &&
      other.track == track &&
      other.songId == songId;

  @override
  int get hashCode => Object.hash(track, songId);
}

/// The user's library data and settings, as one versioned JSON document.
///
/// Tracks are [TrackIdentity]s. In the JSON they are written once, in
/// `tracks`, and the sections refer to them by index. Sections a newer app
/// added are kept in [extras] and written back unchanged; unknown fields
/// inside an entry are ignored. Dates are stored in UTC.
class BackupDocument {
  const BackupDocument({
    required this.createdAt,
    this.favorites = const [],
    this.playlists = const [],
    this.lyricsChoices = const [],
    this.hiddenFolders = const [],
    this.hiddenTracks = const [],
    this.settings = const {},
    this.extras = const {},
  });

  /// Reads [toJson]'s output. Throws [BackupFormatFailure] when it is
  /// malformed or its format is newer than [backupFormat].
  factory BackupDocument.fromJson(Map<String, Object?> json) {
    final format = json['format'];
    if (format is! int || format < 1) {
      throw BackupFormatFailure('Backup has no valid format: $format');
    }
    if (format > backupFormat) {
      throw BackupFormatFailure(
        'Backup format $format is newer than $backupFormat',
        newerFormat: true,
      );
    }
    try {
      final tracks = [
        for (final track in _list(json['tracks']))
          TrackIdentity.fromJson(_map(track)),
      ];
      TrackIdentity trackAt(Object? index) => tracks[(index! as num).toInt()];
      return BackupDocument(
        createdAt: DateTime.parse(json['createdAt']! as String),
        favorites: [
          for (final entry in _list(json['favorites']).map(_map))
            BackupFavorite(
              track: trackAt(entry['track']),
              addedAt: DateTime.parse(entry['addedAt']! as String),
            ),
        ],
        playlists: [
          for (final entry in _list(json['playlists']).map(_map))
            BackupPlaylist(
              name: entry['name']! as String,
              description: entry['description'] as String?,
              createdAt: switch (entry['createdAt']) {
                final String date => DateTime.parse(date),
                _ => null,
              },
              tracks: [for (final i in _list(entry['tracks'])) trackAt(i)],
            ),
        ],
        lyricsChoices: [
          for (final entry in _list(json['lyricsChoices']).map(_map))
            BackupLyricsChoice(
              track: trackAt(entry['track']),
              songId: entry['songId'] as String?,
            ),
        ],
        hiddenFolders: [
          for (final folder in _list(json['hiddenFolders'])) folder! as String,
        ],
        hiddenTracks: [for (final i in _list(json['hiddenTracks'])) trackAt(i)],
        settings: switch (json['settings']) {
          null => const {},
          final Object settings => Map.unmodifiable(_map(settings)),
        },
        extras: Map.unmodifiable({
          for (final MapEntry(:key, :value) in json.entries)
            if (!_knownKeys.contains(key)) key: value,
        }),
      );
    } on BackupFormatFailure {
      rethrow;
    } on Object catch (e) {
      // A wrong type, a missing field, a bad date or a track index out of
      // range.
      throw BackupFormatFailure('Backup is malformed: $e', cause: e);
    }
  }

  /// Reads [encode]'s output (see [BackupDocument.fromJson]).
  factory BackupDocument.decode(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw BackupFormatFailure('Backup is not JSON: $e', cause: e);
    }
    if (json is! Map<String, Object?>) {
      throw const BackupFormatFailure('Backup is not a JSON object');
    }
    return BackupDocument.fromJson(json);
  }

  static const _knownKeys = {
    'format',
    'createdAt',
    'tracks',
    'favorites',
    'playlists',
    'lyricsChoices',
    'hiddenFolders',
    'hiddenTracks',
    'settings',
  };

  /// Always [backupFormat]: an older document is upgraded when read.
  int get format => backupFormat;

  final DateTime createdAt;
  final List<BackupFavorite> favorites;
  final List<BackupPlaylist> playlists;
  final List<BackupLyricsChoice> lyricsChoices;

  /// Folder paths relative to their storage volume, e.g. `Recordings`.
  final List<String> hiddenFolders;
  final List<TrackIdentity> hiddenTracks;

  /// The app's settings as plain JSON values, keyed by name. The app knows
  /// the keys; unknown ones are kept.
  final Map<String, Object?> settings;

  /// Top-level sections this app doesn't know, from a newer app.
  final Map<String, Object?> extras;

  Map<String, Object?> toJson() {
    final tracks = <TrackIdentity, int>{};
    int indexOf(TrackIdentity track) =>
        tracks.putIfAbsent(track, () => tracks.length);
    final sections = <String, Object?>{
      'favorites': [
        for (final favorite in favorites)
          {
            'track': indexOf(favorite.track),
            'addedAt': _date(favorite.addedAt),
          },
      ],
      'playlists': [
        for (final playlist in playlists)
          {
            'name': playlist.name,
            'description': ?playlist.description,
            if (playlist.createdAt case final createdAt?)
              'createdAt': _date(createdAt),
            'tracks': [for (final track in playlist.tracks) indexOf(track)],
          },
      ],
      'lyricsChoices': [
        for (final choice in lyricsChoices)
          {'track': indexOf(choice.track), 'songId': choice.songId},
      ],
      'hiddenFolders': hiddenFolders,
      'hiddenTracks': [for (final track in hiddenTracks) indexOf(track)],
      'settings': settings,
    };
    return {
      ...extras,
      'format': format,
      'createdAt': _date(createdAt),
      'tracks': [for (final track in tracks.keys) track.toJson()],
      ...sections,
    };
  }

  /// [toJson] as compact JSON text.
  String encode() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is BackupDocument &&
      other.createdAt == createdAt &&
      _listEquals(other.favorites, favorites) &&
      _listEquals(other.playlists, playlists) &&
      _listEquals(other.lyricsChoices, lyricsChoices) &&
      _listEquals(other.hiddenFolders, hiddenFolders) &&
      _listEquals(other.hiddenTracks, hiddenTracks) &&
      _jsonEquals(other.settings, settings) &&
      _jsonEquals(other.extras, extras);

  @override
  int get hashCode => Object.hash(
    createdAt,
    Object.hashAll(favorites),
    Object.hashAll(playlists),
    Object.hashAll(lyricsChoices),
    Object.hashAll(hiddenFolders),
    Object.hashAll(hiddenTracks),
    settings.length,
    extras.length,
  );

  @override
  String toString() =>
      'BackupDocument(${favorites.length} favorites, '
      '${playlists.length} playlists, ${lyricsChoices.length} choices)';
}

String _date(DateTime date) => date.toUtc().toIso8601String();

List<Object?> _list(Object? value) => switch (value) {
  null => const [],
  final List<Object?> list => list,
  _ => throw FormatException('Expected a list: $value'),
};

Map<String, Object?> _map(Object? value) => switch (value) {
  final Map<String, Object?> map => map,
  _ => throw FormatException('Expected an object: $value'),
};

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Deep equality of decoded JSON values.
bool _jsonEquals(Object? a, Object? b) => switch ((a, b)) {
  (final Map<Object?, Object?> a, final Map<Object?, Object?> b) =>
    a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && _jsonEquals(a[k], b[k])),
  (final List<Object?> a, final List<Object?> b) =>
    a.length == b.length &&
        Iterable<int>.generate(a.length).every((i) => _jsonEquals(a[i], b[i])),
  _ => a == b,
};
