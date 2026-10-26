import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/preferences_provider.dart';

final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(
  RecentSearches.new,
);

/// The last searches, newest first, kept across restarts.
class RecentSearches extends Notifier<List<String>> {
  static const key = 'recentSearches';
  static const max = 10;

  @override
  List<String> build() =>
      ref.read(sharedPreferencesProvider).getStringList(key) ?? const [];

  /// Puts [query] first. The same search written differently (case,
  /// spelling variants) replaces the older entry; blank queries are
  /// ignored.
  Future<void> add(String query) async {
    final trimmed = query.trim();
    final normalized = normalizeSearchText(trimmed);
    if (normalized.isEmpty) return;
    await _save(
      [
        trimmed,
        for (final q in state)
          if (normalizeSearchText(q) != normalized) q,
      ].take(max).toList(),
    );
  }

  Future<void> remove(String query) => _save([
    for (final q in state)
      if (q != query) q,
  ]);

  Future<void> clear() => _save(const []);

  Future<void> _save(List<String> searches) async {
    state = searches;
    await ref.read(sharedPreferencesProvider).setStringList(key, searches);
  }
}
