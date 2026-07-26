import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/harvest.dart';
import '../../data/models/lending_score.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/farm_repository.dart';

/// Everything the farmer home screen needs, in one load.
///
/// The derived getters live here rather than in the widgets so the screen stays
/// declarative and the arithmetic is testable.
class FarmerDashboard {
  final LendingScore score;
  final List<Loan> loans;
  final List<Harvest> harvests;

  const FarmerDashboard({
    required this.score,
    required this.loans,
    required this.harvests,
  });

  /// The loan the "current active loan" card refers to: the soonest due.
  Loan? get activeLoan {
    final active = loans.where((loan) => loan.isActive).toList()
      ..sort((a, b) {
        final left = a.dueDate;
        final right = b.dueDate;
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return left.compareTo(right);
      });
    return active.isEmpty ? null : active.first;
  }

  /// Total still owed across every active loan, not just the one on the card.
  double get moneyOwed => loans
      .where((loan) => loan.isActive)
      .fold<double>(0, (sum, loan) => sum + loan.outstandingBalance);

  int get verifiedHarvestCount =>
      harvests.where((harvest) => harvest.isVerified).length;

  /// Total recorded harvest volume. Only meaningful alongside [harvestUnitLabel].
  double get totalHarvestQuantity =>
      harvests.fold<double>(0, (sum, harvest) => sum + harvest.quantity);

  /// The unit to label the total with.
  ///
  /// Summing across mixed units would be nonsense, so this reports the shared
  /// unit when there is one and falls back to a neutral word when there is not.
  String get harvestUnitLabel {
    if (harvests.isEmpty) return 'Bags';
    final units = harvests.map((harvest) => harvest.unitType).toSet();
    if (units.length > 1) return 'Units';
    return switch (units.first) {
      UnitType.bag50kg || UnitType.bag25kg || UnitType.bag10kg => 'Bags',
      UnitType.kilogram => 'Kg',
      UnitType.piece => 'Pieces',
      UnitType.liter => 'Litres',
      UnitType.bunch => 'Bunches',
      UnitType.crate => 'Crates',
    };
  }

  /// True when harvests use different units, so the total is a rough figure.
  bool get hasMixedHarvestUnits =>
      harvests.map((harvest) => harvest.unitType).toSet().length > 1;

  /// Most recent activity first, for the "Recent Garden Work" list.
  List<Harvest> get recentWork {
    final sorted = [...harvests]
      ..sort((a, b) {
        final left = a.harvestDate ?? a.createdAt ?? DateTime(1970);
        final right = b.harvestDate ?? b.createdAt ?? DateTime(1970);
        return right.compareTo(left);
      });
    return sorted.take(4).toList();
  }

  bool get hasAnyActivity => harvests.isNotEmpty || loans.isNotEmpty;
}

class FarmerDashboardViewModel extends AsyncNotifier<FarmerDashboard> {
  FarmRepository get _repository => ref.read(farmRepositoryProvider);

  @override
  Future<FarmerDashboard> build() => _load();

  Future<FarmerDashboard> _load() async {
    // Independent reads: fetch concurrently rather than in sequence.
    final results = await Future.wait([
      _repository.fetchLendingScore(),
      _repository.fetchMyLoans(),
      _repository.fetchHarvests(),
    ]);

    return FarmerDashboard(
      score: results[0] as LendingScore,
      loans: results[1] as List<Loan>,
      harvests: results[2] as List<Harvest>,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}

final farmerDashboardProvider =
    AsyncNotifierProvider<FarmerDashboardViewModel, FarmerDashboard>(
      FarmerDashboardViewModel.new,
    );
