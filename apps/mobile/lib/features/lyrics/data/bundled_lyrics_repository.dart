import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

final _log = Logger('lyrics.bundled');

/// The lyrics the app reads: the bundled samples until the cloud catalog
/// (intent 004) replaces them.
final lyricsRepositoryProvider = Provider<LyricsRepository>(
  (ref) => BundledLyricsRepository(rootBundle),
);

/// Lyrics shipped with the app in `assets/lyrics/`: an `index.json` listing
/// LRC files, one recording each. Read once, on first use.
///
/// A file that is missing, malformed or repeats an ID is skipped (and
/// logged); the others still load.
class BundledLyricsRepository implements LyricsRepository {
  BundledLyricsRepository(this._assets);

  static const folder = 'assets/lyrics';

  final AssetBundle _assets;
  Future<_Bundle>? _bundle;

  Future<_Bundle> get _loaded => _bundle ??= _load();

  Future<_Bundle> _load() async {
    final Object? index;
    try {
      index = jsonDecode(await _assets.loadString('$folder/index.json'));
    } on Object catch (e) {
      throw LyricsFormatFailure('Could not read the bundled lyrics', cause: e);
    }
    final entries = switch (index) {
      {'songs': final List<Object?> songs} => songs,
      _ => throw const LyricsFormatFailure(
        'The bundled lyrics index has no "songs" list',
      ),
    };
    final bundle = _Bundle();
    for (final entry in entries) {
      try {
        await _add(bundle, entry);
      } on Object catch (e) {
        _log.fine('Skipped a bundled song: $e');
      }
    }
    return bundle;
  }

  Future<void> _add(_Bundle bundle, Object? entry) async {
    if (entry is! Map<String, Object?>) {
      throw const LyricsFormatFailure('An index entry is not an object');
    }
    final (id, file) = switch (entry) {
      {'id': final String id, 'file': final String file} => (id, file),
      _ => throw const LyricsFormatFailure('An index entry needs id and file'),
    };
    if (bundle.songs.containsKey(id)) {
      throw LyricsFormatFailure('Song $id is listed twice');
    }
    final imported = importIndexedLrc(
      entry,
      await _assets.loadString('$folder/$file'),
    );
    if (imported.skipped.isNotEmpty) {
      _log.fine('$file: skipped ${imported.skipped.join('; ')}');
    }
    bundle.songs[id] = imported.song;
    bundle.recordings[id] = imported.recording;
    bundle.timings[id] = imported.timing;
  }

  @override
  Future<List<Song>> songs() async => [...(await _loaded).songs.values];

  @override
  Future<Song?> song(String id) async => (await _loaded).songs[id];

  @override
  Future<List<Recording>> recordings(String songId) async => [
    for (final r in (await _loaded).recordings.values)
      if (r.songId == songId) r,
  ];

  @override
  Future<SyncTiming?> timing(String recordingId) async =>
      (await _loaded).timings[recordingId];

  @override
  Future<List<Song>> search(String query) async =>
      searchSongs(await songs(), query);
}

class _Bundle {
  final songs = <String, Song>{};
  final recordings = <String, Recording>{};
  final timings = <String, SyncTiming>{};
}
