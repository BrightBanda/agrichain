import 'package:agri/src/utils/analytics_colors.dart';
import 'package:agri/src/utils/monthly_progress_bar.dart';
import 'package:flutter/material.dart';

class MyAnalyticsPage extends StatelessWidget {
  const MyAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Title & Export PDF Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.bar_chart_rounded,
                              color: AnalyticsColors.primaryGreen,
                              size: 26,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'My Analytics',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AnalyticsColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Financial & agricultural performance metrics for Kondwani Phiri',
                          style: TextStyle(
                            fontSize: 11,
                            color: AnalyticsColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 14,
                      color: AnalyticsColors.primaryGreen,
                    ),
                    label: const Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AnalyticsColors.primaryGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AnalyticsColors.lightGreenBg,
                      side: const BorderSide(color: AnalyticsColors.greenBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Filter Pills Navigation
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Overview Pill (Active)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AnalyticsColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AnalyticsColors.primaryGreen.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.style_outlined, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Lending Score Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.emoji_events_outlined, size: 14, color: AnalyticsColors.orangeText),
                          SizedBox(width: 6),
                          Text(
                            'Lending Score',
                            style: TextStyle(
                              color: AnalyticsColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Farm & Harvest Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.grass_rounded, size: 14, color: AnalyticsColors.primaryGreen),
                          SizedBox(width: 6),
                          Text(
                            'Farm & Harvest',
                            style: TextStyle(
                              color: AnalyticsColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Summary Cards (Income vs Spending)
              Row(
                children: [
                  // Income Summary Card (Dark Green)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AnalyticsColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Income Summary',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(Icons.north_east_rounded, size: 16, color: Colors.white70),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'MWK',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            '3,090,000',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Verified Sales from Harvest',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Spending Summary Card (White)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Spending Summary',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AnalyticsColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(Icons.south_east_rounded, size: 16, color: AnalyticsColors.orangeAccent),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'MWK',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AnalyticsColors.textPrimary,
                            ),
                          ),
                          const Text(
                            '245,000',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AnalyticsColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Inputs, Labor & Equipment',
                            style: TextStyle(
                              fontSize: 9,
                              color: AnalyticsColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Monthly Income vs Spending Bar Chart Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title & Month Picker Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'MONTHLY INCOME VS SPENDING\nCHART',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AnalyticsColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AnalyticsColors.lightGreenBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AnalyticsColors.greenBorder),
                          ),
                          child: Row(
                            children: const [
                              Text(
                                'July 2026',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AnalyticsColors.primaryGreen,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: AnalyticsColors.primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Progress Bars Stack
                    const MonthlyProgressBar(
                      month: 'Mar 2026',
                      amount: '+450000 MWK',
                      incomeRatio: 0.20,
                      spendingRatio: 0.25,
                    ),
                    const SizedBox(height: 16),

                    const MonthlyProgressBar(
                      month: 'Apr 2026',
                      amount: '+1200000 MWK',
                      incomeRatio: 0.45,
                      spendingRatio: 0.10,
                    ),
                    const SizedBox(height: 16),

                    const MonthlyProgressBar(
                      month: 'May 2026',
                      amount: '+1800000 MWK',
                      incomeRatio: 0.65,
                      spendingRatio: 0.15,
                    ),
                    const SizedBox(height: 16),

                    const MonthlyProgressBar(
                      month: 'Jun 2026',
                      amount: '+3100000 MWK',
                      incomeRatio: 0.90,
                      spendingRatio: 0.10,
                    ),
                    const SizedBox(height: 16),

                    const MonthlyProgressBar(
                      month: 'Jul 2026',
                      amount: '+2800000 MWK',
                      incomeRatio: 0.82,
                      spendingRatio: 0.12,
                    ),
                    const SizedBox(height: 24),

                    // Legend Footer (Income / Spending)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AnalyticsColors.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Income',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AnalyticsColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AnalyticsColors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Spending',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AnalyticsColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}