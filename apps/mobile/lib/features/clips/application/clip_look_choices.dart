import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/clip_colors.dart';

/// What fills a clip's background.
enum ClipBackground {
  /// A gradient from the cover's main colour, or one picked by title.
  song,

  /// The cover art, blurred.
  cover,

  /// A photo from the gallery.
  photo,

  /// One of [clipPlainColors].
  color,
}

enum ClipTextSize {
  small(0.8),
  medium(1),
  large(1.2);

  const ClipTextSize(this.scale);

  final double scale;
}

enum ClipTextPosition {
  top(0.32),
  center(0.42),
  bottom(0.56);

  const ClipTextPosition(this.focus);

  /// Where the sung line sits, as a part of the height.
  final double focus;
}

const _keep = Object();

/// The user's choices for a clip's look. Every one has a default, so a clip
/// can be made without touching them.
class ClipLook {
  const ClipLook({
    this.background = ClipBackground.song,
    this.photo,
    this.color = 0,
    this.dim,
    this.textSize = ClipTextSize.medium,
    this.textColor = 0,
    this.position = ClipTextPosition.center,
    this.transliteration = false,
    this.showTitle = true,
    this.showArtist = true,
    this.showAlbum = false,
    this.title,
    this.artist,
    this.album,
    this.albumPicture,
    this.artistPicture,
    this.mark = true,
  });

  final ClipBackground background;

  /// The gallery photo's path for [ClipBackground.photo].
  final String? photo;

  /// Index into [clipPlainColors] for [ClipBackground.color].
  final int color;

  /// How much the background is darkened behind the text, 0 to [maxDim];
  /// null for [defaultDim].
  final double? dim;
  final ClipTextSize textSize;

  /// Index into [clipTextColors].
  final int textColor;
  final ClipTextPosition position;

  /// Whether each line's transliteration shows below it.
  final bool transliteration;
  final bool showTitle;
  final bool showArtist;
  final bool showAlbum;

  /// Names edited for this clip; null for the track's own.
  final String? title;
  final String? artist;
  final String? album;

  /// A gallery photo shown as the album picture; null for the cover art.
  final String? albumPicture;

  /// A gallery photo shown round next to the names; null for none.
  final String? artistPicture;

  /// Whether the small Zema mark shows in the top corner.
  final bool mark;

  static const maxDim = 0.8;

  /// No dimming for colours; 40 % behind pictures.
  double get defaultDim => switch (background) {
    ClipBackground.song || ClipBackground.color => 0,
    ClipBackground.cover || ClipBackground.photo => 0.4,
  };

  double get effectiveDim => dim ?? defaultDim;

  ClipLook copyWith({
    ClipBackground? background,
    Object? photo = _keep,
    int? color,
    Object? dim = _keep,
    ClipTextSize? textSize,
    int? textColor,
    ClipTextPosition? position,
    bool? transliteration,
    bool? showTitle,
    bool? showArtist,
    bool? showAlbum,
    Object? title = _keep,
    Object? artist = _keep,
    Object? album = _keep,
    Object? albumPicture = _keep,
    Object? artistPicture = _keep,
    bool? mark,
  }) => ClipLook(
    background: background ?? this.background,
    photo: photo == _keep ? this.photo : photo as String?,
    color: color ?? this.color,
    dim: dim == _keep ? this.dim : dim as double?,
    textSize: textSize ?? this.textSize,
    textColor: textColor ?? this.textColor,
    position: position ?? this.position,
    transliteration: transliteration ?? this.transliteration,
    showTitle: showTitle ?? this.showTitle,
    showArtist: showArtist ?? this.showArtist,
    showAlbum: showAlbum ?? this.showAlbum,
    title: title == _keep ? this.title : title as String?,
    artist: artist == _keep ? this.artist : artist as String?,
    album: album == _keep ? this.album : album as String?,
    albumPicture: albumPicture == _keep
        ? this.albumPicture
        : albumPicture as String?,
    artistPicture: artistPicture == _keep
        ? this.artistPicture
        : artistPicture as String?,
    mark: mark ?? this.mark,
  );

  static const prefsKey = 'clipLook';

  /// The choices kept for the next clip: not photos or edited names; a
  /// photo background comes back as the song's colours.
  Map<String, Object?> toJson() => {
    'background':
        (background == ClipBackground.photo ? ClipBackground.song : background)
            .name,
    'color': color,
    'dim': dim,
    'textSize': textSize.name,
    'textColor': textColor,
    'position': position.name,
    'transliteration': transliteration,
    'showTitle': showTitle,
    'showArtist': showArtist,
    'showAlbum': showAlbum,
    'mark': mark,
  };

  /// The last kept choices, or the defaults for anything missing or bad.
  static ClipLook fromPrefs(SharedPreferences prefs) {
    final raw = prefs.getString(prefsKey);
    if (raw == null) return const ClipLook();
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, Object?>) return const ClipLook();
      T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
          values.where((v) => v.name == name).firstOrNull ?? fallback;
      int index(Object? i, int length) =>
          i is int && i >= 0 && i < length ? i : 0;
      final dim = switch (j['dim']) {
        final num d => d.toDouble(),
        _ => null,
      };
      return ClipLook(
        background: pick(
          ClipBackground.values,
          j['background'],
          ClipBackground.song,
        ),
        color: index(j['color'], clipPlainColors.length),
        dim: dim?.clamp(0, maxDim),
        textSize: pick(ClipTextSize.values, j['textSize'], ClipTextSize.medium),
        textColor: index(j['textColor'], clipTextColors.length),
        position: pick(
          ClipTextPosition.values,
          j['position'],
          ClipTextPosition.center,
        ),
        transliteration: j['transliteration'] == true,
        showTitle: j['showTitle'] != false,
        showArtist: j['showArtist'] != false,
        showAlbum: j['showAlbum'] == true,
        mark: j['mark'] != false,
      );
    } on FormatException {
      return const ClipLook();
    }
  }

  Future<void> save(SharedPreferences prefs) =>
      prefs.setString(prefsKey, jsonEncode(toJson()));
}
