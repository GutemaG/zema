import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/zema_colors.dart';
import '../../../app/theme/zema_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/detection_settings.dart';
import '../data/background_access.dart';

Future<void> showBatteryStepsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: const BatteryStepsSheet(),
      ),
    );

class BatteryStepsSheet extends ConsumerWidget {
  const BatteryStepsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final text = Theme.of(context).textTheme;
    final brand = ref.watch(phoneBrandProvider).value ?? PhoneBrand.other;
    final steps = switch (brand) {
      PhoneBrand.xiaomi => l10n.detectionBatteryXiaomi,
      PhoneBrand.samsung => l10n.detectionBatterySamsung,
      PhoneBrand.huawei => l10n.detectionBatteryHuawei,
      PhoneBrand.oppo => l10n.detectionBatteryOppo,
      PhoneBrand.vivo => l10n.detectionBatteryVivo,
      PhoneBrand.oneplus => l10n.detectionBatteryOneplus,
      PhoneBrand.transsion => l10n.detectionBatteryTranssion,
      PhoneBrand.other => l10n.detectionBatteryOther,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ZemaSpacing.screenSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.detectionBatteryTitle,
              style: text.titleLarge?.copyWith(color: colors.text),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.detectionBatteryIntro,
              style: text.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 12),
            Text(steps, style: text.bodyLarge?.copyWith(color: colors.text)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => unawaited(
                  ref.read(backgroundAccessProvider).openPhoneSettings(),
                ),
                child: Text(l10n.detectionBatteryOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
