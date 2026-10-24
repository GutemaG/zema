import 'package:flutter/material.dart';

import '../../../../app/theme/zema_colors.dart';

/// A vertical strip of section initials. Tapping or dragging over a letter
/// calls [onSelected] with it.
///
/// Letters shrink to fit the available height; screen readers skip the strip
/// (the list itself stays fully readable).
class AlphabetScroller extends StatefulWidget {
  const AlphabetScroller({
    super.key,
    required this.letters,
    required this.onSelected,
  });

  final List<String> letters;
  final ValueChanged<String> onSelected;

  @override
  State<AlphabetScroller> createState() => _AlphabetScrollerState();
}

class _AlphabetScrollerState extends State<AlphabetScroller> {
  String? _active;

  void _select(double dy, double height) {
    final letters = widget.letters;
    if (letters.isEmpty || height <= 0) return;
    final index = (dy / height * letters.length).floor().clamp(
      0,
      letters.length - 1,
    );
    final letter = letters[index];
    if (letter == _active) return;
    setState(() => _active = letter);
    widget.onSelected(letter);
  }

  void _end() => setState(() => _active = null);

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final cell = height / widget.letters.length.clamp(1, 1000);
          final fontSize = (cell * 0.75).clamp(6.0, 12.0);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(d.localPosition.dy, height),
            onTapUp: (_) => _end(),
            onVerticalDragStart: (d) => _select(d.localPosition.dy, height),
            onVerticalDragUpdate: (d) => _select(d.localPosition.dy, height),
            onVerticalDragEnd: (_) => _end(),
            child: SizedBox(
              width: 28,
              child: Column(
                children: [
                  for (final letter in widget.letters)
                    SizedBox(
                      height: cell,
                      child: Center(
                        child: Text(
                          letter,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            fontSize: fontSize,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            color: letter == _active
                                ? colors.primaryText
                                : colors.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
