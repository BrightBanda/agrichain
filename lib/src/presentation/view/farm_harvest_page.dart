import 'package:agri/src/utils/farm_harvest_colors.dart';
import 'package:agri/src/utils/farm_plot_item_card.dart';
import 'package:agri/src/utils/farm_summary_card.dart';
import 'package:flutter/material.dart';

class FarmHarvestPage extends StatelessWidget {
  const FarmHarvestPage({super.key});

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
                              color: FarmHarvestColors.primaryGreen,
                              size: 26,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'My Analytics',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: FarmHarvestColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Financial & agricultural performance metrics for Kondwani Phiri',
                          style: TextStyle(
                            fontSize: 11,
                            color: FarmHarvestColors.textMuted,
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
                      color: FarmHarvestColors.primaryGreen,
                    ),
                    label: const Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: FarmHarvestColors.primaryGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: FarmHarvestColors.lightGreenBg,
                      side: const BorderSide(color: FarmHarvestColors.borderGreen),
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

              // 2. Navigation Tab Pills
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
                          Icon(Icons.style_outlined, size: 14, color: FarmHarvestColors.primaryGreen),
                          SizedBox(width: 6),
                          Text(
                            'Overview',
                            style: TextStyle(
                              color: FarmHarvestColors.textPrimary,
                              fontWeight: FontWeight.w600,
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
                          Icon(Icons.emoji_events_outlined, size: 14, color: Colors.orange),
                          SizedBox(width: 6),
                          Text(
                            'Lending Score',
                            style: TextStyle(
                              color: FarmHarvestColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Farm & Harvest Pill (Active)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: FarmHarvestColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: FarmHarvestColors.primaryGreen.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.grass_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Farm & Harvest',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

              // 3. Farm & Harvest Analytics Main Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: FarmHarvestColors.outerCardBorder),
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
                    // Section Header
                    Row(
                      children: const [
                        Icon(
                          Icons.grass_outlined,
                          color: FarmHarvestColors.primaryGreen,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'FARM & HARVEST ANALYTICS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: FarmHarvestColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Top Metrics Summary Grid Row
                    Row(
                      children: const [
                        Expanded(
                          child: FarmSummaryCard(
                            label: 'Total Land Under\nCultivation',
                            value: '12.5',
                            valueUnit: 'Acres',
                            subtext: '100% Verified Titled',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: FarmSummaryCard(
                            label: 'Expected Harvest Yield\n',
                            value: '350',
                            valueUnit: 'Bags',
                            subtext: 'Maize & Groundnuts',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Farm Performance Breakdown Header
                    const Text(
                      'Farm Performance Breakdown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: FarmHarvestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Plot Breakdown Cards
                    const FarmPlotItemCard(
                      title: 'Lilongwe Main Maize Garden',
                      subtitle: '7.5 Acres • Maize (Chimanga Hybrid)',
                      healthScore: '94%',
                      expectedBags: '240',
                    ),
                    const SizedBox(height: 10),

                    const FarmPlotItemCard(
                      title: 'Kasungu Groundnut & Beans Plot',
                      subtitle: '5 Acres • Groundnuts & Beans',
                      healthScore: '88%',
                      expectedBags: '110',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Official Monthly Report Export Banner
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: FarmHarvestColors.lightGreenBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FarmHarvestColors.borderGreen),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: FarmHarvestColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.article_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Monthly Report',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: FarmHarvestColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Download complete audited records for bank & loan applications.',
                            style: TextStyle(
                              fontSize: 10,
                              color: FarmHarvestColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FarmHarvestColors.primaryGreen,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}