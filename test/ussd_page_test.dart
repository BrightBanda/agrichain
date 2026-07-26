import 'package:agri/src/data/models/enums.dart';
import 'package:agri/src/data/models/farmer_profile.dart';
import 'package:agri/src/data/models/lending_score.dart';
import 'package:agri/src/data/models/user.dart';
import 'package:agri/src/presentation/view/ussd_page.dart';
import 'package:agri/src/presentation/view/widgets/app_header.dart';
import 'package:agri/src/presentation/viewmodel/auth_view_model.dart';
import 'package:agri/src/presentation/viewmodel/farmer_dashboard_view_model.dart';
import 'package:agri/src/presentation/viewmodel/product_list_view_model.dart';
import 'package:agri/src/data/models/harvest.dart';
import 'package:agri/src/data/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _StubAuth extends AuthViewModel {
  @override
  Future<AuthState> build() async =>
      const Authenticated(user: _user, token: 't');
}

class _StubDashboard extends FarmerDashboardViewModel {
  @override
  Future<FarmerDashboard> build() async => FarmerDashboard(
    score: LendingScore.fromJson({'score': 415, 'previous_score': 390}),
    loans: const [],
    harvests: const <Harvest>[],
  );
}

class _StubProducts extends ProductListViewModel {
  @override
  Future<List<Product>> build() async => const [];
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(_StubAuth.new),
        farmerDashboardProvider.overrideWith(_StubDashboard.new),
        productListViewModelProvider.overrideWith(_StubProducts.new),
      ],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppHeader', () {
    testWidgets('shows the brand, role, USSD and ledger actions', (
      tester,
    ) async {
      await _pump(
        tester,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: AppHeader(subtitle: 'Home'),
          ),
        ),
      );

      expect(find.text('AgriChain'), findsOneWidget);
      expect(find.text('FARMER'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      // The USSD entry point is labelled, not just an icon.
      expect(find.text('USSD'), findsOneWidget);
      // The ledger must stay reachable from every screen.
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the brand sits centred on the screen', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: AppHeader(subtitle: 'Home'),
          ),
        ),
      );

      final screenCentre = tester.view.physicalSize.width /
          tester.view.devicePixelRatio /
          2;
      final brand = tester.getCenter(find.text('AgriChain'));
      final badge = tester.getCenter(find.text('FARMER'));

      // The brand cluster straddles the centre line: name left of it, role right.
      expect(brand.dx, lessThan(screenCentre));
      expect(badge.dx, greaterThan(screenCentre));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the USSD button opens the USSD page', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: AppHeader(subtitle: 'Home'),
          ),
        ),
      );

      await tester.tap(find.text('USSD'));
      await tester.pumpAndSettle();

      expect(find.byType(UssdPage), findsOneWidget);
      expect(find.text('USSD Menu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('UssdPage', () {
    testWidgets('opens on the root menu and is labelled a simulation', (
      tester,
    ) async {
      await _pump(tester, const UssdPage());

      expect(find.text('*384*2020#'), findsOneWidget);
      expect(find.textContaining('Simulation.'), findsOneWidget);
      expect(find.textContaining('1. My Money Score'), findsOneWidget);
      // Send stays disabled until a digit is entered.
      final send = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send'),
      );
      expect(send.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keypad then Send navigates the menu with live data', (
      tester,
    ) async {
      await _pump(tester, const UssdPage());

      await tester.tap(find.widgetWithText(InkWell, '1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send'));
      await tester.pumpAndSettle();

      expect(find.textContaining('MY MONEY SCORE'), findsOneWidget);
      expect(find.textContaining('415 pts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exiting offers a way to dial again', (tester) async {
      await _pump(tester, const UssdPage());

      await tester.tap(find.widgetWithText(InkWell, '0'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Session ended'), findsOneWidget);
      expect(find.text('Dial Again'), findsOneWidget);

      await tester.tap(find.text('Dial Again'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1. My Money Score'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
