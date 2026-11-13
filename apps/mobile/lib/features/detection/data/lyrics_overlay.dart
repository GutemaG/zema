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

@immutable
class OverlaySheet {
  const OverlaySheet({
    required this.key,
    required this.source,
    required this.songId,
    required this.title,
    required this.lines,
    this.artist,
    this.offset = Duration.zero,
  });

  final String key;
  final String source;
  final String songId;
  final String title;
  final String? artist;
  final List<OverlayLine> lines;
  final Duration offset;

  Map<String, Object?> toMap() => {
    'key': key,
    'source': source,
    'songId': songId,
    'title': title,
    'artist': ?artist,
    'offsetMs': offset.inMilliseconds,
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
      listEquals(other.lines, lines);

  @override
  int get hashCode => Object.hash(
    key,
    source,
    songId,
    title,
    artist,
    offset,
    Object.hashAll(lines),
  );

  @override
  String toString() => 'OverlaySheet($songId for $key, ${lines.length} lines)';
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

abstract interface class LyricsOverlay {
  Future<bool> canShow();

  Future<void> openSettings();

  Future<bool> show(OverlaySheet sheet);

  Future<void> hide();

  Stream<OverlayAction> get actions;
}

class NoLyricsOverlay implements LyricsOverlay {
  const NoLyricsOverlay();

  @override
  Future<bool> canShow() async => false;

  @override
  Future<void> openSettings() async {}

  @override
  Future<bool> show(OverlaySheet sheet) async => false;

  @override
  Future<void> hide() async {}

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
  Future<bool> show(OverlaySheet sheet) async =>
      await _call<bool>('show', 'Showing lyrics', sheet.toMap()) ?? false;

  @override
  Future<void> hide() => _call<void>('hide', 'Hiding lyrics');

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
