import 'package:agri/src/data/models/enums.dart';
import 'package:agri/src/data/models/farmer_profile.dart';
import 'package:agri/src/data/models/harvest.dart';
import 'package:agri/src/data/models/lending_score.dart';
import 'package:agri/src/data/models/loan.dart';
import 'package:agri/src/data/models/user.dart';
import 'package:agri/src/presentation/view/farmer_home_page.dart';
import 'package:agri/src/presentation/viewmodel/auth_view_model.dart';
import 'package:agri/src/presentation/viewmodel/farmer_dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = FarmerProfile(
  id: '1f88b20e-43ec-4137-8ed0-8c93bd63e605',
  fullName: 'Kondwani Banda',
  nationalIdNumber: 'MW12345678',
  gender: Gender.male,
  district: 'Lilongwe',
  traditionalAuthority: 'T/A Kalolo',
  village: 'Msinja',
  lendingScore: 390,
);

const _user = User(
  id: 'u1',
  phoneNumber: '+265991000001',
  role: UserRole.farmer,
  isVerified: false,
  farmerProfile: _profile,
);

class _StubAuth extends AuthViewModel {
  @override
  Future<AuthState> build() async =>
      const Authenticated(user: _user, token: 'token');
}

class _StubDashboard extends FarmerDashboardViewModel {
  final FarmerDashboard data;

  _StubDashboard(this.data);

  @override
  Future<FarmerDashboard> build() async => data;
}

Future<void> _pump(WidgetTester tester, FarmerDashboard data) async {
  // Phone width so horizontal overflow surfaces, but tall enough that the lazy
  // ListView builds every section instead of only what fits one screen.
  tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(_StubAuth.new),
        farmerDashboardProvider.overrideWith(() => _StubDashboard(data)),
      ],
      child: const MaterialApp(home: FarmerHomePage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the dashboard for a farmer with activity', (
    tester,
  ) async {
    await _pump(
      tester,
      FarmerDashboard(
        score: LendingScore.fromJson({
          'score': 390,
          'previous_score': 320,
          'change': 70,
          'factors': {
            'verified_harvests': 1,
            'produce_listings': 1,
            'repayments_made': 1,
            'loans_fully_repaid': 1,
          },
          'reasons': ['Your score increased by 70 points.'],
        }),
        loans: [
          Loan(
            id: 'l1',
            loanProductId: 'p1',
            amountRequested: 200000,
            amountApproved: 200000,
            interestRate: 18.5,
            totalPayable: 237000,
            amountRepaid: 52000,
            outstandingBalance: 185000,
            status: LoanStatus.active,
            lendingScoreAtApplication: 320,
            dueDate: DateTime(2026, 8, 5),
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
      ),
    );

    // Identity and role.
    expect(find.text('AgriChain'), findsOneWidget);
    expect(find.text('FARMER'), findsOneWidget);
    expect(find.text('Kondwani Banda'), findsOneWidget);

    // Pending registration, because the stub user is unverified.
    expect(
      find.text('Registration Status: Pending Approval'),
      findsOneWidget,
    );

    // Score card: value, ring percentage and the derived headroom.
    expect(find.text('390'), findsOneWidget);
    expect(find.text('16%'), findsOneWidget);
    expect(find.text('MWK 450K'), findsOneWidget);

    // Money owed and the due date from the loan.
    expect(find.text('MWK 185,000'), findsWidgets);
    expect(find.text('Due Aug 5'), findsWidgets);

    // Harvest total with its unit, and the recent work entry.
    expect(find.text('350 Bags'), findsOneWidget);
    expect(find.text('Dry White Hybrid Maize'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);

    expect(find.text('Quick Actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders honest empty states for a brand-new farmer', (
    tester,
  ) async {
    await _pump(
      tester,
      FarmerDashboard(
        score: LendingScore.initial(),
        loans: const [],
        harvests: const [],
      ),
    );

    // No invented figures: the score sits at the floor with no headroom.
    expect(find.text('300'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('No active loan'), findsOneWidget);
    expect(find.text('No farm work recorded yet'), findsOneWidget);
    expect(find.text('Nothing owed'), findsOneWidget);
    // The plot count has no data source, so it must not claim a number.
    expect(find.text('No plots registered'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
