import 'package:flutter/material.dart';

import 'theme/zema_colors.dart';
import 'theme/zema_spacing.dart';

/// One destination in [ZemaNavBar].
class ZemaNavItem {
  const ZemaNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Bottom navigation matching the design canvas: icon over label, no
/// indicator pill, active item in `primaryText` and bold, others `muted`.
///
/// The bar keeps a fixed height; long labels ellipsize and text scaling is
/// capped at 1.3× so the bar never grows or overflows.
class ZemaNavBar extends StatelessWidget {
  const ZemaNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double height = 64;

  final List<ZemaNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ZemaNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zemaColors;
    final color = selected ? colors.primaryText : colors.muted;
    // One node per item for screen readers: label, button, selected state and
    // a tap action (the InkWell's own semantics are excluded with the text).
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: ZemaSpacing.minTap,
            minHeight: ZemaSpacing.minTap,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 24, color: color),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
