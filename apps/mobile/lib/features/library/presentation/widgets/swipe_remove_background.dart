import 'package:flutter/material.dart';

import '../../../../app/theme/zema_colors.dart';

/// What shows behind a row while it is swiped away to remove it.
class SwipeRemoveBackground extends StatelessWidget {
  const SwipeRemoveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return ColoredBox(
      color: colors.soft,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 24),
          child: Icon(Icons.delete_outline, color: colors.text),
        ),
      ),
    );
  }
}
