import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zema/app/app_shell.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/app/zema_nav_bar.dart';
import 'package:zema/features/contribute/presentation/contribute_screen.dart';
import 'package:zema/features/home/presentation/home_screen.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';
import 'package:zema/features/library/presentation/library_screen.dart';
import 'package:zema/features/search/presentation/search_screen.dart';
import 'package:zema/features/settings/presentation/settings_screen.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema/shared/widgets/empty_state.dart';

import '../helpers/fake_library.dart';
import '../helpers/fake_player.dart';
import '../helpers/pump_app.dart';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(ZemaNavBar), matching: find.text(label));

TextStyle _navStyle(WidgetTester tester, String label) =>
    tester.widget<Text>(_navLabel(label)).style!;

/// Records calls to SystemNavigator.pop (what Android back does at the root).
List<String> _recordSystemPops(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      calls.add(call.method);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  group('bottom navigation', () {
    testWidgets('each tab opens its screen and is highlighted', (tester) async {
      await pumpZemaApp(tester);
      final colors = tester.element(find.byType(HomeScreen)).zemaColors;

      const tabs = {
        'Search': SearchScreen,
        'Library': LibraryScreen,
        'Contribute': ContributeScreen,
        'Home': HomeScreen,
      };
      for (final MapEntry(key: label, value: screen) in tabs.entries) {
        await tester.tap(_navLabel(label));
        await tester.pumpAndSettle();

        expect(find.byType(screen), findsOneWidget, reason: label);
        for (final other in tabs.keys) {
          final style = _navStyle(tester, other);
          final active = other == label;
          expect(
            style.color,
            active ? colors.primaryText : colors.muted,
            reason: '$other while $label is open',
          );
          expect(
            style.fontWeight,
            active ? FontWeight.w700 : FontWeight.w500,
            reason: '$other while $label is open',
          );
        }
      }
    });

    testWidgets('keeps a tab scroll position when switching away and back', (
      tester,
    ) async {
      // Short screen so the Contribute tab's content has to scroll.
      useScreen(tester, size: const Size(360, 260));
      await pumpZemaApp(tester);

      await tester.tap(_navLabel('Contribute'));
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: find.byType(ContributeScreen),
        matching: find.byType(Scrollable),
      );
      await tester.drag(scrollable, const Offset(0, -60));
      await tester.pumpAndSettle();
      final scrolled = tester.state<ScrollableState>(scrollable).position;
      expect(scrolled.pixels, greaterThan(0));
      final offset = scrolled.pixels;

      await tester.tap(_navLabel('Library'));
      await tester.pumpAndSettle();
      await tester.tap(_navLabel('Contribute'));
      await tester.pumpAndSettle();

      expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    });

    testWidgets('re-tapping the active tab pops it to its root', (
      tester,
    ) async {
      // The production tabs have no sub-pages yet, so use a shell with one.
      final router = GoRouter(
        initialLocation: '/a',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => AppShell(navigationShell: shell),
            branches: [
              for (final tab in ['a', 'b', 'c', 'd'])
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/$tab',
                      builder: (_, _) => Text('root $tab'),
                      routes: [
                        GoRoute(
                          path: 'detail',
                          builder: (_, _) => Text('detail $tab'),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          // The shell starts the library sync; keep it idle here.
          overrides: [
            ...libraryOverrides(
              permissions: FakeAudioPermissionService(
                current: AudioAccess.unsupported,
              ),
            ),
            ...playerOverrides(),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(extensions: const [ZemaColors.nightVigil]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/a/detail');
      await tester.pumpAndSettle();
      expect(find.text('detail a'), findsOneWidget);

      await tester.tap(_navLabel('Home'));
      await tester.pumpAndSettle();
      expect(find.text('root a'), findsOneWidget);
      expect(find.text('detail a'), findsNothing);
    });
  });

  group('back button', () {
    testWidgets('on another tab goes to Home', (tester) async {
      final pops = _recordSystemPops(tester);
      await pumpZemaApp(tester);
      await tester.tap(_navLabel('Library'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LibraryScreen), findsNothing);
      expect(pops, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('on Home exits the app', (tester) async {
      final pops = _recordSystemPops(tester);
      await pumpZemaApp(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(pops, contains('SystemNavigator.pop'));
    });
  });

  group('routes', () {
    const screens = {
      AppRoutes.home: HomeScreen,
      AppRoutes.search: SearchScreen,
      AppRoutes.library: LibraryScreen,
      AppRoutes.contribute: ContributeScreen,
      AppRoutes.settings: SettingsScreen,
    };
    for (final MapEntry(key: path, value: screen) in screens.entries) {
      testWidgets('$path opens $screen', (tester) async {
        await pumpZemaApp(tester, location: path);
        expect(find.byType(screen), findsOneWidget);
      });
    }

    testWidgets('/ redirects to Home', (tester) async {
      await pumpZemaApp(tester, location: '/');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('the Home gear opens Settings above the shell', (tester) async {
      await pumpZemaApp(tester);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(ZemaNavBar), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ZemaNavBar), findsOneWidget);
    });

    testWidgets('an unknown route shows the C07 error with Go home', (
      tester,
    ) async {
      await pumpZemaApp(tester, location: '/no-such-page');

      final state = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(state.kind, EmptyStateKind.error);
      expect(find.text('Page not found'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Go home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('nav items and the gear have labels and 44×44 targets', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpZemaApp(tester);

      for (final label in ['Home', 'Search', 'Library', 'Contribute']) {
        final item = find.bySemanticsLabel(label);
        expect(item, findsOneWidget, reason: label);
        final size = tester.getSize(item);
        expect(size.width, greaterThanOrEqualTo(44), reason: label);
        expect(size.height, greaterThanOrEqualTo(44), reason: label);
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('Home')),
        matchesSemantics(
          label: 'Home',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      // IconButton exposes its tooltip to screen readers as the tooltip
      // property, which TalkBack and VoiceOver announce.
      expect(
        tester.getSemantics(find.byTooltip('Settings')),
        isSemantics(tooltip: 'Settings', isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSize(find.byTooltip('Settings')),
        greaterThanOrEqualTo(const Size(44, 44)),
      );
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('localized labels follow the UI language', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpZemaApp(tester, deviceLocales: const [Locale('am')]);

      expect(find.bySemanticsLabel('ፍለጋ'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('layout', () {
    testWidgets('no overflow at 1.3× text scale on a 360 dp screen', (
      tester,
    ) async {
      useScreen(tester, textScale: 1.3);
      for (final code in ['en', 'am', 'om', 'ti']) {
        await pumpZemaApp(tester, deviceLocales: [Locale(code)]);
        for (final tab in [0, 1, 2, 3]) {
          await tester.tap(
            find
                .descendant(
                  of: find.byType(ZemaNavBar),
                  matching: find.byType(InkWell),
                )
                .at(tab),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$code tab $tab');
        }
      }
    });

    testWidgets('long labels ellipsize and keep the bar height', (
      tester,
    ) async {
      useScreen(tester, textScale: 1.3);
      // About 40% longer than the longest real label.
      const long = 'Contribute lyrics';
      await pumpThemed(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: ZemaNavBar(
            selectedIndex: 0,
            onSelected: (_) {},
            items: const [
              ZemaNavItem(icon: Icons.home, label: long),
              ZemaNavItem(icon: Icons.search, label: long),
              ZemaNavItem(icon: Icons.book, label: long),
              ZemaNavItem(icon: Icons.edit, label: long),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ZemaNavBar)).height, ZemaNavBar.height);
      final text = tester.widget<Text>(find.text(long).first);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
