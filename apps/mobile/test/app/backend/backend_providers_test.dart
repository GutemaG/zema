import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/backend/backend_config.dart';
import 'package:zema/app/backend/backend_providers.dart';
import 'package:zema_data/zema_data.dart';

void main() {
  test('without --dart-define: the emulator URL and no key', () {
    const config = BackendConfig.fromEnvironment();
    expect(config.url, 'http://10.0.2.2:54321');
    expect(config.key, isEmpty);
    expect(config.isConfigured, isFalse);
  });

  test('the catalog is null when the build has no key', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(catalogRepositoryProvider), isNull);
  });

  test('with a key, the catalog is the Supabase repository', () {
    final container = ProviderContainer(
      overrides: [
        backendConfigProvider.overrideWithValue(
          const BackendConfig(url: 'http://backend.test', key: 'anon-key'),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container.read(catalogRepositoryProvider),
      isA<SupabaseCatalogRepository>(),
    );
  });

  test('an empty URL counts as not configured', () {
    expect(const BackendConfig(url: '', key: 'k').isConfigured, isFalse);
  });
}
