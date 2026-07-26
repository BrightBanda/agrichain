import 'package:agri/src/data/models/enums.dart';
import 'package:agri/src/data/models/farmer_profile.dart';
import 'package:agri/src/data/models/harvest.dart';
import 'package:agri/src/data/models/lending_score.dart';
import 'package:agri/src/data/models/loan.dart';
import 'package:agri/src/data/models/loan_product.dart';
import 'package:agri/src/data/models/product.dart';
import 'package:agri/src/data/models/score_history.dart';
import 'package:agri/src/data/models/supplier_profile.dart';
import 'package:agri/src/data/models/user.dart';
import 'package:agri/src/presentation/view/service_provider_home_page.dart';
import 'package:agri/src/presentation/view/analytics_page.dart';
import 'package:agri/src/presentation/view/loans_page.dart';
import 'package:agri/src/presentation/view/marketplace_page.dart';
import 'package:agri/src/presentation/viewmodel/analytics_view_model.dart';
import 'package:agri/src/presentation/viewmodel/auth_view_model.dart';
import 'package:agri/src/presentation/viewmodel/farmer_dashboard_view_model.dart';
import 'package:agri/src/presentation/viewmodel/loan_marketplace_view_model.dart';
import 'package:agri/src/presentation/viewmodel/product_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = FarmerProfile(
  id: 'p1',
  fullName: 'george mbale',
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
  isVerified: true,
  farmerProfile: _profile,
);

const _supplierUser = User(
  id: 'u4',
  phoneNumber: '+265700000501',
  organizationName: 'Farmers World Malawi',
  role: UserRole.supplier,
  isVerified: true,
  supplierProfile: SupplierProfile(
    id: 'sp1',
    businessName: 'Farmers World Malawi',
    district: 'Lilongwe',
    services: [ProductType.seeds, ProductType.fertilizer],
  ),
);

final _score = LendingScore.fromJson({
  'score': 415,
  'previous_score': 390,
  'change': 25,
  'factors': {
    'verified_harvests': 1,
    'produce_listings': 1,
    'repayments_made': 2,
    'loans_fully_repaid': 1,
  },
  'reasons': ['Your score increased by 25 points.'],
});

final _harvest = Harvest(
  id: 'h1',
  userId: 'u1',
  cropName: 'Dry White Hybrid Maize',
  quantity: 350,
  unitType: UnitType.bag50kg,
  season: '2025/2026',
  district: 'Lilongwe',
  status: HarvestStatus.verified,
  harvestDate: DateTime(2026, 5, 14),
);

final _activeLoan = Loan(
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
  repaymentPeriodMonths: 9,
  dueDate: DateTime(2027, 4, 26),
);

/// Deliberately given a threshold the stub farmer clears, and a second offer
/// they do not, so both card states render.
const _offers = [
  LoanProduct(
    id: 'lp1',
    institutionUserId: 'i1',
    name: 'Seed & Fertilizer Loan',
    loanType: LoanType.inputFinancing,
    maxAmount: 500000,
    interestRate: 18.5,
    repaymentPeriodMonths: 9,
    minLendingScore: 310,
    description: 'Get money or input vouchers to buy certified seeds.',
    isActive: true,
    institutionName: 'Malawi Rural Microfinance Ltd',
    monthlyFeePercent: 2.06,
  ),
  LoanProduct(
    id: 'lp2',
    institutionUserId: 'i1',
    name: 'Farm Equipment Loan',
    loanType: LoanType.equipmentFinancing,
    maxAmount: 900000,
    interestRate: 24,
    repaymentPeriodMonths: 12,
    minLendingScore: 600,
    description: 'Buy solar water pumps or walking tractors.',
    isActive: true,
    institutionName: 'Malawi Rural Microfinance Ltd',
  ),
];

const _products = [
  Product(
    id: 'pr1',
    userId: 'u2',
    productType: ProductType.livestockAnimals,
    productName: 'nkhumba',
    unitType: UnitType.piece,
    district: 'Lilongwe',
    pricePerUnit: 45000,
    quantityAvailable: 25,
    sellerName: 'george mbale',
    sellerVerified: true,
  ),
  Product(
    id: 'pr2',
    userId: 'u3',
    productType: ProductType.cropsProduce,
    productName: 'Certified Hybrid Maize Seeds 25kg',
    unitType: UnitType.bag25kg,
    district: 'Mzuzu',
    pricePerUnit: 45000,
    quantityAvailable: 50,
    sellerName: 'SeedCo Malawi',
    sellerVerified: false,
  ),
];

class _StubAuth extends AuthViewModel {
  final User user;

  _StubAuth([this.user = _user]);

  @override
  Future<AuthState> build() async => Authenticated(user: user, token: 't');
}

class _StubDashboard extends FarmerDashboardViewModel {
  @override
  Future<FarmerDashboard> build() async => FarmerDashboard(
    score: _score,
    loans: [_activeLoan],
    harvests: [_harvest],
  );
}

class _StubOffers extends LoanMarketplaceViewModel {
  @override
  Future<List<LoanProduct>> build() async => _offers;
}

/// A supply listing from a service provider, exercising the FR-11 categories.
const _withSeedListing = [
  ..._products,
  Product(
    id: 'pr3',
    userId: 'u4',
    productType: ProductType.fertilizer,
    productName: 'Urea Fertilizer 50kg Bag',
    unitType: UnitType.bag50kg,
    district: 'Lilongwe',
    pricePerUnit: 65000,
    quantityAvailable: 200,
    sellerName: 'Farmers World Malawi',
    sellerVerified: true,
  ),
];

class _StubProducts extends ProductListViewModel {
  final List<Product> products;

  _StubProducts([this.products = _products]);

  @override
  Future<List<Product>> build() async => products;
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  List<Product> products = _products,
  User user = _user,
}) async {
  // Phone width so horizontal overflow surfaces; tall so the lazy lists build
  // every section rather than only what fits one screen.
  tester.view.physicalSize = const Size(390 * 3, 3000 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => _StubAuth(user)),
        farmerDashboardProvider.overrideWith(_StubDashboard.new),
        loanMarketplaceProvider.overrideWith(_StubOffers.new),
        productListViewModelProvider.overrideWith(
          () => _StubProducts(products),
        ),
        scoreHistoryProvider.overrideWith(
          (ref) async => [
            ScoreHistoryEntry.fromJson({
              'id': 's1',
              'previous_score': 390,
              'score': 415,
              'factors': const {},
              'reasons': const [
                'Your score increased by 25 points.',
                'You have made 2 repayment(s) on time (+50 points).',
              ],
              'calculated_at': '2026-07-26T10:38:16.000000',
            }),
          ],
        ),
      ],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('LoansPage — Agri Loan Marketplace', () {
    testWidgets('renders offers with eligibility from the live score', (
      tester,
    ) async {
      await _pump(tester, const LoansPage());

      expect(find.text('Agri Loan Marketplace'), findsOneWidget);
      expect(find.text('Approved Farmer Credit'), findsOneWidget);
      expect(find.text('Available Loans'), findsOneWidget);

      // Institution name comes from the API join, not a hardcoded string.
      expect(find.text('Malawi Rural Microfinance Ltd'), findsNWidgets(2));

      // A 415 score clears 310 but not 600.
      expect(find.text('Eligible'), findsOneWidget);
      expect(find.text('69% Match'), findsOneWidget);
      expect(find.text('Apply For Seed & Fertilizer Loan'), findsOneWidget);
      expect(find.text('Not Yet Eligible'), findsOneWidget);
      expect(
        find.textContaining('You need 185 more points'),
        findsOneWidget,
      );

      // Monthly fee is derived, not invented.
      expect(find.text('2.1% / month'), findsOneWidget);
      expect(find.text('MWK 500,000'), findsWidgets);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the balance link reflects an outstanding loan', (tester) async {
      await _pump(tester, const LoansPage());
      expect(find.text('My Current Balance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MarketplacePage', () {
    testWidgets('renders the grid with seller details from the API', (
      tester,
    ) async {
      await _pump(tester, const MarketplacePage());

      expect(find.text('Marketplace'), findsWidgets);
      expect(find.text('Sell Product'), findsOneWidget);
      expect(find.text('nkhumba'), findsOneWidget);
      expect(find.text('Certified Hybrid Maize Seeds 25kg'), findsOneWidget);

      // Seller name is joined server-side; verification is the real trust
      // signal standing in for the mockup's star rating.
      expect(find.text('SeedCo Malawi'), findsOneWidget);
      expect(find.text('Verified Seller'), findsOneWidget);

      expect(find.text('Available: 25 Piece'), findsOneWidget);
      expect(find.text('MWK 45,000'), findsNWidgets(2));

      // Categories with no backend source are present but disabled.
      expect(find.text('Seeds'), findsOneWidget);
      expect(find.text('Fertiliser'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('search narrows the grid', (tester) async {
      await _pump(tester, const MarketplacePage());

      await tester.enterText(find.byType(TextField).first, 'nkhumba');
      await tester.pumpAndSettle();

      // Two matches: the search box's own text and the surviving card.
      expect(find.text('nkhumba'), findsNWidgets(2));
      expect(find.text('Certified Hybrid Maize Seeds 25kg'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('choosing a category filters the grid', (tester) async {
      await _pump(tester, const MarketplacePage());

      // The chip row scrolls; bring the chip into view or the tap silently
      // misses and the test would pass without filtering anything.
      final seeds = find.text('Seeds');
      await tester.ensureVisible(seeds);
      await tester.pumpAndSettle();
      await tester.tap(seeds);
      await tester.pumpAndSettle();

      // The stub has no SEEDS listing, so the grid empties.
      expect(find.text('nkhumba'), findsNothing);
      expect(find.text('Nothing matches your search'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a supply listing shows its service-provider seller', (
      tester,
    ) async {
      await _pump(tester, const MarketplacePage(), products: _withSeedListing);

      expect(find.text('Urea Fertilizer 50kg Bag'), findsOneWidget);
      expect(find.text('Farmers World Malawi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MyAnalyticsPage', () {
    testWidgets('Overview leads with real records and flags sample figures', (
      tester,
    ) async {
      await _pump(tester, const MyAnalyticsPage());

      expect(find.text('Your Records'), findsOneWidget);
      expect(find.text('415'), findsOneWidget);
      // The notice is a RichText, so the finder has to look inside spans.
      expect(
        find.textContaining('Sample figures.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Income vs Spending'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Lending Score tab shows live history', (tester) async {
      await _pump(tester, const MyAnalyticsPage());

      await tester.tap(find.text('Lending Score'));
      await tester.pumpAndSettle();

      expect(find.text('415 / 850'), findsOneWidget);
      expect(find.text('Lending Score History'), findsOneWidget);
      expect(find.text('390 → 415'), findsOneWidget);
      expect(find.text('+25'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Farm & Harvest tab shows real harvests', (tester) async {
      await _pump(tester, const MyAnalyticsPage());

      // The tab strip scrolls horizontally; bring the last tab into view first.
      final tab = find.text('Farm & Harvest');
      await tester.ensureVisible(tab);
      await tester.pumpAndSettle();
      await tester.tap(tab);
      await tester.pumpAndSettle();

      expect(find.text('Harvest Records'), findsOneWidget);
      expect(find.text('Dry White Hybrid Maize'), findsOneWidget);
      expect(find.text('350 Bags'), findsOneWidget);
      expect(find.text('Verified'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('service provider role', () {
    testWidgets('home shows the business, services and own listings only', (
      tester,
    ) async {
      await _pump(
        tester,
        const ServiceProviderHomePage(),
        user: _supplierUser,
        products: _withSeedListing,
      );

      expect(find.text('Farmers World Malawi'), findsWidgets);
      // The role badge uppercases its label.
      expect(find.text('SERVICE PROVIDER'), findsOneWidget);
      expect(find.text('My Listings'), findsWidgets);

      // Its own fertilizer listing appears; the farmers' produce does not.
      expect(find.text('Urea Fertilizer 50kg Bag'), findsOneWidget);
      expect(find.text('nkhumba'), findsNothing);

      // Declared services are shown as chips.
      expect(find.text('Fertilizer'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('farmer-only features are absent, not disabled', (tester) async {
      await _pump(
        tester,
        const ServiceProviderHomePage(),
        user: _supplierUser,
        products: _withSeedListing,
      );

      expect(find.text('Farmer Money Score'), findsNothing);
      expect(find.text('Quick Actions'), findsNothing);
      expect(find.text('Recent Garden Work'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('listable categories by role', () {
    test('a farmer may list only produce and livestock', () {
      expect(_user.listableProductTypes, ProductType.farmProduce);
      expect(_user.canListProducts, isTrue);
      expect(_user.isServiceProvider, isFalse);
    });

    test('a service provider may list only its declared services', () {
      expect(_supplierUser.listableProductTypes, [
        ProductType.seeds,
        ProductType.fertilizer,
      ]);
      expect(_supplierUser.isServiceProvider, isTrue);
      expect(
        _supplierUser.supplierProfile!.mayList(ProductType.pesticides),
        isFalse,
      );
    });

    test('a provider with no declared services cannot list anything', () {
      const bare = User(
        id: 'u9',
        phoneNumber: '+265700000000',
        role: UserRole.supplier,
        isVerified: false,
        supplierProfile: SupplierProfile(
          id: 'sp9',
          businessName: 'Empty Ltd',
          services: [],
        ),
      );
      expect(bare.canListProducts, isFalse);
    });

    test('roles with no marketplace rights cannot list', () {
      const institution = User(
        id: 'u8',
        phoneNumber: '+265700000001',
        role: UserRole.financialInstitution,
        isVerified: true,
      );
      expect(institution.canListProducts, isFalse);
      expect(institution.listableProductTypes, isEmpty);
    });

    test('supplier profile drops categories a provider may not sell', () {
      // A stale or hostile payload must not widen what can be listed.
      final profile = SupplierProfile.fromJson({
        'id': 'sp1',
        'business_name': 'Mixed Ltd',
        'services': ['SEEDS', 'CROPS_PRODUCE', 'NOT_A_CATEGORY'],
      });
      expect(profile.services, [ProductType.seeds]);
    });
  });
}
