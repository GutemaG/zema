import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import 'catalog_page.dart';
import 'contributions_page.dart';
import 'fingerprints_page.dart';
import 'reports_page.dart';
import 'session.dart';
import 'strings.dart';
import 'theme.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: Strings.appName,
    debugShowCheckedModeBanner: false,
    theme: buildAdminTheme(),
    home: const SessionGate(),
  );
}

/// Signs in, then shows the moderator's pages; nothing else otherwise.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(adminConfigProvider).isConfigured) {
      return const _Message(
        title: Strings.appName,
        body: Strings.notConfigured,
      );
    }
    return switch (ref.watch(sessionProvider)) {
      AsyncData(value: Moderator(:final profile)) => AdminShell(
        profile: profile,
      ),
      AsyncData(value: NotModerator(:final user)) => _Message(
        title: Strings.notModerator,
        body: '${user.email ?? user.name ?? ''}\n\n${Strings.notModeratorHint}',
        action: const _SignOutButton(),
      ),
      AsyncData(value: SignedOut(:final error)) => _SignInPage(error: error),
      AsyncError(:final error) => _Message(
        title: Strings.appName,
        body: error is NetworkFailure ? Strings.offline : '$error',
        action: FilledButton(
          onPressed: () => ref.invalidate(sessionProvider),
          child: const Text(Strings.retry),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _SignInPage extends ConsumerWidget {
  const _SignInPage({this.error});

  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Message(
    title: Strings.appName,
    body: error == null
        ? Strings.signInHint
        : '${Strings.signInFailed}: $error',
    action: FilledButton(
      onPressed: () => ref.read(sessionProvider.notifier).signIn(),
      child: const Text(Strings.signIn),
    ),
  );
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton(
    onPressed: () => ref.read(sessionProvider.notifier).signOut(),
    child: const Text(Strings.signOut),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: text.headlineSmall),
                const SizedBox(height: 12),
                Text(body, textAlign: TextAlign.center, style: text.bodyMedium),
                if (action case final action?) ...[
                  const SizedBox(height: 24),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The moderator's pages: a rail on wide screens, a bottom bar on narrow.
enum AdminPage {
  contributions(Strings.contributions, Icons.inbox_outlined),
  fingerprints(Strings.fingerprints, Icons.graphic_eq),
  reports(Strings.reports, Icons.flag_outlined),
  catalog(Strings.catalog, Icons.library_music_outlined);

  const AdminPage(this.label, this.icon);

  final String label;
  final IconData icon;
}

final adminPageProvider = NotifierProvider<AdminPageNotifier, AdminPage>(
  AdminPageNotifier.new,
);

class AdminPageNotifier extends Notifier<AdminPage> {
  @override
  AdminPage build() => AdminPage.contributions;

  void show(AdminPage page) => state = page;
}

/// What each page shows; tests replace it.
final pageBodiesProvider = Provider<Map<AdminPage, WidgetBuilder>>(
  (_) => {
    AdminPage.contributions: (_) => const ContributionsPage(),
    AdminPage.fingerprints: (_) => const FingerprintsPage(),
    AdminPage.reports: (_) => const ReportsPage(),
    AdminPage.catalog: (_) => const CatalogPage(),
  },
);

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(adminPageProvider);
    void select(int i) =>
        ref.read(adminPageProvider.notifier).show(AdminPage.values[i]);
    final body =
        ref.watch(pageBodiesProvider)[page]?.call(context) ??
        const Center(child: Text(Strings.comingSoon));
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(
        title: Text(page.label),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text(profile.displayName)),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: _SignOutButton(),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: page.index,
                  onDestinationSelected: select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final p in AdminPage.values)
                      NavigationRailDestination(
                        icon: Icon(p.icon),
                        label: Text(p.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: page.index,
              onDestinationSelected: select,
              destinations: [
                for (final p in AdminPage.values)
                  NavigationDestination(icon: Icon(p.icon), label: p.label),
              ],
            ),
    );
  }
}
