import 'package:flutter/material.dart';
import 'app_colors.dart';

class VerifiedPhoneCard extends StatelessWidget {
  final String countryCode;
  final String phoneNumber;
  final VoidCallback onChangeTap;

  const VerifiedPhoneCard({
    super.key,
    this.countryCode = '+265',
    required this.phoneNumber,
    required this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.verifiedCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.verifiedCardBorder),
      ),
      child: Row(
        children: [
          // Country Code Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              countryCode,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Phone Info Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Verified Phone Number',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),

          // Change Action Link
          GestureDetector(
            onTap: onChangeTap,
            child: const Text(
              'Change',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}