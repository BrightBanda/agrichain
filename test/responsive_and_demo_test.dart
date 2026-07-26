import 'package:agri/src/data/models/demo_accounts.dart';
import 'package:agri/src/data/models/enums.dart';
import 'package:agri/src/data/models/lending_score.dart';
import 'package:agri/src/presentation/view/landing_page.dart';
import 'package:agri/src/presentation/view/widgets/demo_account_sheet.dart';
import 'package:agri/src/presentation/viewmodel/auth_view_model.dart';
import 'package:agri/src/utils/farm_bottom_nav.dart';
import 'package:agri/src/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedOutAuth extends AuthViewModel {
  @override
  Future<AuthState> build() async => const Unauthenticated();
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 1400),
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authViewModelProvider.overrideWith(_SignedOutAuth.new)],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PageWidth', () {
    testWidgets('leaves a phone viewport alone', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: PageWidth(child: SizedBox(height: 10, child: Placeholder())),
        ),
        size: const Size(390, 800),
      );

      final width = tester.getSize(find.byType(Placeholder)).width;
      expect(width, 390);
      expect(tester.takeException(), isNull);
    });

    testWidgets('caps content on a desktop-width window', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: PageWidth(child: SizedBox(height: 10, child: Placeholder())),
        ),
        size: const Size(1600, 900),
      );

      // Capped rather than stretched across the whole window.
      final width = tester.getSize(find.byType(Placeholder)).width;
      expect(width, 720);
      expect(tester.takeException(), isNull);
    });
  });

  group('grid columns', () {
    test('never drops below two or exceeds four', () {
      expect(gridColumnsFor(200), 2);
      expect(gridColumnsFor(390), 2);
      expect(gridColumnsFor(720), 4);
      expect(gridColumnsFor(4000), 4);
    });

    test('adds a column as width allows', () {
      // 180pt target tiles.
      expect(gridColumnsFor(560), 3);
    });
  });

  group('breakpoints', () {
    testWidgets('a phone is neither medium nor wide', (tester) async {
      late BuildContext captured;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
        size: const Size(390, 800),
      );
      expect(Breakpoints.isWide(captured), isFalse);
      expect(Breakpoints.isMedium(captured), isFalse);
    });

    testWidgets('a desktop window is wide', (tester) async {
      late BuildContext captured;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
        size: const Size(1400, 900),
      );
      expect(Breakpoints.isWide(captured), isTrue);
      expect(Breakpoints.isMedium(captured), isTrue);
    });
  });

  group('demo accounts', () {
    test('covers every role the picker advertises', () {
      expect(DemoAccounts.all, hasLength(4));
      expect(
        DemoAccounts.all.map((a) => a.role).toSet(),
        {
          UserRole.farmer,
          UserRole.supplier,
          UserRole.financialInstitution,
        },
      );
      // Two farmers: one established, one with nothing recorded.
      expect(
        DemoAccounts.all.where((a) => a.role == UserRole.farmer).length,
        2,
      );
    });

    test('every account has distinct credentials', () {
      final phones = DemoAccounts.all.map((a) => a.phoneNumber).toSet();
      expect(phones, hasLength(DemoAccounts.all.length));
      for (final account in DemoAccounts.all) {
        expect(account.password, isNotEmpty);
        expect(account.phoneNumber, startsWith('+265'));
      }
    });

    test('the no-score farmer sits at the engine floor, not below it', () {
      // A score under 300 is not representable: the engine clamps to its floor.
      final atFloor = LendingScore.fromJson({'score': 250});
      expect(atFloor.progress, 0.0);
      expect(LendingScore.minScore, 300);
      expect(LendingScore.initial().score, 300);
      // Which is what makes the account useful: no borrowing headroom at all.
      expect(LendingScore.initial().borrowCapacity, 0);
    });
  });

  group('LandingPage demo entry points', () {
    testWidgets('offers the test-account picker', (tester) async {
      await _pump(tester, const LandingPage());
      expect(find.text('Use a test account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the picker lists every account', (tester) async {
      await _pump(tester, const LandingPage());

      await tester.tap(find.text('Use a test account'));
      await tester.pumpAndSettle();

      expect(find.byType(DemoAccountSheet), findsOneWidget);
      expect(find.text('Test accounts'), findsOneWidget);
      for (final account in DemoAccounts.all) {
        expect(find.text(account.label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('FarmNavTab', () {
    test('My Farm is the first destination', () {
      // The shell's IndexedStack order must match this enum.
      expect(FarmNavTab.values.first, FarmNavTab.myFarm);
      expect(FarmNavTab.values[2], FarmNavTab.home);
      expect(FarmNavTab.values, hasLength(5));
    });
  });
}
