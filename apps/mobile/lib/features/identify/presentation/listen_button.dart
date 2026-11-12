import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';

class ListenButton extends StatelessWidget {
  const ListenButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.mic_none_rounded),
    tooltip: AppLocalizations.of(context).listenTooltip,
    constraints: const BoxConstraints(
      minWidth: ZemaSpacing.minTap,
      minHeight: ZemaSpacing.minTap,
    ),
    onPressed: () => context.push(AppRoutes.listen),
  );
}
