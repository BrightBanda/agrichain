import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// One option in a [SegmentedToggle].
class ToggleOption {
  final String label;
  final IconData icon;

  const ToggleOption({required this.label, required this.icon});
}

/// A two-or-more option switch, filled on the selected side.
///
/// Used for Marketplace / Sell Product and for the analytics tabs.
class SegmentedToggle extends StatelessWidget {
  final List<ToggleOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Lets the row scroll when the labels do not fit, as the analytics tabs need.
  final bool scrollable;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final segments = [
      for (var i = 0; i < options.length; i++)
        _Segment(
          option: options[i],
          selected: i == selectedIndex,
          expand: !scrollable,
          onTap: () => onSelected(i),
        ),
    ];

    if (!scrollable) {
      return Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: segments[i]),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            segments[i],
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final ToggleOption option;
  final bool selected;
  final bool expand;
  final VoidCallback onTap;

  const _Segment({
    required this.option,
    required this.selected,
    required this.expand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              option.icon,
              size: 15,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
