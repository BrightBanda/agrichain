import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'pill_badge.dart';

/// The header shown at the top of every signed-in screen.
///
/// Laid out as two rows rather than one: a compact utility row of actions, then
/// the brand centred beneath it. Centring the brand in the *same* row as the
/// actions would either push them off a narrow screen or leave the brand
/// visibly off-centre, since true centring cannot account for unequal side
/// widths.
///
/// Callbacks are optional so a screen can omit an affordance entirely rather
/// than showing one that does nothing.
class AppBrandHeader extends StatelessWidget {
  final String roleLabel;
  final String subtitle;
  final String languageCode;
  final int notificationCount;
  final String? avatarInitials;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  /// Opens the ledger explorer. Null hides the action.
  final VoidCallback? onLedgerTap;

  /// Opens the USSD simulator. Null hides the action.
  final VoidCallback? onUssdTap;

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
    this.onLedgerTap,
    this.onUssdTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Utility row: language on the left, account actions on the right.
        Row(
          children: [
            _LanguageChip(code: languageCode, onTap: onLanguageTap),
            const Spacer(),
            if (onUssdTap != null) ...[
              _UssdChip(onTap: onUssdTap!),
              const SizedBox(width: 7),
            ],
            if (onLedgerTap != null) ...[
              _CircleAction(
                icon: Icons.link,
                tooltip: 'AgriChain ledger',
                onTap: onLedgerTap!,
              ),
              const SizedBox(width: 7),
            ],
            _NotificationBell(
              count: notificationCount,
              onTap: onNotificationsTap,
            ),
            const SizedBox(width: 7),
            _Avatar(initials: avatarInitials, onTap: onAvatarTap),
          ],
        ),
        const SizedBox(height: 14),

        // Brand, centred and prominent.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.cardTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.eco,
                size: 23,
                color: AppColors.primaryMuted,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'AgriChain',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: PillBadge(
                text: roleLabel,
                background: AppColors.goldSoft,
                foreground: AppColors.gold,
                uppercase: true,
              ),
            ),
          ],
        ),

        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Text button reading "USSD" — the entry point to the low-connectivity menu.
class _UssdChip extends StatelessWidget {
  final VoidCallback onTap;

  const _UssdChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'USSD menu (simulation)',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.dialpad, size: 13, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'USSD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryMuted),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.language, size: 14, color: AppColors.primaryMuted),
            const SizedBox(width: 4),
            Text(
              code,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryMuted,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
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
        padding: const EdgeInsets.all(7),
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.cardTint,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: initials == null || initials!.isEmpty
            ? const Icon(Icons.person, size: 18, color: AppColors.primaryMuted)
            : Text(
                initials!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}
