import 'package:flutter/material.dart';
import 'lending_score_colors.dart';

class LendingScoreItemCard extends StatelessWidget {
  final String score;
  final String pointsAdded;
  final String description;
  final String date;

  const LendingScoreItemCard({
    super.key,
    required this.score,
    required this.pointsAdded,
    required this.description,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: LendingScoreColors.lightGreenBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LendingScoreColors.borderGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    score,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: LendingScoreColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LendingScoreColors.pointsBadgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pointsAdded,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LendingScoreColors.pointsText,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: LendingScoreColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: LendingScoreColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}