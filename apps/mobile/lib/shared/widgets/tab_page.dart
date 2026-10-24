import 'package:flutter/material.dart';

import '../../app/theme/zema_spacing.dart';

/// Layout for a tab's root screen: a large title header with optional actions
/// above the content, as on the design canvas.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;

  /// Buttons at the end of the header, e.g. the Settings gear on Home.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ZemaSpacing.screenSide,
                12,
                ZemaSpacing.screenSide - 4,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
