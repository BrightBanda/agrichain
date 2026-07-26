import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/loan_product.dart';
import '../../data/repositories/farm_repository.dart';
import 'farmer_dashboard_view_model.dart';

/// The published loan offers farmers browse and compare (FR-15).
class LoanMarketplaceViewModel extends AsyncNotifier<List<LoanProduct>> {
  @override
  Future<List<LoanProduct>> build() =>
      ref.read(farmRepositoryProvider).fetchLoanProducts();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(farmRepositoryProvider).fetchLoanProducts(),
    );
  }

  /// Submits an application, then refreshes the dashboard so the new loan and
  /// any score change appear immediately.
  Future<void> apply({
    required String loanProductId,
    required double amount,
  }) async {
    await ref.read(farmRepositoryProvider).applyForLoan(
      loanProductId: loanProductId,
      amount: amount,
    );
    await ref.read(farmerDashboardProvider.notifier).refresh();
  }
}

final loanMarketplaceProvider =
    AsyncNotifierProvider<LoanMarketplaceViewModel, List<LoanProduct>>(
      LoanMarketplaceViewModel.new,
    );

/// Filters the marketplace by loan type. Null shows everything.
///
/// A Notifier rather than the legacy StateProvider, which Riverpod 3 moved out
/// of the main entry point.
class LoanTypeFilter extends Notifier<LoanType?> {
  @override
  LoanType? build() => null;

  void select(LoanType? type) => state = type;
}

final loanTypeFilterProvider = NotifierProvider<LoanTypeFilter, LoanType?>(
  LoanTypeFilter.new,
);

/// Filters by institution name. Null shows everything.
class LoanInstitutionFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? institution) => state = institution;
}

final loanInstitutionFilterProvider =
    NotifierProvider<LoanInstitutionFilter, String?>(LoanInstitutionFilter.new);

/// The offers left after both filters are applied.
final filteredLoanProductsProvider = Provider<List<LoanProduct>>((ref) {
  final products = ref.watch(loanMarketplaceProvider).value ?? const [];
  final type = ref.watch(loanTypeFilterProvider);
  final institution = ref.watch(loanInstitutionFilterProvider);

  return products.where((product) {
    if (type != null && product.loanType != type) return false;
    if (institution != null && product.institutionName != institution) {
      return false;
    }
    return true;
  }).toList();
});

/// Institution names present in the marketplace, for the filter dropdown.
final loanInstitutionsProvider = Provider<List<String>>((ref) {
  final products = ref.watch(loanMarketplaceProvider).value ?? const [];
  final names = products
      .map((product) => product.institutionName)
      .whereType<String>()
      .toSet()
      .toList();
  names.sort();
  return names;
});
