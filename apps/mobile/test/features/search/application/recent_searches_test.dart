import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/search/application/recent_searches.dart';

Future<(ProviderContainer, SharedPreferences)> _container({
  List<String>? saved,
}) async {
  SharedPreferences.setMockInitialValues({RecentSearches.key: ?saved});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer.test(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  return (container, prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecentSearches', () {
    test('starts empty, or with what was saved', () async {
      var (container, _) = await _container();
      expect(container.read(recentSearchesProvider), isEmpty);

      (container, _) = await _container(saved: ['kidist', 'amlak']);
      expect(container.read(recentSearchesProvider), ['kidist', 'amlak']);
    });

    test('adds newest first, trimmed, and saves', () async {
      final (container, prefs) = await _container();
      final searches = container.read(recentSearchesProvider.notifier);

      await searches.add(' kidist ');
      await searches.add('amlak');

      expect(container.read(recentSearchesProvider), ['amlak', 'kidist']);
      expect(prefs.getStringList(RecentSearches.key), ['amlak', 'kidist']);
    });

    test(
      'the same search written differently replaces the older one',
      () async {
        final (container, _) = await _container(saved: ['ፀሎት', 'amlak']);
        final searches = container.read(recentSearchesProvider.notifier);

        await searches.add('ጸሎት');
        await searches.add('AMLAK');

        expect(container.read(recentSearchesProvider), ['AMLAK', 'ጸሎት']);
      },
    );

    test('ignores blank and noise-only queries', () async {
      final (container, _) = await _container(saved: ['amlak']);
      final searches = container.read(recentSearchesProvider.notifier);

      await searches.add('   ');
      await searches.add('Official Video');

      expect(container.read(recentSearchesProvider), ['amlak']);
    });

    test('keeps the 10 newest', () async {
      final (container, _) = await _container();
      final searches = container.read(recentSearchesProvider.notifier);
      for (var i = 1; i <= 12; i++) {
        await searches.add('song $i');
      }

      final recent = container.read(recentSearchesProvider);
      expect(recent, hasLength(RecentSearches.max));
      expect(recent.first, 'song 12');
      expect(recent.last, 'song 3');
    });

    test('removes one, and clears all', () async {
      final (container, prefs) = await _container(saved: ['a1', 'b2', 'c3']);
      final searches = container.read(recentSearchesProvider.notifier);

      await searches.remove('b2');
      expect(container.read(recentSearchesProvider), ['a1', 'c3']);

      await searches.clear();
      expect(container.read(recentSearchesProvider), isEmpty);
      expect(prefs.getStringList(RecentSearches.key), isEmpty);
    });
  });
}
