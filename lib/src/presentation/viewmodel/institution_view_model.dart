import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/loan.dart';
import '../../data/repositories/farm_repository.dart';

/// Loan applications awaiting a financial institution's decision (FR-17, FR-18).
class InstitutionApplicationsViewModel extends AsyncNotifier<List<Loan>> {
  @override
  Future<List<Loan>> build() =>
      ref.read(farmRepositoryProvider).fetchApplications();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(farmRepositoryProvider).fetchApplications(),
    );
  }

  /// Records a decision, then reloads so the queue reflects it.
  ///
  /// Approving anchors the agreement to the ledger on the server, so the list is
  /// refetched rather than patched locally — the returned loan carries a
  /// server-computed total payable and due date.
  Future<Loan> decide({
    required String loanId,
    required bool approve,
    double? amountApproved,
    String? note,
  }) async {
    final decided = await ref.read(farmRepositoryProvider).decideLoan(
      loanId: loanId,
      approve: approve,
      amountApproved: amountApproved,
      note: note,
    );
    await refresh();
    return decided;
  }
}

final institutionApplicationsProvider =
    AsyncNotifierProvider<InstitutionApplicationsViewModel, List<Loan>>(
      InstitutionApplicationsViewModel.new,
    );

/// Applications still waiting on a decision, newest first.
final pendingApplicationsProvider = Provider<List<Loan>>((ref) {
  final all = ref.watch(institutionApplicationsProvider).value ?? const [];
  return all.where((loan) => loan.isPending).toList();
});

/// Applications already decided, for the audit trail.
final decidedApplicationsProvider = Provider<List<Loan>>((ref) {
  final all = ref.watch(institutionApplicationsProvider).value ?? const [];
  return all.where((loan) => !loan.isPending).toList();
});
