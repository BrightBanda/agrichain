import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// One of the three small metric cards (total garden / money owed / expected crop).
///
/// Designed to sit inside a Row of equal-width siblings.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;

  /// Colours the caption — red for an amount owed, green for growth.
  final Color? captionColor;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.captionColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeading,
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 3),
              Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: captionColor ?? AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lays out stat tiles in an evenly spaced row.
class StatTileRow extends StatelessWidget {
  final List<StatTile> tiles;

  const StatTileRow({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight bounds the row's height so `stretch` can equalise the
    // tiles. Without it, `stretch` inside a scroll view forces infinite height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}
