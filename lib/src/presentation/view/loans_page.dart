import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/lending_score.dart';
import '../../data/models/loan_product.dart';
import '../../utils/app_brand_header.dart';
import '../../utils/credit_header_card.dart';
import '../../utils/filter_bar.dart';
import '../../utils/loan_offer_card.dart';
import '../../utils/section_header.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/farmer_dashboard_view_model.dart';
import '../viewmodel/loan_marketplace_view_model.dart';
import 'my_loans_page.dart';
import 'widgets/ledger_widgets.dart';

/// The Agri Loan Marketplace (FR-15, FR-16).
///
/// Offers, eligibility and the apply flow all run against the live backend. The
/// farmer's own loans live on [MyLoansPage], reached from the balance link.
class LoansPage extends ConsumerWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashboard = ref.watch(farmerDashboardProvider);
    final offers = ref.watch(loanMarketplaceProvider);

    final score = dashboard.value?.score ?? LendingScore.initial();
    final owed = dashboard.value?.moneyOwed ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(loanMarketplaceProvider.notifier).refresh();
            await ref.read(farmerDashboardProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              AppBrandHeader(
                roleLabel: user?.role.label ?? 'Farmer',
                subtitle: 'Loans',
                avatarInitials: initialsOf(user?.displayName),
              ),
              const SizedBox(height: 16),

              CreditHeaderCard(
                title: 'Agri Loan Marketplace',
                badgeText: (user?.isVerified ?? false)
                    ? 'Approved Farmer Credit'
                    : 'Verification Pending',
                qualifyingText:
                    'Your lending score (${score.score} pts) qualifies you for '
                    'loans up to ${formatMwk(score.borrowCapacity)}. Each '
                    'institution still makes its own decision.',
                balanceLabel: owed > 0
                    ? 'My Current Balance'
                    : 'My Loan History',
                onBalanceTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyLoansPage()),
                ),
              ),
              const SizedBox(height: 16),

              const _Filters(),
              const SizedBox(height: 20),

              const SectionHeader(title: 'Available Loans'),
              const SizedBox(height: 12),

              switch (offers) {
                AsyncValue(hasError: true, :final error) => LedgerErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(loanMarketplaceProvider),
                ),
                AsyncValue(hasValue: true) => _Offers(score: score),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
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

/// Two initials for the avatar, shared by the screens that show the header.
String? initialsOf(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(loanTypeFilterProvider);
    final selectedInstitution = ref.watch(loanInstitutionFilterProvider);
    final institutions = ref.watch(loanInstitutionsProvider);
    final anyActive = selectedType != null || selectedInstitution != null;

    return Row(
      children: [
        Expanded(
          child: FilterDropdown<LoanType>(
            allLabel: 'All Loan Types',
            value: selectedType,
            options: LoanType.values,
            labelOf: (type) => type.label,
            emphasised: true,
            onChanged: (type) =>
                ref.read(loanTypeFilterProvider.notifier).select(type),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilterDropdown<String>(
            allLabel: 'All Institutions',
            value: selectedInstitution,
            options: institutions,
            labelOf: (name) => name,
            onChanged: (name) =>
                ref.read(loanInstitutionFilterProvider.notifier).select(name),
          ),
        ),
        const SizedBox(width: 10),
        FilterIconButton(
          active: anyActive,
          // Clears both filters; there is no further filter sheet yet.
          onTap: anyActive
              ? () {
                  ref.read(loanTypeFilterProvider.notifier).select(null);
                  ref.read(loanInstitutionFilterProvider.notifier).select(null);
                }
              : null,
        ),
      ],
    );
  }
}

class _Offers extends ConsumerWidget {
  final LendingScore score;

  const _Offers({required this.score});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(filteredLoanProductsProvider);
    final total = ref.watch(loanMarketplaceProvider).value?.length ?? 0;

    if (offers.isEmpty) {
      return _EmptyOffers(filtered: total > 0);
    }

    return Column(
      children: [
        for (final offer in offers)
          LoanOfferCard(
            institutionName: offer.institutionName ?? 'Financial Institution',
            name: offer.name,
            description: offer.description,
            monthlyFeeText: '${offer.monthlyFee.toStringAsFixed(1)}% / month',
            maxAmountText: formatMwk(offer.maxAmount),
            eligibilityText: offer.isEligible(score.score)
                ? 'Eligible'
                : '${offer.matchPercent(score.score)}% Match',
            isEligible: offer.isEligible(score.score),
            ineligibleHint: offer.isEligible(score.score)
                ? null
                : 'You need ${offer.pointsShort(score.score)} more points. '
                      'Record a harvest and have it verified to get there.',
            terms: offer.terms,
            actionLabel: offer.isEligible(score.score)
                ? 'Apply For ${offer.name}'
                : 'Not Yet Eligible',
            onApply: offer.isEligible(score.score)
                ? () => _apply(context, ref, offer)
                : null,
          ),
      ],
    );
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    LoanProduct offer,
  ) async {
    // Default to the farmer's own headroom rather than the product ceiling, so
    // the pre-filled figure is one the backend will accept.
    final suggested = score.borrowCapacity < offer.maxAmount
        ? score.borrowCapacity
        : offer.maxAmount;
    final controller = TextEditingController(
      text: suggested <= 0 ? '' : suggested.toStringAsFixed(0),
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(offer.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${offer.institutionName ?? 'The institution'} lends up to '
              '${formatMwk(offer.maxAmount)} at ${offer.interestRate}% over '
              '${offer.repaymentPeriodMonths} months.',
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'How much do you need? (MWK)',
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
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (amount == null || amount <= 0 || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(loanMarketplaceProvider.notifier).apply(
        loanProductId: offer.id,
        amount: amount,
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
            content: Text(
              'Applied for ${formatMwk(amount)}. '
              '${offer.institutionName ?? 'The institution'} will review it.',
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

class _EmptyOffers extends StatelessWidget {
  /// True when offers exist but the filters hide them all.
  final bool filtered;

  const _EmptyOffers({required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
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
          const SizedBox(height: 12),
          Text(
            filtered ? 'No loans match these filters' : 'No loans published yet',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? 'Clear the filters to see every available offer.'
                : 'Loan offers appear here once a financial institution '
                      'publishes them.',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
