import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../catalog/application/catalog_index.dart';

final _log = Logger('search.catalog');

/// A catalog song found by Search, by its title or one of its lines.
class CatalogMatch {
  const CatalogMatch({
    required this.songId,
    required this.title,
    required this.score,
    this.artist,
    this.line,
  });

  CatalogMatch.fromHit(CatalogSearchHit hit)
    : this(
        songId: hit.songId,
        title: hit.title,
        score: hit.score,
        artist: hit.artist,
        line: hit.line,
      );

  CatalogMatch.fromLyricMatch(LyricMatch match)
    : this(
        songId: match.song.id,
        title: match.song.title,
        score: match.score,
        artist: match.song.artist,
        line: match.line.text,
      );

  final String songId;
  final String title;
  final String? artist;
  final double score;

  /// The best-matching line, or null when the title matched.
  final String? line;

  @override
  String toString() => 'CatalogMatch($songId${line == null ? '' : ': $line'})';
}

/// The catalog's song index prepared for searching by title: one
/// [SearchKey] per song (its title and transliteration), built once per
/// index change. Works offline.
class CatalogTitleIndex {
  CatalogTitleIndex(List<CatalogEntry> entries)
    : _entries = [
        for (final entry in entries)
          (entry, SearchKey([entry.title, ?entry.transliteration].join(' '))),
      ];

  final List<(CatalogEntry, SearchKey)> _entries;

  /// Songs whose title matches [query], best first, then in index order.
  List<CatalogMatch> search(String query) {
    final key = SearchKey(query);
    if (key.isEmpty) return const [];
    final hits = <(int, double)>[];
    for (final (i, (_, titleKey)) in _entries.indexed) {
      final score = matchScore(key, titleKey);
      if (score >= matchThreshold) hits.add((i, score));
    }
    hits.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
    return [
      for (final (i, score) in hits)
        CatalogMatch(
          songId: _entries[i].$1.id,
          title: _entries[i].$1.title,
          artist: _entries[i].$1.artist,
          score: score,
        ),
    ];
  }
}

/// Title matches and line matches as one list, each song once, best first.
/// When a song matches both ways the higher score wins, and the title wins
/// a tie (as the server's `search_songs` does).
List<CatalogMatch> mergeCatalogMatches(
  List<CatalogMatch> titles,
  List<CatalogMatch> lines,
) {
  final best = <String, (int, CatalogMatch)>{};
  for (final match in [...titles, ...lines]) {
    final current = best[match.songId];
    if (current == null) {
      best[match.songId] = (best.length, match);
    } else if (match.score > current.$2.score) {
      best[match.songId] = (current.$1, match);
    }
  }
  final ranked = best.values.toList()
    ..sort((a, b) {
      final byScore = b.$2.score.compareTo(a.$2.score);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
  return [for (final (_, match) in ranked) match];
}

/// The index of catalog titles; null until the index has loaded.
final catalogTitleIndexProvider = Provider<CatalogTitleIndex?>((ref) {
  final entries = ref.watch(catalogEntriesProvider).value;
  return entries == null ? null : CatalogTitleIndex(entries);
});

/// How long Search waits after the last keystroke before asking the server.
const lineSearchDelay = Duration(milliseconds: 300);

/// The catalog songs with a line matching [query], from the server; null
/// in a build with no backend.
///
/// Waits [lineSearchDelay] first. Search watches only the current query, so
/// typing on disposes this provider: a query typed past is never sent, and
/// a slow answer for it is never shown. Title hits are left out; the index
/// finds those, offline too. Failures (a [ZemaFailure]) aren't retried
/// automatically; Search offers Try again.
final catalogLineSearchProvider = FutureProvider.autoDispose
    .family<List<CatalogMatch>?, String>((ref, query) async {
      final catalog = ref.watch(catalogRepositoryProvider);
      if (catalog == null || SearchKey(query).isEmpty) return null;
      // A timer rather than Future.delayed, so disposing cancels the wait.
      final wait = Completer<void>();
      final timer = Timer(lineSearchDelay, wait.complete);
      ref.onDispose(timer.cancel);
      await wait.future;
      final watch = Stopwatch()..start();
      final hits = await catalog.search(query);
      _log.fine('${hits.length} hits in ${watch.elapsedMilliseconds} ms');
      return [
        for (final hit in hits)
          if (hit.line != null) CatalogMatch.fromHit(hit),
      ];
    }, retry: (_, _) => null);
