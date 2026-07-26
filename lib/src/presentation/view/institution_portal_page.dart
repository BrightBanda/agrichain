import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/loan.dart';
import '../../utils/pill_badge.dart';
import '../../utils/section_header.dart';
import '../../utils/stat_tile.dart';
import '../../utils/responsive.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/institution_view_model.dart';
import 'widgets/app_header.dart';
import 'widgets/ledger_widgets.dart';

/// The financial institution's portal (FR-17, FR-18).
///
/// This is where loans are verified: each application shows the applicant, the
/// lending score at the moment they applied, and what approving would commit
/// the institution to. Approving anchors the agreement to the ledger.
class InstitutionPortalPage extends ConsumerWidget {
  const InstitutionPortalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(institutionApplicationsProvider);
    final pending = ref.watch(pendingApplicationsProvider);
    final decided = ref.watch(decidedApplicationsProvider);

    final exposure = decided
        .where((loan) => loan.isActive)
        .fold<double>(0, (sum, loan) => sum + loan.outstandingBalance);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(institutionApplicationsProvider.notifier).refresh(),
          child: PageWidth(
            child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const AppHeader(
                subtitle: 'Loan Verification',
                roleLabel: 'Bank Admin',
              ),
              const SizedBox(height: 16),

              _InstitutionCard(
                name: user?.displayName ?? 'Financial Institution',
                pendingCount: pending.length,
              ),
              const SizedBox(height: 14),

              StatTileRow(
                tiles: [
                  StatTile(
                    label: 'To Review',
                    value: '${pending.length}',
                    caption: pending.isEmpty ? 'Nothing waiting' : 'Awaiting you',
                    captionColor: pending.isEmpty
                        ? AppColors.positive
                        : AppColors.warning,
                  ),
                  StatTile(
                    label: 'Decided',
                    value: '${decided.length}',
                    caption: 'Total decisions',
                  ),
                  StatTile(
                    label: 'Lent Out',
                    value: exposure > 0 ? formatMwkCompact(exposure) : formatMwk(0),
                    caption: 'Outstanding',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              switch (state) {
                AsyncValue(hasError: true, :final error) => LedgerErrorState(
                  message: '$error',
                  onRetry: () =>
                      ref.invalidate(institutionApplicationsProvider),
                ),
                AsyncValue(hasValue: true) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Awaiting Verification'),
                    const SizedBox(height: 10),
                    if (pending.isEmpty)
                      const _EmptyQueue()
                    else
                      for (final loan in pending)
                        _ApplicationCard(
                          loan: loan,
                          onDecide: (approve) =>
                              _decide(context, ref, loan, approve: approve),
                        ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Decision History'),
                    const SizedBox(height: 10),
                    if (decided.isEmpty)
                      const _NoHistory()
                    else
                      for (final loan in decided) _DecidedRow(loan: loan),
                  ],
                ),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              },
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    Loan loan, {
    required bool approve,
  }) async {
    final amountController = TextEditingController(
      text: loan.amountRequested.toStringAsFixed(0),
    );
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve application' : 'Decline application'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${loan.farmerName ?? 'This farmer'} requested '
                '${formatMwk(loan.amountRequested)} with a lending score of '
                '${loan.lendingScoreAtApplication}.',
                style: const TextStyle(fontSize: 12.5, height: 1.4),
              ),
              if (approve) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount to approve (MWK)',
                    helperText: 'Cannot exceed the amount requested',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: 'Note to the farmer (optional)',
                  hintText: approve
                      ? 'Approved on verified harvest history.'
                      : 'Reason for declining',
                  border: const OutlineInputBorder(),
                ),
              ),
              if (approve) ...[
                const SizedBox(height: 12),
                const Text(
                  'Approving writes the agreed terms to the AgriChain ledger, '
                  'where they cannot be altered afterwards.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: approve ? AppColors.primary : AppColors.danger,
            ),
            child: Text(approve ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false) || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final amount = approve
        ? double.tryParse(amountController.text.trim())
        : null;

    try {
      final decided = await ref
          .read(institutionApplicationsProvider.notifier)
          .decide(
            loanId: loan.id,
            approve: approve,
            amountApproved: amount,
            note: noteController.text.trim(),
          );

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: approve ? AppColors.primary : Colors.red.shade700,
            duration: const Duration(seconds: 5),
            content: Text(
              approve
                  ? 'Approved ${formatMwk(decided.amountApproved ?? 0)}. '
                        'Total payable ${formatMwk(decided.totalPayable ?? 0)}.'
                  : 'Application declined.',
            ),
          ),
        );
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
            content: Text('$error'),
          ),
        );
    }
  }
}

class _InstitutionCard extends StatelessWidget {
  final String name;
  final int pendingCount;

  const _InstitutionCard({required this.name, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.scoreTop, AppColors.scoreBottom],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance, size: 12, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'National Bank Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pendingCount == 0
                ? 'No applications waiting for a decision.'
                : '$pendingCount application(s) waiting for your decision.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Loan loan;
  final void Function(bool approve) onDecide;

  const _ApplicationCard({required this.loan, required this.onDecide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardTint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 19,
                  color: AppColors.primaryMuted,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.farmerName ?? 'Unnamed applicant',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeading,
                      ),
                    ),
                    if (loan.farmerPhone != null)
                      Text(
                        loan.farmerPhone!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              _ScoreBadge(score: loan.lendingScoreAtApplication),
            ],
          ),
          const SizedBox(height: 13),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Metric(
                  label: 'Requested',
                  value: formatMwk(loan.amountRequested),
                ),
                _Metric(
                  label: 'Interest',
                  value: '${loan.interestRate.toStringAsFixed(1)}%',
                ),
                _Metric(
                  label: 'If Approved',
                  value: formatMwk(loan.projectedTotalPayable),
                ),
              ],
            ),
          ),
          if (loan.appliedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Applied ${formatRelativeDate(loan.appliedAt!)}'
              '${loan.repaymentPeriodMonths == null ? '' : ' • ${loan.repaymentPeriodMonths} month term'}',
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onDecide(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => onDecide(true),
                  icon: const Icon(Icons.verified_outlined, size: 16),
                  label: const Text(
                    'Verify & Approve',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    // Banded so a reviewer reads risk at a glance rather than a bare number.
    final (background, foreground) = score >= 550
        ? (AppColors.accentSoft, AppColors.primary)
        : score >= 400
              ? (AppColors.warningSoft, AppColors.warning)
              : (AppColors.dangerSoft, AppColors.danger);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PillBadge(
          text: '$score pts',
          background: background,
          foreground: foreground,
          dense: true,
        ),
        const SizedBox(height: 3),
        const Text(
          'at application',
          style: TextStyle(fontSize: 8.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecidedRow extends StatelessWidget {
  final Loan loan;

  const _DecidedRow({required this.loan});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (loan.status) {
      LoanStatus.active => (AppColors.warningSoft, AppColors.warning),
      LoanStatus.repaid => (AppColors.accentSoft, AppColors.primary),
      LoanStatus.rejected => (AppColors.dangerSoft, AppColors.danger),
      LoanStatus.pending => (AppColors.surfaceMuted, AppColors.textMuted),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.farmerName ?? 'Unnamed applicant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loan.status == LoanStatus.rejected
                      ? 'Declined • requested ${formatMwk(loan.amountRequested)}'
                      : 'Approved ${formatMwk(loan.amountApproved ?? 0)} • '
                            '${formatMwk(loan.outstandingBalance)} outstanding',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillBadge(
            text: loan.status.label,
            background: background,
            foreground: foreground,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'Nothing to verify',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Applications appear here as farmers apply for the loan products '
            'your institution has published.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHistory extends StatelessWidget {
  const _NoHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text(
        'No decisions recorded yet.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
      ),
    );
  }
}
