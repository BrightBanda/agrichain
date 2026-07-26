import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'pill_badge.dart';

/// The top bar: brand, role badge, language chip, notifications and avatar.
///
/// [onLanguageTap] and [onNotificationsTap] are optional so a screen can leave
/// an affordance disabled rather than pretending it works.
class AppBrandHeader extends StatelessWidget {
  final String roleLabel;
  final String subtitle;
  final String languageCode;
  final int notificationCount;
  final String? avatarInitials;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  const AppBrandHeader({
    super.key,
    required this.roleLabel,
    this.subtitle = 'Home',
    this.languageCode = 'EN',
    this.notificationCount = 0,
    this.avatarInitials,
    this.onLanguageTap,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.cardTint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.eco,
                size: 18,
                color: AppColors.primaryMuted,
              ),
            ),
            const SizedBox(width: 8),
            // The brand and role badge yield space to the fixed-width actions
            // on the right rather than pushing them off the screen.
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'AgriChain',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: PillBadge(
                      text: roleLabel,
                      background: AppColors.goldSoft,
                      foreground: AppColors.gold,
                      dense: true,
                      uppercase: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _LanguageChip(code: languageCode, onTap: onLanguageTap),
            const SizedBox(width: 8),
            _NotificationBell(
              count: notificationCount,
              onTap: onNotificationsTap,
            ),
            const SizedBox(width: 8),
            _Avatar(initials: avatarInitials, onTap: onAvatarTap),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String code;
  final VoidCallback? onTap;

  const _LanguageChip({required this.code, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.language, size: 13, color: AppColors.primaryMuted),
            const SizedBox(width: 4),
            Text(
              code,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryMuted,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 15,
              color: AppColors.primaryMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _NotificationBell({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 17,
              color: AppColors.primaryMuted,
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? initials;
  final VoidCallback? onTap;

  const _Avatar({this.initials, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.cardTint,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: initials == null || initials!.isEmpty
            ? const Icon(Icons.person, size: 17, color: AppColors.primaryMuted)
            : Text(
                initials!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}
