import 'package:flutter/material.dart';
import 'farm_harvest_colors.dart';

class FarmPlotItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String healthScore;
  final String expectedBags;

  const FarmPlotItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.healthScore,
    required this.expectedBags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: FarmHarvestColors.innerCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FarmHarvestColors.innerCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: FarmHarvestColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FarmHarvestColors.healthBadgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$healthScore Health',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: FarmHarvestColors.healthBadgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: FarmHarvestColors.textMuted,
                  ),
                ),
              ),
              Text(
                '$expectedBags Bags',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: FarmHarvestColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}