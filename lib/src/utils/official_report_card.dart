import 'package:flutter/material.dart';
import 'lending_score_colors.dart';

class OfficialReportCard extends StatelessWidget {
  const OfficialReportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: LendingScoreColors.lightGreenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LendingScoreColors.borderGreen),
      ),
      child: Row(
        children: [
          // File Icon Chip
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: LendingScoreColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Description Text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Official Monthly Report',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: LendingScoreColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Download complete audited records for bank & loan applications.',
                  style: TextStyle(
                    fontSize: 10,
                    color: LendingScoreColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Export Button
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: LendingScoreColors.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Export',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}