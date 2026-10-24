import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';

/// Opens above the tab shell. The body is a placeholder until bolt 3 adds
/// Language, Palette and About.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: EmptyState(
        kind: EmptyStateKind.empty,
        title: l10n.comingSoonTitle,
        message: l10n.settingsComingSoonMessage,
      ),
    );
  }
}
