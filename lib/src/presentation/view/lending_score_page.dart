import 'package:agri/src/utils/lending_score_colors.dart';
import 'package:agri/src/utils/lending_score_item_card.dart';
import 'package:agri/src/utils/official_report_card.dart';
import 'package:flutter/material.dart';

class LendingScorePage extends StatelessWidget {
  const LendingScorePage({super.key});

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
              // 1. Header Title & PDF Export Action
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
                              color: LendingScoreColors.primaryGreen,
                              size: 26,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'My Analytics',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: LendingScoreColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Financial & agricultural performance metrics for Kondwani Phiri',
                          style: TextStyle(
                            fontSize: 11,
                            color: LendingScoreColors.textMuted,
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
                      color: LendingScoreColors.primaryGreen,
                    ),
                    label: const Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: LendingScoreColors.primaryGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: LendingScoreColors.lightGreenBg,
                      side: const BorderSide(color: LendingScoreColors.borderGreen),
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

              // 2. Navigation Pills Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Overview Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.style_outlined, size: 14, color: LendingScoreColors.primaryGreen),
                          SizedBox(width: 6),
                          Text(
                            'Overview',
                            style: TextStyle(
                              color: LendingScoreColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Lending Score Pill (Active)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: LendingScoreColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: LendingScoreColors.primaryGreen.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.emoji_events_outlined, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Lending Score',
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
                          Icon(Icons.grass_rounded, size: 14, color: LendingScoreColors.primaryGreen),
                          SizedBox(width: 6),
                          Text(
                            'Farm & Harvest',
                            style: TextStyle(
                              color: LendingScoreColors.textPrimary,
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

              // 3. Lending Score History Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: LendingScoreColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Container Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.workspace_premium_outlined,
                              color: LendingScoreColors.primaryGreen,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'LENDING SCORE HISTORY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: LendingScoreColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        // Gold Tier Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: LendingScoreColors.goldTierBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Gold Tier (742 / 850)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: LendingScoreColors.goldTierText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Score Item Cards
                    const LendingScoreItemCard(
                      score: '742 Score',
                      pointsAdded: '+12 pts',
                      description: 'Paid back input voucher installment on time',
                      date: 'Jul 2026',
                    ),
                    const SizedBox(height: 10),

                    const LendingScoreItemCard(
                      score: '730 Score',
                      pointsAdded: '+25 pts',
                      description: 'Verified 45 bags maize sale with NFRA',
                      date: 'Jun 2026',
                    ),
                    const SizedBox(height: 10),

                    const LendingScoreItemCard(
                      score: '705 Score',
                      pointsAdded: '+18 pts',
                      description: 'Updated farm boundary satellite data',
                      date: 'May 2026',
                    ),
                    const SizedBox(height: 10),

                    const LendingScoreItemCard(
                      score: '687 Score',
                      pointsAdded: '+30 pts',
                      description: 'Successfully completed Cycle 4 repayment',
                      date: 'Jan 2026',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Official Monthly Report Banner Component
              const OfficialReportCard(),
            ],
          ),
        ),
      ),
    );
  }
}