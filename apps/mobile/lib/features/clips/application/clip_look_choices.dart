import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/clip_colors.dart';
import '../data/clip_encoder.dart';

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

/// How the lyrics move through a clip.
enum ClipLyricsStyle {
  /// The lines stacked, scrolling up as each is sung.
  scroll,

  /// Only the sung line, replaced by the next with a [ClipLineAnimation].
  line,
}

/// How one line gives way to the next in [ClipLyricsStyle.line].
enum ClipLineAnimation {
  rise(ClipMotion.rise),
  fade(ClipMotion.fade),
  zoom(ClipMotion.zoom),
  outIn(ClipMotion.outIn);

  const ClipLineAnimation(this.motion);

  final ClipMotion motion;
}

enum ClipTextSize {
  small(0.8),
  medium(1),
  large(1.2);

  const ClipTextSize(this.scale);

  final double scale;
}

/// Where the sung line sits on the frame: [x] across and [focus] down, each
/// as a part of the frame, kept inside the area the lyrics can use. Lines
/// wrap narrower the further they are from the middle, so they stay on the
/// frame.
@immutable
class ClipTextPosition {
  const ClipTextPosition._(this.x, this.focus);

  /// [x] and [focus] clamped to their ranges.
  factory ClipTextPosition(double x, double focus) => ClipTextPosition._(
    x.clamp(minX, maxX).toDouble(),
    focus.clamp(minFocus, maxFocus).toDouble(),
  );

  static const top = ClipTextPosition._(0.5, 0.32);
  static const center = ClipTextPosition._(0.5, 0.42);
  static const bottom = ClipTextPosition._(0.5, 0.56);
  static const presets = [top, center, bottom];

  static const minX = 0.3;
  static const maxX = 0.7;
  static const minFocus = 0.3;
  static const maxFocus = 0.85;

  final double x;
  final double focus;

  /// This position moved by [dx] and [dy] parts of the frame.
  ClipTextPosition moved(double dx, double dy) =>
      ClipTextPosition(x + dx, focus + dy);

  /// Read back from [toJson], or from the preset name kept before positions
  /// were free; null when [j] is neither.
  static ClipTextPosition? fromJson(Object? j) => switch (j) {
    {'x': final num x, 'y': final num y} => ClipTextPosition(
      x.toDouble(),
      y.toDouble(),
    ),
    'top' => top,
    'center' => center,
    'bottom' => bottom,
    _ => null,
  };

  Map<String, Object?> toJson() => {'x': x, 'y': focus};

  @override
  bool operator ==(Object other) =>
      other is ClipTextPosition && other.x == x && other.focus == focus;

  @override
  int get hashCode => Object.hash(x, focus);
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
    this.style = ClipLyricsStyle.scroll,
    this.animation = ClipLineAnimation.rise,
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
  final ClipLyricsStyle style;
  final ClipLineAnimation animation;

  /// How the video changes from one line to the next.
  ClipMotion get motion => switch (style) {
    ClipLyricsStyle.scroll => ClipMotion.scroll,
    ClipLyricsStyle.line => animation.motion,
  };

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
    ClipLyricsStyle? style,
    ClipLineAnimation? animation,
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
    style: style ?? this.style,
    animation: animation ?? this.animation,
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
    'position': position.toJson(),
    'transliteration': transliteration,
    'showTitle': showTitle,
    'showArtist': showArtist,
    'showAlbum': showAlbum,
    'mark': mark,
    'style': style.name,
    'animation': animation.name,
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
        position:
            ClipTextPosition.fromJson(j['position']) ?? ClipTextPosition.center,
        transliteration: j['transliteration'] == true,
        showTitle: j['showTitle'] != false,
        showArtist: j['showArtist'] != false,
        showAlbum: j['showAlbum'] == true,
        mark: j['mark'] != false,
        style: pick(ClipLyricsStyle.values, j['style'], ClipLyricsStyle.scroll),
        animation: pick(
          ClipLineAnimation.values,
          j['animation'],
          ClipLineAnimation.rise,
        ),
      );
    } on FormatException {
      return const ClipLook();
    }
  }

  Future<void> save(SharedPreferences prefs) =>
      prefs.setString(prefsKey, jsonEncode(toJson()));
}
