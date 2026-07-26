import 'package:flutter/material.dart';
import 'analytics_colors.dart';

class MonthlyProgressBar extends StatelessWidget {
  final String month;
  final String amount;
  final double incomeRatio;  // Value between 0.0 and 1.0
  final double spendingRatio; // Value between 0.0 and 1.0

  const MonthlyProgressBar({
    super.key,
    required this.month,
    required this.amount,
    required this.incomeRatio,
    required this.spendingRatio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              month,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AnalyticsColors.textSecondary,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AnalyticsColors.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final double incomeWidth = maxWidth * incomeRatio;
            final double spendingWidth = maxWidth * spendingRatio;

            return Stack(
              children: [
                // Base Track (Grey)
                Container(
                  height: 10,
                  width: maxWidth,
                  decoration: BoxDecoration(
                    color: AnalyticsColors.trackGrey,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                // Combined Green & Orange Bar
                Row(
                  children: [
                    Container(
                      height: 10,
                      width: incomeWidth,
                      decoration: BoxDecoration(
                        color: AnalyticsColors.primaryGreen,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(5),
                          bottomLeft: const Radius.circular(5),
                          topRight: Radius.circular(spendingWidth > 0 ? 0 : 5),
                          bottomRight: Radius.circular(spendingWidth > 0 ? 0 : 5),
                        ),
                      ),
                    ),
                    Container(
                      height: 10,
                      width: spendingWidth,
                      decoration: const BoxDecoration(
                        color: AnalyticsColors.orangeAccent,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}