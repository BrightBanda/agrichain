import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// One quick action: an icon over a label.
///
/// [filled] draws the primary treatment used for the main action in the row.
class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: filled ? AppColors.primary : AppColors.cardTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: filled ? Colors.white : AppColors.primaryMuted,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Evenly spaces quick actions across the width.
class QuickActionRow extends StatelessWidget {
  final List<QuickActionTile> actions;

  const QuickActionRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight bounds the row's height so `stretch` can equalise the
    // tiles. Without it, `stretch` inside a scroll view forces infinite height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: actions[i]),
          ],
        ],
      ),
    );
  }
}
