import 'package:flutter/material.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// A Home section's title, with an optional "See all" button.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final seeAll = onSeeAll;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ZemaSpacing.screenSide,
        20,
        ZemaSpacing.screenSide - 4,
        4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: colors.text),
              ),
            ),
          ),
          if (seeAll != null)
            TextButton(
              onPressed: seeAll,
              style: TextButton.styleFrom(
                foregroundColor: colors.primaryText,
                minimumSize: const Size(ZemaSpacing.minTap, ZemaSpacing.minTap),
              ),
              child: Text(AppLocalizations.of(context).homeSeeAll),
            ),
        ],
      ),
    );
  }
}
