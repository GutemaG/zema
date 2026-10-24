import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/theme/zema_colors.dart';
import 'package:zema/shared/widgets/empty_state.dart';
import 'package:zema/shared/widgets/tab_page.dart';

import '../../helpers/pump_app.dart';

const _icons = {
  EmptyStateKind.empty: Icons.inbox_outlined,
  EmptyStateKind.error: Icons.error_outline,
  EmptyStateKind.offline: Icons.cloud_off_outlined,
};

// English and Ethiopic copies of the same content.
const _texts = [
  (title: 'Nothing here yet', message: 'Songs you add will show up here.'),
  (title: 'እስካሁን ምንም የለም', message: 'የሚጨምሯቸው መዝሙሮች እዚህ ይታያሉ።'),
];

void main() {
  group('EmptyState', () {
    for (final kind in EmptyStateKind.values) {
      for (final text in _texts) {
        testWidgets('${kind.name} shows icon, title and message '
            '(${text.title})', (tester) async {
          await pumpThemed(
            tester,
            EmptyState(kind: kind, title: text.title, message: text.message),
          );

          expect(find.byIcon(_icons[kind]!), findsOneWidget);
          expect(find.text(text.title), findsOneWidget);
          expect(find.text(text.message), findsOneWidget);
          expect(find.byType(FilledButton), findsNothing);
        });

        testWidgets('${kind.name} action calls back when tapped '
            '(${text.title})', (tester) async {
          var taps = 0;
          await pumpThemed(
            tester,
            EmptyState(
              kind: kind,
              title: text.title,
              message: text.message,
              actionLabel: 'Try again',
              onAction: () => taps++,
            ),
          );

          await tester.tap(find.text('Try again'));
          expect(taps, 1);
        });
      }
    }

    testWidgets('no button without a callback, even with a label', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const EmptyState(
          kind: EmptyStateKind.offline,
          title: 'Offline',
          message: 'Showing saved lyrics.',
          actionLabel: 'Retry',
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('uses design tokens and a 44 px tall button', (tester) async {
      await pumpThemed(
        tester,
        EmptyState(
          kind: EmptyStateKind.error,
          title: 'Title',
          message: 'Message',
          actionLabel: 'Retry',
          onAction: () {},
        ),
      );
      final colors = tester.element(find.byType(EmptyState)).zemaColors;

      expect(tester.widget<Icon>(find.byType(Icon)).color, colors.muted);
      expect(tester.widget<Text>(find.text('Title')).style?.color, colors.text);
      expect(
        tester.widget<Text>(find.text('Message')).style?.color,
        colors.muted,
      );
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(44),
      );
    });

    for (final text in _texts) {
      testWidgets('no overflow at 1.3× with 40% longer strings on 360 dp '
          '(${text.title})', (tester) async {
        useScreen(tester, textScale: 1.3);
        String longer(String s) =>
            '$s ${s.substring(0, (s.length * 0.4).ceil())}';
        await pumpThemed(
          tester,
          EmptyState(
            kind: EmptyStateKind.empty,
            title: longer(text.title),
            message: longer(text.message),
            actionLabel: longer('Go home'),
            onAction: () {},
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('scrolls instead of overflowing on a very short screen', (
      tester,
    ) async {
      useScreen(tester, size: const Size(640, 200), textScale: 1.3);
      await pumpThemed(
        tester,
        EmptyState(
          kind: EmptyStateKind.error,
          title: 'Something went wrong',
          message: 'Check your connection and try again in a moment.',
          actionLabel: 'Try again',
          onAction: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Try again'), 50);
      expect(find.text('Try again').hitTestable(), findsOneWidget);
    });
  });

  group('TabPage', () {
    testWidgets('long titles ellipsize at 1.3× on 360 dp', (tester) async {
      useScreen(tester, textScale: 1.3);
      await pumpThemed(
        tester,
        TabPage(
          title: 'A very long translated screen title for this tab',
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
            ),
          ],
          child: const SizedBox(),
        ),
      );

      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(find.textContaining('A very long'));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
    });
  });
}
