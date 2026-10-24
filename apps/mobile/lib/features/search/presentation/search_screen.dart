import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/tab_page.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(
      title: l10n.navSearch,
      child: EmptyState(
        kind: EmptyStateKind.empty,
        title: l10n.comingSoonTitle,
        message: l10n.searchComingSoonMessage,
      ),
    );
  }
}
