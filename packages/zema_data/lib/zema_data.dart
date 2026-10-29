/// Zema's backend access: the Supabase implementation of zema_core's
/// [CatalogRepository].
///
/// Pure Dart with no dart:io (no Flutter), so the app, the admin website and
/// tools share it.
library;

import 'package:zema_core/zema_core.dart';

export 'src/supabase_catalog_repository.dart';
