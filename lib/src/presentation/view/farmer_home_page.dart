import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/user.dart';
import '../../utils/active_loan_card.dart';
import '../../utils/money_score_card.dart';
import '../../utils/profile_summary_card.dart';
import '../../utils/quick_action_tile.dart';
import '../../utils/section_header.dart';
import '../../utils/stat_tile.dart';
import '../../utils/status_notice_card.dart';
import '../../utils/weather_card.dart';
import '../../utils/work_log_tile.dart';
import '../../utils/responsive.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/farmer_dashboard_view_model.dart';
import 'blockchain_explorer_page.dart';
import 'record_harvest_page.dart';
import 'score_details_page.dart';
import 'widgets/app_header.dart';
import 'widgets/ledger_widgets.dart';

/// The farmer's home screen.
///
/// Everything shown is derived from the backend — score, tier, borrowing
/// headroom, money owed, harvest totals and verification state — except the
/// weather card and the plot count, which have no data source yet and are
/// labelled as such on screen.
class FarmerHomePage extends ConsumerWidget {
  /// Lets the bottom nav jump to another tab from a quick action.
  final void Function(int index)? onNavigateToTab;

  const FarmerHomePage({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(farmerDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(farmerDashboardProvider.notifier).refresh(),
          child: PageWidth(
            child: switch (state) {
            AsyncValue(hasError: true, :final error) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const AppHeader(subtitle: 'Home'),
                const SizedBox(height: 40),
                LedgerErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(farmerDashboardProvider),
                ),
              ],
            ),
            AsyncValue(hasValue: true, :final value?) => _Dashboard(
              user: user,
              dashboard: value,
              header: const AppHeader(subtitle: 'Home'),
              onNavigateToTab: onNavigateToTab,
            ),
            _ => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const AppHeader(subtitle: 'Home'),
                const SizedBox(height: 80),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ],
            ),
          }),
        ),
      ),
    );
  }

  static void _notAvailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature is not available yet.')),
      );
  }

  static String? _initials(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

}

class _Dashboard extends ConsumerWidget {
  final User? user;
  final FarmerDashboard dashboard;
  final Widget header;
  final void Function(int index)? onNavigateToTab;

  const _Dashboard({
    required this.user,
    required this.dashboard,
    required this.header,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = user?.farmerProfile;
    final score = dashboard.score;
    final loan = dashboard.activeLoan;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        header,
        const SizedBox(height: 16),

        // Registration status, straight from User.isVerified.
        if (user != null) _registrationNotice(context, user!),
        const SizedBox(height: 12),

        ProfileSummaryCard(
          greeting: 'Muli Bwanji, Welcome back 👋',
          name: user?.displayName ?? 'Farmer',
          location: [
            if (profile?.district.isNotEmpty ?? false) profile!.district,
            // The farms module does not exist yet, so plots are not counted.
            'No plots registered',
          ].join(' • '),
          registrationId: profile == null ? null : _shortId(profile.id),
          tierLabel: score.tier.label,
          avatarInitials: FarmerHomePage._initials(user?.displayName),
        ),
        const SizedBox(height: 12),

        MoneyScoreCard(
          score: score.score,
          progress: score.progress,
          tierSummary: score.tier.summary,
          borrowCapacityText: formatMwkCompact(score.borrowCapacity),
          strengths: score.strengths,
          change: score.change,
          onSeeDetails: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScoreDetailsPage(score: score),
            ),
          ),
        ),
        const SizedBox(height: 12),

        WeatherCard(
          weather: WeatherSnapshot.placeholder(profile?.district ?? ''),
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 10),
        QuickActionRow(
          actions: [
            QuickActionTile(
              icon: Icons.grass_outlined,
              label: 'My Gardens',
              onTap: () => onNavigateToTab?.call(0),
            ),
            QuickActionTile(
              icon: Icons.shopping_bag_outlined,
              label: 'Buy',
              onTap: () => onNavigateToTab?.call(1),
            ),
            QuickActionTile(
              icon: Icons.account_balance_outlined,
              label: 'Get Loan',
              onTap: () => onNavigateToTab?.call(3),
            ),
            QuickActionTile(
              icon: Icons.add,
              label: 'Log Work',
              filled: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecordHarvestPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StatTileRow(
          tiles: [
            StatTile(
              label: 'Total Garden',
              // No farms module, so this is honestly empty rather than invented.
              value: '—',
              caption: 'No plots registered',
            ),
            StatTile(
              label: 'Money Owed',
              value: dashboard.moneyOwed > 0
                  ? formatMwk(dashboard.moneyOwed)
                  : formatMwk(0),
              caption: loan?.dueDate == null
                  ? (dashboard.moneyOwed > 0 ? 'Repayment due' : 'Nothing owed')
                  : 'Due ${formatShortDate(loan!.dueDate!)}',
              captionColor: dashboard.moneyOwed > 0
                  ? (loan?.isOverdue ?? false
                        ? AppColors.danger
                        : AppColors.warning)
                  : AppColors.positive,
            ),
            StatTile(
              label: 'Recorded Crop',
              value: dashboard.harvests.isEmpty
                  ? '—'
                  : '${formatQuantity(dashboard.totalHarvestQuantity)} '
                        '${dashboard.harvestUnitLabel}',
              caption: dashboard.harvests.isEmpty
                  ? 'No harvests yet'
                  : '${dashboard.verifiedHarvestCount} verified',
              captionColor: dashboard.verifiedHarvestCount > 0
                  ? AppColors.positive
                  : AppColors.textMuted,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (loan != null)
          ActiveLoanCard(
            title: 'Loan (${formatMwk(loan.amountApproved ?? 0)} approved)',
            balanceText: formatMwk(loan.outstandingBalance),
            dueText: loan.dueDate == null
                ? null
                : loan.isOverdue
                      ? 'Overdue'
                      : 'Due ${formatShortDate(loan.dueDate!)}',
            isOverdue: loan.isOverdue,
            progress: loan.repaymentProgress,
            onAction: () => onNavigateToTab?.call(3),
          )
        else
          _NoActiveLoanCard(
            capacityText: formatMwkCompact(score.borrowCapacity),
            onBrowse: () => onNavigateToTab?.call(3),
          ),
        const SizedBox(height: 20),

        SectionHeader(
          title: 'Recent Garden Work',
          actionLabel: 'Record Work',
          onAction: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecordHarvestPage()),
            );
            await ref.read(farmerDashboardProvider.notifier).refresh();
          },
        ),
        const SizedBox(height: 10),
        if (dashboard.recentWork.isEmpty)
          _EmptyWork()
        else
          for (final harvest in dashboard.recentWork)
            WorkLogTile(
              icon: Icons.agriculture_outlined,
              title: harvest.cropName,
              subtitle:
                  '${formatQuantity(harvest.quantity)} '
                  '${harvest.unitType.label} • ${harvest.season}',
              trailing: harvest.harvestDate == null
                  ? ''
                  : formatRelativeDate(harvest.harvestDate!),
              statusLabel: harvest.isVerified ? 'Verified' : 'Pending',
              isVerified: harvest.isVerified,
            ),
        const SizedBox(height: 12),

        // The ledger is the platform's differentiator, so it gets a way in.
        _LedgerLink(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BlockchainExplorerPage()),
          ),
        ),
      ],
    );
  }

  Widget _registrationNotice(BuildContext context, User user) {
    if (user.isVerified) {
      return StatusNoticeCard.positive(
        icon: Icons.verified_outlined,
        title: 'Registration Approved',
        message:
            'Your identity has been verified. You can apply for loans from '
            'connected institutions.',
        badgeText: 'Approved',
      );
    }

    return StatusNoticeCard(
      icon: Icons.schedule,
      title: 'Registration Status: Pending Approval',
      badgeText: 'Pending Approval',
      message:
          'Awaiting review by a loan institution. Your details are already '
          'anchored to the ledger and cannot be altered.',
      actionLabel: 'Download PDF',
      actionIcon: Icons.download,
      // No document service yet; the button says so rather than doing nothing.
      onAction: () =>
          FarmerHomePage._notAvailable(context, 'Registration PDF download'),
    );
  }

  static String _shortId(String id) =>
      id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();
}

class _NoActiveLoanCard extends StatelessWidget {
  final String capacityText;
  final VoidCallback? onBrowse;

  const _NoActiveLoanCard({required this.capacityText, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No active loan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your score qualifies you for up to $capacityText.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onBrowse,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Get Loan',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWork extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.agriculture_outlined, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'No farm work recorded yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Recording and verifying harvests is what raises your score.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LedgerLink extends StatelessWidget {
  final VoidCallback onTap;

  const _LedgerLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, size: 18, color: AppColors.primaryMuted),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'View your records on the AgriChain ledger',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}
