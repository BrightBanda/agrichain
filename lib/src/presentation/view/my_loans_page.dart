import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/farm_repository.dart';
import '../../utils/pill_badge.dart';
import '../../utils/section_header.dart';
import '../viewmodel/farmer_dashboard_view_model.dart';
import 'widgets/ledger_widgets.dart';

/// The farmer's own loans and their repayment state (FR-19, FR-20).
///
/// Reached from the balance link on the loan marketplace.
class MyLoansPage extends ConsumerWidget {
  const MyLoansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(farmerDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        title: const Text(
          'My Loans',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(farmerDashboardProvider.notifier).refresh(),
          child: switch (state) {
            AsyncValue(hasError: true, :final error) => LedgerErrorState(
              message: '$error',
              onRetry: () => ref.invalidate(farmerDashboardProvider),
            ),
            AsyncValue(hasValue: true, :final value?) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _OwedSummary(owed: value.moneyOwed),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Loan History'),
                const SizedBox(height: 10),
                if (value.loans.isEmpty)
                  const _NoLoans()
                else
                  for (final loan in value.loans)
                    _LoanCard(
                      loan: loan,
                      onRepay: loan.isActive
                          ? () => _repay(context, ref, loan)
                          : null,
                    ),
              ],
            ),
            _ => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          },
        ),
      ),
    );
  }

  Future<void> _repay(BuildContext context, WidgetRef ref, Loan loan) async {
    final controller = TextEditingController(
      text: loan.outstandingBalance.toStringAsFixed(0),
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Make a repayment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outstanding balance: ${formatMwk(loan.outstandingBalance)}',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (MWK)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(double.tryParse(controller.text.trim())),
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (amount == null || amount <= 0 || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(farmRepositoryProvider).repayLoan(
        loanId: loan.id,
        amount: amount,
        // The backend rejects duplicate references, which is what stops a
        // double-tap from being recorded as two payments.
        reference: 'APP-${DateTime.now().microsecondsSinceEpoch}',
      );
      await ref.read(farmerDashboardProvider.notifier).refresh();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Repayment of ${formatMwk(amount)} recorded.'),
          ),
        );
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('$error'),
          ),
        );
    }
  }
}

class _OwedSummary extends StatelessWidget {
  final double owed;

  const _OwedSummary({required this.owed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total still to pay back',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            formatMwk(owed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (owed <= 0) ...[
            const SizedBox(height: 4),
            const Text(
              'You have no outstanding loans.',
              style: TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback? onRepay;

  const _LoanCard({required this.loan, this.onRepay});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (loan.status) {
      LoanStatus.active => (AppColors.warningSoft, AppColors.warning),
      LoanStatus.repaid => (AppColors.accentSoft, AppColors.primary),
      LoanStatus.rejected => (AppColors.dangerSoft, AppColors.danger),
      LoanStatus.pending => (AppColors.surfaceMuted, AppColors.textMuted),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  formatMwk(loan.amountApproved ?? loan.amountRequested),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              PillBadge(
                text: loan.status.label,
                background: background,
                foreground: foreground,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${loan.interestRate.toStringAsFixed(1)}% interest'
            '${loan.repaymentPeriodMonths == null ? '' : ' • ${loan.repaymentPeriodMonths} months'}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          if (loan.totalPayable != null) ...[
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Total payable',
              value: formatMwk(loan.totalPayable!),
            ),
            _DetailRow(label: 'Repaid', value: formatMwk(loan.amountRepaid)),
            _DetailRow(
              label: 'Outstanding',
              value: formatMwk(loan.outstandingBalance),
              emphasise: loan.outstandingBalance > 0,
            ),
            if (loan.dueDate != null)
              _DetailRow(
                label: loan.isOverdue ? 'Overdue since' : 'Due',
                value: formatFullDate(loan.dueDate!),
                emphasise: loan.isOverdue,
              ),
          ],
          if (loan.decisionNote != null && loan.decisionNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              loan.decisionNote!,
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (onRepay != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRepay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Pay Back',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasise;

  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: emphasise ? AppColors.danger : AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLoans extends StatelessWidget {
  const _NoLoans();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 34,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'No loans yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Apply from the loan marketplace and your applications will appear '
            'here.',
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
