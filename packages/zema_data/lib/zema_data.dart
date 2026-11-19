/// Zema's backend access: the Supabase implementations of zema_core's
/// [CatalogRepository], [AuthRepository], [ProfileRepository],
/// [BackupRepository], [ContributionRepository] and [ModerationRepository].
///
/// Pure Dart with no dart:io (no Flutter), so the app, the admin website and
/// tools share it.
library;

import 'package:zema_core/zema_core.dart';

export 'package:supabase/supabase.dart' show GotrueAsyncStorage;

export 'src/session_store.dart';
export 'src/supabase_backup_repository.dart';
export 'src/supabase_auth_repository.dart';
export 'src/supabase_catalog_repository.dart';
export 'src/supabase_contribution_repository.dart';
export 'src/supabase_moderation_repository.dart';
export 'src/supabase_profile_repository.dart';
