import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('detection.overlay');

@immutable
class OverlayLine {
  const OverlayLine(this.text, {this.at});

  final String text;
  final Duration? at;

  Map<String, Object?> toMap() => {'text': text, 'atMs': ?at?.inMilliseconds};

  @override
  bool operator ==(Object other) =>
      other is OverlayLine && other.text == text && other.at == at;

  @override
  int get hashCode => Object.hash(text, at);

  @override
  String toString() => 'OverlayLine($at $text)';
}

sealed class OverlayContent {
  const OverlayContent({required this.key, required this.source});

  final String key;
  final String source;

  Map<String, Object?> toMap();
}

@immutable
class OverlaySheet extends OverlayContent {
  const OverlaySheet({
    required super.key,
    required super.source,
    required this.songId,
    required this.title,
    required this.lines,
    this.artist,
    this.offset = Duration.zero,
    this.failed = false,
  });

  final String songId;
  final String title;
  final String? artist;
  final List<OverlayLine> lines;
  final Duration offset;
  final bool failed;

  @override
  Map<String, Object?> toMap() => {
    'kind': 'lyrics',
    'key': key,
    'source': source,
    'songId': songId,
    'title': title,
    'artist': ?artist,
    'offsetMs': offset.inMilliseconds,
    'failed': failed,
    'lines': [for (final line in lines) line.toMap()],
  };

  @override
  bool operator ==(Object other) =>
      other is OverlaySheet &&
      other.key == key &&
      other.source == source &&
      other.songId == songId &&
      other.title == title &&
      other.artist == artist &&
      other.offset == offset &&
      other.failed == failed &&
      listEquals(other.lines, lines);

  @override
  int get hashCode => Object.hash(
    key,
    source,
    songId,
    title,
    artist,
    offset,
    failed,
    Object.hashAll(lines),
  );

  @override
  String toString() => 'OverlaySheet($songId for $key, ${lines.length} lines)';
}

@immutable
class OverlayQuestion extends OverlayContent {
  const OverlayQuestion({
    required super.key,
    required super.source,
    required this.songId,
    required this.title,
    this.artist,
  });

  final String songId;
  final String title;
  final String? artist;

  @override
  Map<String, Object?> toMap() => {
    'kind': 'question',
    'key': key,
    'source': source,
    'songId': songId,
    'title': title,
    'artist': ?artist,
  };

  @override
  bool operator ==(Object other) =>
      other is OverlayQuestion &&
      other.key == key &&
      other.source == source &&
      other.songId == songId &&
      other.title == title &&
      other.artist == artist;

  @override
  int get hashCode => Object.hash(key, source, songId, title, artist);

  @override
  String toString() => 'OverlayQuestion($songId for $key)';
}

sealed class OverlayAction {
  const OverlayAction(this.key);

  final String key;

  static OverlayAction? fromMap(Object? value) {
    if (value is! Map) return null;
    final key = value['key'];
    if (key is! String) return null;
    return switch (value['type']) {
      'closed' => OverlayClosed(key),
      'offset' => OverlayOffset(
        key,
        Duration(milliseconds: (value['offsetMs'] as num?)?.toInt() ?? 0),
      ),
      'open' => OverlayOpened(key, songId: value['songId'] as String?),
      'confirm' => switch (value['songId']) {
        final String id => OverlayConfirmed(key, id),
        _ => null,
      },
      'notMezmur' => OverlayNotMezmur(key),
      _ => null,
    };
  }
}

class OverlayClosed extends OverlayAction {
  const OverlayClosed(super.key);
}

class OverlayOffset extends OverlayAction {
  const OverlayOffset(super.key, this.offset);

  final Duration offset;
}

class OverlayOpened extends OverlayAction {
  const OverlayOpened(super.key, {this.songId});

  final String? songId;
}

class OverlayConfirmed extends OverlayAction {
  const OverlayConfirmed(super.key, this.songId);

  final String songId;
}

class OverlayNotMezmur extends OverlayAction {
  const OverlayNotMezmur(super.key);
}

enum OverlayStart { bubble, bar }

@immutable
class OverlayAppearance {
  const OverlayAppearance({
    this.textSize = 18,
    this.opacity = 1,
    this.start = OverlayStart.bubble,
  });

  static const minText = 12.0;
  static const maxText = 30.0;
  static const minOpacity = 0.4;

  final double textSize;
  final double opacity;
  final OverlayStart start;

  OverlayAppearance copyWith({
    double? textSize,
    double? opacity,
    OverlayStart? start,
  }) => OverlayAppearance(
    textSize: textSize ?? this.textSize,
    opacity: opacity ?? this.opacity,
    start: start ?? this.start,
  );

  Map<String, Object?> toMap() => {
    'textSp': textSize,
    'opacity': opacity,
    'start': start.name,
  };

  static OverlayAppearance fromMap(Object? value) {
    if (value is! Map) return const OverlayAppearance();
    return OverlayAppearance(
      textSize: (value['textSp'] as num?)?.toDouble() ?? 18,
      opacity: (value['opacity'] as num?)?.toDouble() ?? 1,
      start:
          OverlayStart.values.asNameMap()[value['start']] ??
          OverlayStart.bubble,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OverlayAppearance &&
      other.textSize == textSize &&
      other.opacity == opacity &&
      other.start == start;

  @override
  int get hashCode => Object.hash(textSize, opacity, start);
}

abstract interface class LyricsOverlay {
  Future<bool> canShow();

  Future<void> openSettings();

  Future<bool> show(OverlayContent content);

  Future<void> hide();

  Future<OverlayAppearance> appearance();

  Future<void> setAppearance(OverlayAppearance appearance);

  Stream<OverlayAction> get actions;
}

class NoLyricsOverlay implements LyricsOverlay {
  const NoLyricsOverlay();

  @override
  Future<bool> canShow() async => false;

  @override
  Future<void> openSettings() async {}

  @override
  Future<bool> show(OverlayContent content) async => false;

  @override
  Future<void> hide() async {}

  @override
  Future<OverlayAppearance> appearance() async => const OverlayAppearance();

  @override
  Future<void> setAppearance(OverlayAppearance appearance) async {}

  @override
  Stream<OverlayAction> get actions => const Stream.empty();
}

class AndroidLyricsOverlay implements LyricsOverlay {
  const AndroidLyricsOverlay([
    this._methods = const MethodChannel('zema/overlay'),
    this._events = const EventChannel('zema/overlay/events'),
  ]);

  final MethodChannel _methods;
  final EventChannel _events;

  @override
  Future<bool> canShow() async =>
      await _call<bool>('canShow', 'Checking the overlay permission') ?? false;

  @override
  Future<void> openSettings() =>
      _call<void>('openSettings', 'Opening the overlay settings');

  @override
  Future<bool> show(OverlayContent content) async =>
      await _call<bool>('show', 'Showing lyrics', content.toMap()) ?? false;

  @override
  Future<void> hide() => _call<void>('hide', 'Hiding lyrics');

  @override
  Future<OverlayAppearance> appearance() async => OverlayAppearance.fromMap(
    await _call<Map<Object?, Object?>>('appearance', 'Reading the appearance'),
  );

  @override
  Future<void> setAppearance(OverlayAppearance appearance) =>
      _call<void>('setAppearance', 'Saving the appearance', appearance.toMap());

  @override
  Stream<OverlayAction> get actions => _events
      .receiveBroadcastStream()
      .map(OverlayAction.fromMap)
      .where((action) => action != null)
      .cast<OverlayAction>()
      .handleError((Object e) => _log.warning('Overlay actions failed', e));

  Future<T?> _call<T>(String method, String what, [Object? arguments]) async {
    try {
      return await _methods.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      _log.warning('$what failed', e);
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
