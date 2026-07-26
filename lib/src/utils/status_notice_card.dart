import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'pill_badge.dart';

/// An attention banner with an optional badge and action — used for the
/// registration approval state, and reusable for any pending/blocked notice.
class StatusNoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? badgeText;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// Colours default to the amber "pending" treatment.
  final Color background;
  final Color border;
  final Color accent;

  const StatusNoticeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.badgeText,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.background = AppColors.warningSoft,
    this.border = AppColors.warningBorder,
    this.accent = AppColors.warning,
  });

  /// The success variant, for an approved registration.
  const StatusNoticeCard.positive({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.badgeText,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  }) : background = AppColors.accentSoft,
       border = const Color(0xFFB6E3CD),
       accent = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeading,
                      ),
                    ),
                    if (badgeText != null)
                      PillBadge(
                        text: badgeText!,
                        background: accent.withValues(alpha: 0.14),
                        foreground: accent,
                        dense: true,
                      ),
                  ],
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                _ActionButton(
                  label: actionLabel!,
                  icon: actionIcon,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const _ActionButton({required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? null : Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}
