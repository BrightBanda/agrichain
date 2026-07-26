import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/harvest.dart';
import '../../data/models/lending_score.dart';
import '../../data/models/score_history.dart';
import '../../utils/analytics_colors.dart';
import '../../utils/monthly_progress_bar.dart';
import '../../utils/pill_badge.dart';
import '../../utils/sample_data_notice.dart';
import '../../utils/score_ring.dart';
import '../../utils/section_header.dart';
import '../../utils/segmented_toggle.dart';
import '../../utils/stat_tile.dart';
import '../../utils/work_log_tile.dart';
import '../viewmodel/analytics_view_model.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/farmer_dashboard_view_model.dart';
import 'widgets/app_header.dart';
import 'widgets/ledger_widgets.dart';

/// My Analytics: Overview, Lending Score, and Farm & Harvest.
///
/// Lending Score and Farm & Harvest run on live data. Income, spending and the
/// monthly chart cannot: AgriChain records harvests, listings, loans and
/// repayments, but has no sales or purchase ledger, so those sections keep the
/// designed layout behind an explicit sample-data notice.
class MyAnalyticsPage extends ConsumerStatefulWidget {
  const MyAnalyticsPage({super.key});

  @override
  ConsumerState<MyAnalyticsPage> createState() => _MyAnalyticsPageState();
}

class _MyAnalyticsPageState extends ConsumerState<MyAnalyticsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dashboard = ref.watch(farmerDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(farmerDashboardProvider.notifier).refresh();
            ref.invalidate(scoreHistoryProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const AppHeader(subtitle: 'My Analytics'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bar_chart,
                              size: 19,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'My Analytics',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Financial & agricultural performance for '
                          '${user?.displayName ?? 'your farm'}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // No report generator exists, so this states that plainly.
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'PDF export is not built yet — there is no report '
                            'endpoint.',
                          ),
                        ),
                      ),
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SegmentedToggle(
                scrollable: true,
                selectedIndex: _tab,
                options: const [
                  ToggleOption(label: 'Overview', icon: Icons.dashboard_outlined),
                  ToggleOption(
                    label: 'Lending Score',
                    icon: Icons.emoji_events_outlined,
                  ),
                  ToggleOption(
                    label: 'Farm & Harvest',
                    icon: Icons.grass_outlined,
                  ),
                ],
                onSelected: (index) => setState(() => _tab = index),
              ),
              const SizedBox(height: 18),

              switch (dashboard) {
                AsyncValue(hasError: true, :final error) => LedgerErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(farmerDashboardProvider),
                ),
                AsyncValue(hasValue: true, :final value?) => switch (_tab) {
                  1 => _LendingScoreTab(score: value.score),
                  2 => _FarmHarvestTab(dashboard: value),
                  _ => _OverviewTab(dashboard: value),
                },
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  final FarmerDashboard dashboard;

  const _OverviewTab({required this.dashboard});

  /// Illustrative monthly series. Kept as a named constant so it is obvious in
  /// the code that these are not measurements.
  static const _sampleMonths = [
    ('Mar 2026', 450000.0, 0.15, 0.05),
    ('Apr 2026', 1200000.0, 0.30, 0.07),
    ('May 2026', 1800000.0, 0.45, 0.08),
    ('Jun 2026', 3100000.0, 0.72, 0.10),
    ('Jul 2026', 2800000.0, 0.66, 0.09),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real metrics first, so the page leads with what AgriChain can prove.
        const SectionHeader(title: 'Your Records'),
        const SizedBox(height: 10),
        StatTileRow(
          tiles: [
            StatTile(
              label: 'Lending Score',
              value: '${dashboard.score.score}',
              caption: dashboard.score.tier.label,
              captionColor: AppColors.positive,
            ),
            StatTile(
              label: 'Verified Harvests',
              value: '${dashboard.verifiedHarvestCount}',
              caption: 'of ${dashboard.harvests.length} recorded',
            ),
            StatTile(
              label: 'Money Owed',
              value: dashboard.moneyOwed > 0
                  ? formatMwkCompact(dashboard.moneyOwed)
                  : formatMwk(0),
              caption: dashboard.moneyOwed > 0 ? 'Outstanding' : 'Nothing owed',
              captionColor: dashboard.moneyOwed > 0
                  ? AppColors.warning
                  : AppColors.positive,
            ),
          ],
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'Income vs Spending'),
        const SizedBox(height: 10),
        const SampleDataNotice(
          explanation:
              'AgriChain has no sales or purchase ledger yet, so income and '
              'spending cannot be measured. The figures below illustrate the '
              'layout only.',
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Income Summary',
                amount: 'MWK 3,090,000',
                caption: 'Verified sales from harvest',
                filled: true,
                trendUp: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Spending Summary',
                amount: 'MWK 245,000',
                caption: 'Inputs, labour & equipment',
                filled: false,
                trendUp: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'MONTHLY INCOME VS SPENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: AnalyticsColors.textSecondary,
                      ),
                    ),
                  ),
                  PillBadge(
                    text: 'Sample',
                    background: AppColors.warningSoft,
                    foreground: AppColors.warning,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final (month, amount, income, spending) in _sampleMonths)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: MonthlyProgressBar(
                    month: month,
                    amount: '+${formatMwk(amount)}',
                    incomeRatio: income,
                    spendingRatio: spending,
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(
                    color: AnalyticsColors.primaryGreen,
                    label: 'Income',
                  ),
                  const SizedBox(width: 18),
                  _LegendDot(
                    color: AnalyticsColors.orangeAccent,
                    label: 'Spending',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final String caption;
  final bool filled;
  final bool trendUp;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.caption,
    required this.filled,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    final onFilled = filled;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: onFilled ? Colors.white70 : AppColors.textMuted,
                  ),
                ),
              ),
              Icon(
                trendUp ? Icons.arrow_outward : Icons.south_west,
                size: 14,
                color: onFilled ? Colors.white70 : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: onFilled ? Colors.white : AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: 2,
            style: TextStyle(
              fontSize: 9.5,
              height: 1.3,
              color: onFilled ? Colors.white70 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: AnalyticsColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Lending Score — entirely live data
// ---------------------------------------------------------------------------

class _LendingScoreTab extends ConsumerWidget {
  final LendingScore score;

  const _LendingScoreTab({required this.score});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scoreHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.scoreTop, AppColors.scoreBottom],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${score.score} / ${LendingScore.maxScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score.tier.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Borrowing headroom ${formatMwk(score.borrowCapacity)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              ScoreRing(progress: score.progress, size: 70),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'Why Your Score Is This'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              for (final reason in score.reasons)
                Padding(
                  padding: const EdgeInsets.all(11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'Lending Score History'),
        const SizedBox(height: 10),
        switch (history) {
          AsyncValue(hasError: true, :final error) => LedgerErrorState(
            message: '$error',
            onRetry: () => ref.invalidate(scoreHistoryProvider),
          ),
          AsyncValue(hasValue: true, :final value?) => value.isEmpty
              ? const _EmptyHistory()
              : Column(
                  children: [
                    for (final entry in value) _HistoryRow(entry: entry),
                  ],
                ),
          _ => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        },
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ScoreHistoryEntry entry;

  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rose = entry.improved;
    final flat = entry.change == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: flat
                  ? AppColors.surfaceMuted
                  : rose
                        ? AppColors.accentSoft
                        : AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              flat
                  ? Icons.remove
                  : rose
                        ? Icons.trending_up
                        : Icons.trending_down,
              size: 17,
              color: flat
                  ? AppColors.textMuted
                  : rose
                        ? AppColors.primary
                        : AppColors.danger,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${entry.previousScore} → ${entry.score}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!flat)
                      PillBadge(
                        text: '${rose ? '+' : ''}${entry.change}',
                        dense: true,
                        background: rose
                            ? AppColors.accentSoft
                            : AppColors.dangerSoft,
                        foreground: rose ? AppColors.primary : AppColors.danger,
                      ),
                  ],
                ),
                if (entry.headlineReason != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.headlineReason!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (entry.calculatedAt != null) ...[
            const SizedBox(width: 8),
            Text(
              formatShortDate(entry.calculatedAt!),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text(
        'No score changes recorded yet. Your history builds as harvests are '
        'verified and loans are repaid.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          color: AppColors.textMuted,
          height: 1.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Farm & Harvest — live data
// ---------------------------------------------------------------------------

class _FarmHarvestTab extends StatelessWidget {
  final FarmerDashboard dashboard;

  const _FarmHarvestTab({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final harvests = dashboard.harvests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatTileRow(
          tiles: [
            StatTile(
              label: 'Recorded Crop',
              value: harvests.isEmpty
                  ? '—'
                  : '${formatQuantity(dashboard.totalHarvestQuantity)} '
                        '${dashboard.harvestUnitLabel}',
              caption: dashboard.hasMixedHarvestUnits
                  ? 'Mixed units'
                  : '${harvests.length} record(s)',
            ),
            StatTile(
              label: 'Verified',
              value: '${dashboard.verifiedHarvestCount}',
              caption: 'Independently confirmed',
              captionColor: dashboard.verifiedHarvestCount > 0
                  ? AppColors.positive
                  : AppColors.textMuted,
            ),
            const StatTile(
              label: 'Registered Plots',
              // The farm module (FR-04) does not exist, so no plot count.
              value: '—',
              caption: 'Not yet supported',
            ),
          ],
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'Harvest Records'),
        const SizedBox(height: 10),
        if (harvests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'No harvests recorded yet. Recording a harvest and having your '
              'cooperative verify it is what raises your lending score.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          )
        else
          for (final harvest in _sorted(harvests))
            WorkLogTile(
              icon: Icons.agriculture_outlined,
              title: harvest.cropName,
              subtitle:
                  '${formatQuantity(harvest.quantity)} '
                  '${harvest.unitType.label} • ${harvest.season} • '
                  '${harvest.district}',
              trailing: harvest.harvestDate == null
                  ? ''
                  : formatShortDate(harvest.harvestDate!),
              statusLabel: harvest.isVerified ? 'Verified' : 'Pending',
              isVerified: harvest.isVerified,
            ),
      ],
    );
  }

  List<Harvest> _sorted(List<Harvest> harvests) {
    final sorted = [...harvests];
    sorted.sort((a, b) {
      final left = a.harvestDate ?? a.createdAt ?? DateTime(1970);
      final right = b.harvestDate ?? b.createdAt ?? DateTime(1970);
      return right.compareTo(left);
    });
    return sorted;
  }
}
