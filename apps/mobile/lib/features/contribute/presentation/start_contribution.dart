import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/application/account_providers.dart';
import '../../account/presentation/widgets/sign_in_prompt.dart';
import '../application/drafts.dart';

/// Signs a guest in first (C09), then starts [draft] (a new song unless
/// it says otherwise) and opens it. Every way into contributing goes
/// through here; nothing happens when the guest doesn't sign in.
Future<void> startContribution(
  BuildContext context,
  WidgetRef ref, {
  ContributionDraft draft = const ContributionDraft(),
}) async {
  if (ref.read(authRepositoryProvider)?.currentUser == null) {
    final signedIn = await showSignInPrompt(
      context,
      reason: AppLocalizations.of(context).contributeSignInReason,
    );
    if (!signedIn || !context.mounted) return;
  }
  final id = await startDraft(ref, draft: draft);
  if (context.mounted) await context.push<void>(AppRoutes.draft(id));
}
