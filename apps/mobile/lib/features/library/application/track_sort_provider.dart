import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/preferences_provider.dart';
import 'tracks_query.dart';

/// The Tracks sort, remembered across restarts.
final trackSortProvider = NotifierProvider<TrackSortController, TrackSort>(
  TrackSortController.new,
);

class TrackSortController extends Notifier<TrackSort> {
  static const fieldKey = 'tracksSort';
  static const descendingKey = 'tracksSortDescending';

  @override
  TrackSort build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final name = prefs.getString(fieldKey);
    final field = TrackSortField.values.firstWhere(
      (f) => f.name == name,
      orElse: () => TrackSort.initial.field,
    );
    return TrackSort(field, descending: prefs.getBool(descendingKey) ?? false);
  }

  Future<void> set(TrackSort sort) async {
    if (sort == state) return;
    state = sort;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(fieldKey, sort.field.name);
    await prefs.setBool(descendingKey, sort.descending);
  }
}
