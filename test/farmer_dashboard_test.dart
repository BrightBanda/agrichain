import 'package:agri/src/core/utils/formatters.dart';
import 'package:agri/src/data/models/enums.dart';
import 'package:agri/src/data/models/harvest.dart';
import 'package:agri/src/data/models/lending_score.dart';
import 'package:agri/src/data/models/loan.dart';
import 'package:agri/src/presentation/viewmodel/farmer_dashboard_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

Loan _loan({
  required String id,
  required LoanStatus status,
  double outstanding = 0,
  double totalPayable = 100000,
  double repaid = 0,
  DateTime? dueDate,
}) {
  return Loan(
    id: id,
    loanProductId: 'p1',
    amountRequested: 100000,
    amountApproved: 100000,
    interestRate: 18.5,
    totalPayable: totalPayable,
    amountRepaid: repaid,
    outstandingBalance: outstanding,
    status: status,
    lendingScoreAtApplication: 320,
    dueDate: dueDate,
  );
}

Harvest _harvest({
  required String id,
  required double quantity,
  UnitType unit = UnitType.bag50kg,
  HarvestStatus status = HarvestStatus.verified,
  DateTime? date,
}) {
  return Harvest(
    id: id,
    userId: 'u1',
    cropName: 'Maize',
    quantity: quantity,
    unitType: unit,
    season: '2025/2026',
    district: 'Lilongwe',
    status: status,
    harvestDate: date,
  );
}

FarmerDashboard _dashboard({
  List<Loan> loans = const [],
  List<Harvest> harvests = const [],
  LendingScore? score,
}) {
  return FarmerDashboard(
    score: score ?? LendingScore.initial(),
    loans: loans,
    harvests: harvests,
  );
}

void main() {
  group('money owed', () {
    test('sums only active loans, ignoring repaid and rejected ones', () {
      final dashboard = _dashboard(
        loans: [
          _loan(id: 'a', status: LoanStatus.active, outstanding: 120000),
          _loan(id: 'b', status: LoanStatus.active, outstanding: 65000),
          _loan(id: 'c', status: LoanStatus.repaid, outstanding: 999999),
          _loan(id: 'd', status: LoanStatus.rejected, outstanding: 999999),
        ],
      );

      expect(dashboard.moneyOwed, 185000);
    });

    test('is zero when nothing is active', () {
      final dashboard = _dashboard(
        loans: [_loan(id: 'a', status: LoanStatus.repaid, outstanding: 0)],
      );
      expect(dashboard.moneyOwed, 0);
      expect(dashboard.activeLoan, isNull);
    });
  });

  group('active loan selection', () {
    test('picks the loan falling due soonest', () {
      final dashboard = _dashboard(
        loans: [
          _loan(
            id: 'later',
            status: LoanStatus.active,
            dueDate: DateTime(2027, 4, 26),
          ),
          _loan(
            id: 'sooner',
            status: LoanStatus.active,
            dueDate: DateTime(2026, 8, 5),
          ),
        ],
      );

      expect(dashboard.activeLoan?.id, 'sooner');
    });

    test('sorts loans without a due date last', () {
      final dashboard = _dashboard(
        loans: [
          _loan(id: 'undated', status: LoanStatus.active),
          _loan(
            id: 'dated',
            status: LoanStatus.active,
            dueDate: DateTime(2027, 1, 1),
          ),
        ],
      );

      expect(dashboard.activeLoan?.id, 'dated');
    });
  });

  group('harvest totals', () {
    test('labels the total with the shared unit', () {
      final dashboard = _dashboard(
        harvests: [
          _harvest(id: 'a', quantity: 120),
          _harvest(id: 'b', quantity: 230),
        ],
      );

      expect(dashboard.totalHarvestQuantity, 350);
      expect(dashboard.harvestUnitLabel, 'Bags');
      expect(dashboard.hasMixedHarvestUnits, isFalse);
    });

    test('refuses to imply a unit when harvests mix them', () {
      final dashboard = _dashboard(
        harvests: [
          _harvest(id: 'a', quantity: 120, unit: UnitType.bag50kg),
          _harvest(id: 'b', quantity: 40, unit: UnitType.crate),
        ],
      );

      expect(dashboard.hasMixedHarvestUnits, isTrue);
      expect(dashboard.harvestUnitLabel, 'Units');
    });

    test('counts only verified harvests', () {
      final dashboard = _dashboard(
        harvests: [
          _harvest(id: 'a', quantity: 10),
          _harvest(id: 'b', quantity: 10, status: HarvestStatus.pending),
          _harvest(id: 'c', quantity: 10, status: HarvestStatus.rejected),
        ],
      );

      expect(dashboard.verifiedHarvestCount, 1);
    });
  });

  test('recent work is newest first and capped at four entries', () {
    final dashboard = _dashboard(
      harvests: [
        _harvest(id: 'oldest', quantity: 1, date: DateTime(2026, 1, 1)),
        _harvest(id: 'newest', quantity: 1, date: DateTime(2026, 6, 1)),
        _harvest(id: 'mid', quantity: 1, date: DateTime(2026, 3, 1)),
        _harvest(id: 'x4', quantity: 1, date: DateTime(2026, 2, 1)),
        _harvest(id: 'x5', quantity: 1, date: DateTime(2025, 12, 1)),
      ],
    );

    final recent = dashboard.recentWork;
    expect(recent, hasLength(4));
    expect(recent.first.id, 'newest');
    expect(recent.map((h) => h.id), isNot(contains('x5')));
  });

  group('LendingScore', () {
    test('maps the engine range onto the ring', () {
      expect(LendingScore.initial().progress, 0);
      expect(LendingScore.initial().percent, 0);

      final mid = LendingScore.fromJson({'score': 575, 'previous_score': 575});
      expect(mid.percent, 50);

      final top = LendingScore.fromJson({'score': 850, 'previous_score': 800});
      expect(top.progress, 1.0);
    });

    test('clamps a score outside the engine range', () {
      final over = LendingScore.fromJson({'score': 9999});
      expect(over.progress, 1.0);
      final under = LendingScore.fromJson({'score': 0});
      expect(under.progress, 0.0);
    });

    test('derives the tier from the score', () {
      expect(FarmerTier.forScore(300), FarmerTier.bronze);
      expect(FarmerTier.forScore(399), FarmerTier.bronze);
      expect(FarmerTier.forScore(400), FarmerTier.silver);
      expect(FarmerTier.forScore(550), FarmerTier.gold);
      expect(FarmerTier.forScore(700), FarmerTier.platinum);
    });

    test('borrowing headroom grows with points above the floor', () {
      expect(LendingScore.initial().borrowCapacity, 0);
      final score = LendingScore.fromJson({'score': 390});
      expect(score.borrowCapacity, (390 - 300) * 5000);
    });

    test('lists only the factors actually earning points', () {
      final score = LendingScore.fromJson({
        'score': 390,
        'factors': {
          'verified_harvests': 1,
          'produce_listings': 1,
          'repayments_made': 1,
          'loans_fully_repaid': 1,
        },
      });

      expect(score.strengths, ['Verified Harvests', 'Crop Sales', 'Fast Payback']);
    });

    test('claims no strengths for a farmer with no activity', () {
      final score = LendingScore.fromJson({'score': 300, 'factors': {}});
      expect(score.strengths, isEmpty);
    });
  });

  group('formatters', () {
    test('groups thousands', () {
      expect(groupDigits(185000), '185,000');
      expect(groupDigits(1), '1');
      expect(groupDigits(1000), '1,000');
      expect(groupDigits(2500000), '2,500,000');
    });

    test('formats currency with and without decimals', () {
      expect(formatMwk(185000), 'MWK 185,000');
      expect(formatMwk(185000.5, decimals: true), 'MWK 185,000.50');
    });

    test('compacts large amounts for tight spaces', () {
      expect(formatMwkCompact(2500000), 'MWK 2.5M');
      expect(formatMwkCompact(450000), 'MWK 450K');
      expect(formatMwkCompact(1000000), 'MWK 1M');
      expect(formatMwkCompact(500), 'MWK 500');
    });

    test('drops trailing zero decimals from quantities', () {
      expect(formatQuantity(120.0), '120');
      expect(formatQuantity(120.5), '120.50');
      expect(formatQuantity(1200.0), '1,200');
    });

    test('formats dates', () {
      expect(formatShortDate(DateTime(2026, 8, 5)), 'Aug 5');
      expect(formatFullDate(DateTime(2027, 4, 26)), '26 Apr 2027');
    });
  });

  group('Loan', () {
    test('reports repayment progress', () {
      final loan = _loan(
        id: 'a',
        status: LoanStatus.active,
        totalPayable: 237000,
        repaid: 118500,
        outstanding: 118500,
      );
      expect(loan.repaymentProgress, closeTo(0.5, 0.001));
    });

    test('flags an active loan past its due date as overdue', () {
      final overdue = _loan(
        id: 'a',
        status: LoanStatus.active,
        dueDate: DateTime(2020, 1, 1),
      );
      expect(overdue.isOverdue, isTrue);

      // A repaid loan is never overdue, however old its due date.
      final repaid = _loan(
        id: 'b',
        status: LoanStatus.repaid,
        dueDate: DateTime(2020, 1, 1),
      );
      expect(repaid.isOverdue, isFalse);
    });
  });
}
