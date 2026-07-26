import 'package:agri/src/data/models/enums.dart';
import 'package:agri/src/data/models/loan.dart';
import 'package:agri/src/data/models/onboarding_defaults.dart';
import 'package:agri/src/data/models/requests.dart';
import 'package:agri/src/presentation/view/AccountSelectionPage.dart';
import 'package:agri/src/presentation/view/landing_page.dart';
import 'package:agri/src/presentation/view/login_page.dart';
import 'package:agri/src/presentation/viewmodel/auth_view_model.dart';
import 'package:agri/src/utils/verification_progress_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resolves immediately so screens that watch auth do not sit on a spinner.
///
/// Without this, the real view model reads secure storage, whose platform
/// channel has no handler under `flutter test`, so the future never completes
/// and pumpAndSettle times out.
class _SignedOutAuth extends AuthViewModel {
  @override
  Future<AuthState> build() async => const Unauthenticated();
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
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
  group('LandingPage', () {
    testWidgets('offers all three ways in', (tester) async {
      await _pump(tester, const LandingPage());

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('National Bank Admin Access'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Create Account leads to the role choice', (tester) async {
      await _pump(tester, const LandingPage());

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountSelectionPage), findsOneWidget);
      expect(find.text('Who are you?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the admin link opens a labelled sign-in', (tester) async {
      await _pump(tester, const LandingPage());

      await tester.tap(find.text('National Bank Admin Access'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      // Relabelled, but the same credentials flow: the account's role decides
      // what appears after sign-in.
      expect(
        find.widgetWithText(AppBar, 'National Bank Admin Access'),
        findsOneWidget,
      );
      expect(
        find.textContaining('verify farmer loan applications'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sign In opens the ordinary sign-in', (tester) async {
      await _pump(tester, const LandingPage());

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Sign In'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('simplified farmer registration payload', () {
    test('sends the four collected fields plus the placeholders', () {
      const request = FarmerRegisterRequest(
        fullName: 'Kondwani Banda',
        nationalIdNumber: 'MW12345678',
        phoneNumber: '+265999123456',
        password: 'Password123!',
        confirmPassword: 'Password123!',
        gender: OnboardingDefaults.gender,
        district: OnboardingDefaults.district,
        traditionalAuthority: OnboardingDefaults.traditionalAuthority,
        village: OnboardingDefaults.village,
      );

      final json = request.toJson();

      // What the form actually asked for.
      expect(json['full_name'], 'Kondwani Banda');
      expect(json['national_id_number'], 'MW12345678');
      expect(json['phone_number'], '+265999123456');
      expect(json['password'], 'Password123!');
      expect(json['confirm_password'], 'Password123!');

      // The backend requires these, so the form fills them in.
      expect(json['gender'], 'OTHER');
      expect(json['district'], 'Lilongwe');
      expect(json['traditional_authority'], 'T/A Kalolo');
      expect(json['village'], 'Not yet provided');
    });

    test('the placeholder gender asserts nothing about the person', () {
      // Sign-up never asks, so anything other than OTHER would be a claim.
      expect(OnboardingDefaults.gender, Gender.other);
    });

    test('a placeholder profile is detectable so it can be completed later', () {
      expect(
        OnboardingDefaults.looksPlaceholder(
          village: OnboardingDefaults.village,
        ),
        isTrue,
      );
      expect(
        OnboardingDefaults.looksPlaceholder(village: 'Msinja Village'),
        isFalse,
      );
      expect(OnboardingDefaults.looksPlaceholder(village: null), isTrue);
    });
  });

  group('VerificationProgressSheet', () {
    testWidgets('walks the steps and returns the result', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => VerificationProgressSheet.show<bool>(
                context: context,
                steps: const [
                  VerificationStep(
                    'Validating your details',
                    duration: Duration(milliseconds: 10),
                    isReal: true,
                  ),
                  VerificationStep(
                    'Checking the national banking database',
                    duration: Duration(milliseconds: 10),
                  ),
                ],
                work: () async => true,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.text('Verifying your details'), findsOneWidget);
      expect(
        find.text('Checking the national banking database'),
        findsOneWidget,
      );
      // The unreal step is tagged, so nobody mistakes it for a real lookup.
      expect(find.text('simulated check'), findsOneWidget);

      await tester.pumpAndSettle();
      // Dialog closed once the work finished.
      expect(find.text('Verifying your details'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failure is shown rather than silently dismissed', (
      tester,
    ) async {
      await _pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => VerificationProgressSheet.show<bool>(
                context: context,
                steps: const [
                  VerificationStep(
                    'Validating your details',
                    duration: Duration(milliseconds: 10),
                    isReal: true,
                  ),
                ],
                work: () async => throw 'Phone number already registered.',
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      // Several pumps: the failure surfaces across async gaps, not in one frame.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('Could not complete'), findsOneWidget);
      expect(
        find.text('Phone number already registered.'),
        findsOneWidget,
      );

      // The sheet holds the failure on screen for ~900ms before closing. That
      // is a bare Future.delayed, which pumpAndSettle will not advance because
      // no frames are scheduled, so the clock has to be moved explicitly.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();
      expect(find.text('Could not complete'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('loan review helpers', () {
    Loan pending({double requested = 100000, double rate = 15}) => Loan(
      id: 'l1',
      loanProductId: 'p1',
      amountRequested: requested,
      interestRate: rate,
      amountRepaid: 0,
      outstandingBalance: 0,
      status: LoanStatus.pending,
      lendingScoreAtApplication: 300,
      farmerName: 'Simple Form Farmer',
      farmerPhone: '+265700000701',
    );

    test('a pending application is flagged for review', () {
      expect(pending().isPending, isTrue);
      expect(pending().isActive, isFalse);
    });

    test('projected total shows what approving commits the institution to', () {
      // 100,000 at 15% simple interest.
      expect(pending().projectedTotalPayable, 115000);
    });

    test('the applicant identity comes from the API join', () {
      final loan = Loan.fromJson({
        'id': 'l2',
        'loan_product_id': 'p1',
        'amount_requested': '250000.00',
        'interest_rate': '18.50',
        'amount_repaid': '0.00',
        'outstanding_balance': '0.00',
        'status': 'PENDING',
        'lending_score_at_application': 415,
        'farmer_name': 'Kondwani Banda',
        'farmer_phone': '+265991000001',
      });

      expect(loan.farmerName, 'Kondwani Banda');
      expect(loan.farmerPhone, '+265991000001');
      expect(loan.lendingScoreAtApplication, 415);
    });
  });
}
