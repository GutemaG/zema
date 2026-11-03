import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../application/drafts.dart';

/// Starts [draft] (a new song unless it says otherwise) and opens it. Every
/// way into contributing goes through here. No account is needed: drafts
/// and lyrics saved on this phone are local, and only sending one for
/// review asks a guest to sign in (S22).
Future<void> startContribution(
  BuildContext context,
  WidgetRef ref, {
  ContributionDraft draft = const ContributionDraft(),
}) async {
  final id = await startDraft(ref, draft: draft);
  if (context.mounted) await context.push<void>(AppRoutes.draft(id));
}
