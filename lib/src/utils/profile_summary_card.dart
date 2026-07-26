import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'pill_badge.dart';

/// The "welcome back" identity card.
///
/// [greeting] is passed in rather than hard-coded so it can be localised —
/// "Muli Bwanji" in Chichewa, "Welcome back" in English.
class ProfileSummaryCard extends StatelessWidget {
  final String greeting;
  final String name;
  final String location;
  final String? registrationId;
  final String? tierLabel;
  final String? avatarInitials;
  final VoidCallback? onTap;

  const ProfileSummaryCard({
    super.key,
    required this.greeting,
    required this.name,
    required this.location,
    this.registrationId,
    this.tierLabel,
    this.avatarInitials,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.cardTint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: avatarInitials == null || avatarInitials!.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: AppColors.primaryMuted,
                      size: 22,
                    )
                  : Text(
                      avatarInitials!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (registrationId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${registrationId!}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (tierLabel != null)
              PillBadge(
                text: tierLabel!,
                background: AppColors.goldSoft,
                foreground: AppColors.gold,
                icon: Icons.workspace_premium,
              ),
          ],
        ),
      ),
    );
  }
}
