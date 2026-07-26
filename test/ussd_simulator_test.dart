import 'package:agri/src/data/models/enums.dart';
import 'package:agri/src/data/models/farmer_profile.dart';
import 'package:agri/src/data/models/harvest.dart';
import 'package:agri/src/data/models/lending_score.dart';
import 'package:agri/src/data/models/loan.dart';
import 'package:agri/src/data/models/product.dart';
import 'package:agri/src/data/models/user.dart';
import 'package:agri/src/presentation/viewmodel/farmer_dashboard_view_model.dart';
import 'package:agri/src/presentation/viewmodel/ussd_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = FarmerProfile(
  id: 'p1',
  fullName: 'Kondwani Banda',
  nationalIdNumber: 'MW1',
  gender: Gender.male,
  district: 'Lilongwe',
  traditionalAuthority: 'T/A Kalolo',
  village: 'Msinja',
  lendingScore: 415,
);

const _user = User(
  id: 'u1',
  phoneNumber: '+265991000001',
  role: UserRole.farmer,
  isVerified: false,
  farmerProfile: _profile,
);

final _dashboard = FarmerDashboard(
  score: LendingScore.fromJson({
    'score': 415,
    'previous_score': 390,
    'change': 25,
    'factors': const {},
    'reasons': const [],
  }),
  loans: [
    Loan(
      id: 'l1',
      loanProductId: 'lp1',
      amountRequested: 200000,
      amountApproved: 200000,
      interestRate: 18.5,
      totalPayable: 237000,
      amountRepaid: 52000,
      outstandingBalance: 185000,
      status: LoanStatus.active,
      lendingScoreAtApplication: 390,
      dueDate: DateTime(2027, 4, 26),
    ),
  ],
  harvests: [
    Harvest(
      id: 'h1',
      userId: 'u1',
      cropName: 'Dry White Hybrid Maize',
      quantity: 350,
      unitType: UnitType.bag50kg,
      season: '2025/2026',
      district: 'Lilongwe',
      status: HarvestStatus.verified,
      harvestDate: DateTime(2026, 5, 14),
    ),
  ],
);

const _products = [
  Product(
    id: 'pr1',
    userId: 'u2',
    productType: ProductType.cropsProduce,
    productName: 'Maize',
    unitType: UnitType.bag50kg,
    district: 'Lilongwe',
    pricePerUnit: 45000,
    quantityAvailable: 100,
  ),
];

UssdSimulator _session({
  User? user = _user,
  FarmerDashboard? dashboard,
  List<Product> products = _products,
}) {
  return UssdSimulator(
    user: user,
    dashboard: dashboard ?? _dashboard,
    products: products,
  );
}

void main() {
  group('root menu', () {
    test('greets the farmer and lists every option', () {
      final display = _session().display;

      expect(display, contains('AgriChain Malawi'));
      expect(display, contains('Moni, Kondwani'));
      expect(display, contains('1. My Money Score'));
      expect(display, contains('2. My Loan Balance'));
      expect(display, contains('3. My Last Harvest'));
      expect(display, contains('4. Market Prices'));
      expect(display, contains('5. Registration Status'));
      expect(display, contains('0. Exit'));
    });

    test('falls back to a generic greeting without a profile', () {
      expect(_session(user: null).display, contains('Moni, Farmer'));
    });

    test('an unoffered option is rejected, not ignored', () {
      final session = _session()..reply('9');

      expect(session.screen, UssdScreen.root);
      expect(session.display, contains('Invalid choice'));
      // The menu is still shown beneath the error.
      expect(session.display, contains('1. My Money Score'));
    });

    test('empty input asks for a number', () {
      final session = _session()..reply('  ');
      expect(session.display, contains('Enter a number'));
    });
  });

  group('menu options return live data', () {
    test('1 shows the score, tier and headroom', () {
      final session = _session()..reply('1');

      expect(session.screen, UssdScreen.score);
      expect(session.display, contains('415 pts'));
      expect(session.display, contains('Silver Farmer'));
      // (415 - 300) * 5000
      expect(session.display, contains('MWK 575,000'));
    });

    test('2 shows the outstanding balance and due date', () {
      final session = _session()..reply('2');

      expect(session.screen, UssdScreen.loan);
      expect(session.display, contains('Owing: MWK 185,000'));
      expect(session.display, contains('Paid: MWK 52,000'));
      expect(session.display, contains('26 Apr 2027'));
    });

    test('2 says so plainly when there is no active loan', () {
      final noLoan = FarmerDashboard(
        score: _dashboard.score,
        loans: const [],
        harvests: _dashboard.harvests,
      );
      final session = _session(dashboard: noLoan)..reply('2');

      expect(session.display, contains('no active loan'));
    });

    test('2 flags an overdue loan rather than showing a plain date', () {
      final overdue = FarmerDashboard(
        score: _dashboard.score,
        loans: [
          Loan(
            id: 'l2',
            loanProductId: 'lp1',
            amountRequested: 100000,
            amountApproved: 100000,
            interestRate: 10,
            totalPayable: 110000,
            amountRepaid: 0,
            outstandingBalance: 110000,
            status: LoanStatus.active,
            lendingScoreAtApplication: 400,
            dueDate: DateTime(2020, 1, 1),
          ),
        ],
        harvests: const [],
      );
      final session = _session(dashboard: overdue)..reply('2');

      expect(session.display, contains('OVERDUE'));
    });

    test('3 shows the most recent harvest', () {
      final session = _session()..reply('3');

      expect(session.screen, UssdScreen.harvest);
      expect(session.display, contains('Dry White Hybrid Maize'));
      expect(session.display, contains('350 50 kg Bag'));
      expect(session.display, contains('Season 2025/2026'));
      expect(session.display, contains('Verified'));
    });

    test('4 lists market prices', () {
      final session = _session()..reply('4');

      expect(session.screen, UssdScreen.prices);
      expect(session.display, contains('Maize'));
      expect(session.display, contains('MWK 45,000'));
    });

    test('4 degrades gracefully with no listings', () {
      final session = _session(products: const [])..reply('4');
      expect(session.display, contains('Service unavailable'));
    });

    test('5 reflects the real verification state', () {
      final pending = _session()..reply('5');
      expect(pending.display, contains('PENDING APPROVAL'));

      const verified = User(
        id: 'u1',
        phoneNumber: '+265991000001',
        role: UserRole.farmer,
        isVerified: true,
        farmerProfile: _profile,
      );
      final approved = _session(user: verified)..reply('5');
      expect(approved.display, contains('APPROVED'));
    });
  });

  group('navigation', () {
    test('0 returns to the root menu from a leaf', () {
      final session = _session()..reply('1');
      expect(session.screen, UssdScreen.score);

      session.reply('0');
      expect(session.screen, UssdScreen.root);
      expect(session.display, contains('1. My Money Score'));
    });

    test('00 ends the session from a leaf', () {
      final session = _session()
        ..reply('1')
        ..reply('00');

      expect(session.isEnded, isTrue);
      expect(session.display, contains('Session ended'));
    });

    test('0 at the root ends the session', () {
      final session = _session()..reply('0');
      expect(session.isEnded, isTrue);
    });

    test('an ended session ignores further input', () {
      final session = _session()..reply('0');
      session.reply('1');

      expect(session.screen, UssdScreen.ended);
      expect(session.acceptsInput, isFalse);
    });

    test('restart returns to a clean root menu', () {
      final session = _session()
        ..reply('9') // leaves an error
        ..reply('0'); // ends
      expect(session.isEnded, isTrue);

      session.restart();
      expect(session.screen, UssdScreen.root);
      expect(session.display, isNot(contains('Invalid choice')));
    });

    test('an invalid reply on a leaf keeps you on that leaf', () {
      final session = _session()
        ..reply('1')
        ..reply('7');

      expect(session.screen, UssdScreen.score);
      expect(session.display, contains('Invalid choice'));
    });
  });

  group('data refresh', () {
    test('updateData swaps the figures without losing the screen', () {
      final session = _session(dashboard: _dashboard)..reply('1');
      expect(session.display, contains('415 pts'));

      session.updateData(
        user: _user,
        dashboard: FarmerDashboard(
          score: LendingScore.fromJson({'score': 700, 'previous_score': 415}),
          loans: const [],
          harvests: const [],
        ),
        products: _products,
      );

      // Same screen, new numbers.
      expect(session.screen, UssdScreen.score);
      expect(session.display, contains('700 pts'));
      expect(session.display, contains('Platinum Farmer'));
    });

    test('a session opened before data arrives shows it once loaded', () {
      // This is the real sequence: the page opens while the dashboard is null.
      final session = UssdSimulator(user: _user);
      session.reply('1');
      expect(session.display, contains('Service unavailable'));

      session.updateData(user: _user, dashboard: _dashboard);
      expect(session.display, contains('415 pts'));
    });
  });

  test('every response stays within a feature-phone width', () {
    // A USSD page cannot scroll, so long lines would simply be cut off.
    for (final option in ['1', '2', '3', '4', '5']) {
      final session = _session()..reply(option);
      for (final line in session.display.split('\n')) {
        expect(
          line.length,
          lessThanOrEqualTo(UssdSimulator.lineWidth),
          reason: 'Option $option produced an over-long line: "$line"',
        );
      }
    }
  });
}
