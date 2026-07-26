import 'package:flutter/material.dart';
import 'farm_harvest_colors.dart';

class FarmSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String valueUnit;
  final String subtext;

  const FarmSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.valueUnit,
    required this.subtext,
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
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: FarmHarvestColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FarmHarvestColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                valueUnit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FarmHarvestColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: FarmHarvestColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}