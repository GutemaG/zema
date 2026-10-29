/// Zema's backend access: the Supabase implementations of zema_core's
/// [CatalogRepository], [AuthRepository] and [ProfileRepository].
///
/// Pure Dart with no dart:io (no Flutter), so the app, the admin website and
/// tools share it.
library;

import 'package:zema_core/zema_core.dart';

export 'src/session_store.dart';
export 'src/supabase_auth_repository.dart';
export 'src/supabase_catalog_repository.dart';
export 'src/supabase_profile_repository.dart';
