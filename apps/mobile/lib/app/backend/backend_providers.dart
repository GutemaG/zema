import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

import 'backend_config.dart';

/// The build's backend settings. Tests override it.
final backendConfigProvider = Provider<BackendConfig>(
  (ref) => const BackendConfig.fromEnvironment(),
);

/// The shared lyrics catalog, or null when the build has no backend key
/// (treated like being offline).
final catalogRepositoryProvider = Provider<CatalogRepository?>((ref) {
  final config = ref.watch(backendConfigProvider);
  if (!config.isConfigured) return null;
  final repository = SupabaseCatalogRepository(
    url: config.url,
    key: config.key,
  );
  ref.onDispose(repository.close);
  return repository;
});

/// The catalog's recordings to identify an excerpt against, or null without
/// a backend.
final audioCatalogProvider = Provider<AudioCatalog?>(
  (ref) => switch (ref.watch(catalogRepositoryProvider)) {
    final AudioCatalog catalog => catalog,
    _ => null,
  },
);

/// The catalog's track prints (intent 013), or null without a backend.
final trackPrintCatalogProvider = Provider<TrackPrintCatalog?>(
  (ref) => switch (ref.watch(catalogRepositoryProvider)) {
    final TrackPrintCatalog catalog => catalog,
    _ => null,
  },
);
