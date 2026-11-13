import 'package:flutter/material.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../../app/theme/zema_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// What an account adds, shown on the account choice (S04) and sign in
/// (S24): contribute, back up, restore.
class AccountBenefits extends StatelessWidget {
  const AccountBenefits({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IconPoint(Icons.edit_note, l10n.accountBenefitContribute),
        IconPoint(Icons.cloud_upload_outlined, l10n.accountBenefitBackup),
        IconPoint(Icons.phonelink_setup_outlined, l10n.accountBenefitRestore),
      ],
    );
  }
}

class IconPoint extends StatelessWidget {
  const IconPoint(this.icon, this.label, {super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.soft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: colors.accentText),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// The buttons at the bottom of S04 and S24: a full-width filled primary
/// action and a text secondary one. [busy] shows progress on the primary
/// button and disables both.
class AccountActions extends StatelessWidget {
  const AccountActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.primaryIcon,
    this.busy = false,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final IconData? primaryIcon;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final icon = primaryIcon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: busy ? null : onPrimary,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          icon: busy
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.muted,
                  ),
                )
              : icon == null
              ? null
              : Icon(icon),
          label: Text(primaryLabel),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : onSecondary,
          style: TextButton.styleFrom(
            foregroundColor: colors.primaryText,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(secondaryLabel),
        ),
      ],
    );
  }
}

/// The S04 and S24 layout: [content] at the top and [actions] at the
/// bottom, scrolling together when they don't fit (large text, small
/// screens).
class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.content, required this.actions});

  final List<Widget> content;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            ZemaSpacing.screenSide,
            24,
            ZemaSpacing.screenSide,
            16,
          ),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...content,
                const Spacer(),
                const SizedBox(height: 24),
                actions,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
