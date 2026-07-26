import 'package:flutter/material.dart';

/// A small rounded label — the `FARMER`, `Pending Approval` and `Gold Farmer`
/// chips all use this.
class PillBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final bool dense;
  final bool uppercase;

  const PillBadge({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
    this.dense = false,
    this.uppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 10 : 13, color: foreground),
            SizedBox(width: dense ? 3 : 5),
          ],
          // Flexible so a long label ellipsizes instead of overflowing the
          // row it sits in — role names like FINANCIAL_INSTITUTION are wide.
          Flexible(
            child: Text(
              uppercase ? text.toUpperCase() : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: dense ? 9 : 10.5,
                fontWeight: FontWeight.bold,
                color: foreground,
                letterSpacing: uppercase ? 0.6 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
