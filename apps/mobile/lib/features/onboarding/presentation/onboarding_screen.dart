import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_language.dart';
import '../../../app/l10n/language_providers.dart';
import '../../../app/routes.dart';
import '../../../app/theme/zema_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/presentation/widgets/account_page.dart';
import '../../detection/application/detection_providers.dart';
import '../../detection/presentation/permissions_group.dart';
import '../../settings/application/settings_controller.dart';
import '../application/onboarding.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pages = 3;

  final _pager = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() => unawaited(
    _pager.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    ),
  );

  Future<void> _finish() async {
    await ref.read(onboardingPendingProvider.notifier).done();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.zemaColors;
    final textTheme = Theme.of(context).textTheme;
    final otherApps = ref.watch(otherAppsSupportedProvider);

    List<Widget> heading(IconData icon, String title, String message) => [
      _Dots(page: _page, count: _pages),
      const SizedBox(height: 24),
      Icon(icon, size: 48, color: colors.accentText),
      const SizedBox(height: 16),
      Text(title, style: textTheme.headlineSmall?.copyWith(color: colors.text)),
      const SizedBox(height: 8),
      Text(message, style: textTheme.bodyMedium?.copyWith(color: colors.muted)),
      const SizedBox(height: 16),
    ];

    final next = AccountActions(
      primaryLabel: l10n.onboardingNext,
      onPrimary: _next,
      secondaryLabel: l10n.onboardingSkip,
      onSecondary: () => unawaited(_finish()),
    );

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pager,
          onPageChanged: (page) => setState(() => _page = page),
          children: [
            AccountPage(
              content: [
                ...heading(
                  Icons.music_note_rounded,
                  l10n.onboardingWelcomeTitle,
                  l10n.onboardingWelcomeMessage,
                ),
                const _Languages(),
              ],
              actions: next,
            ),
            AccountPage(
              content: [
                ...heading(
                  Icons.lightbulb_outline,
                  l10n.onboardingHowTitle,
                  l10n.onboardingHowMessage,
                ),
                IconPoint(
                  Icons.library_music_outlined,
                  l10n.onboardingStepPlay,
                ),
                IconPoint(Icons.lyrics_outlined, l10n.onboardingStepLyrics),
                if (otherApps)
                  IconPoint(
                    Icons.picture_in_picture_alt_outlined,
                    l10n.onboardingStepOtherApps,
                  )
                else
                  IconPoint(Icons.mic_none, l10n.onboardingStepListen),
              ],
              actions: next,
            ),
            AccountPage(
              content: [
                ...heading(
                  Icons.verified_user_outlined,
                  l10n.onboardingPermissionsTitle,
                  l10n.onboardingPermissionsMessage,
                ),
                const PermissionsGroup(music: true),
                const SizedBox(height: 16),
                Text(
                  l10n.onboardingPrivacy,
                  style: textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
              ],
              actions: AccountActions(
                primaryLabel: l10n.onboardingContinue,
                onPrimary: () => unawaited(_finish()),
                secondaryLabel: l10n.onboardingSkipForNow,
                onSecondary: () => unawaited(_finish()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.page, required this.count});

  final int page;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: i == page ? 20 : 8,
              height: 8,
              margin: const EdgeInsetsDirectional.only(end: 6),
              decoration: BoxDecoration(
                color: i == page ? colors.primary : colors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

class _Languages extends ConsumerWidget {
  const _Languages();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appLanguageProvider);
    return RadioGroup<AppLanguage>(
      groupValue: current,
      onChanged: (language) {
        if (language != null && language != current) {
          unawaited(
            ref.read(settingsProvider.notifier).setLanguage(language.code),
          );
        }
      },
      child: Column(
        children: [
          for (final language in AppLanguage.values)
            RadioListTile<AppLanguage>(
              key: ValueKey(language),
              value: language,
              contentPadding: EdgeInsets.zero,
              title: Text(language.nativeName, locale: language.locale),
            ),
        ],
      ),
    );
  }
}
