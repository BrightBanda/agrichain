import 'dart:async';

import 'package:agri/src/presentation/view/landing_page.dart';
import 'package:agri/src/presentation/view/auth_gate.dart';
import 'package:agri/src/presentation/viewmodel/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Auth view models that resolve immediately, so the tests never touch secure
/// storage or the network.
class _SignedOutAuthViewModel extends AuthViewModel {
  @override
  Future<AuthState> build() async => const Unauthenticated();
}

/// Pumps [AuthGate] rather than `MyApp`, so these tests describe the routing
/// rule itself and stay valid while `main.dart`'s home screen is in flux.
Future<void> _pumpGate(WidgetTester tester, AuthViewModel Function() auth) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authViewModelProvider.overrideWith(auth)],
      child: const MaterialApp(home: AuthGate()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed-out users land on the landing screen', (tester) async {
    await _pumpGate(tester, _SignedOutAuthViewModel.new);

    // The landing page is the entry point; choosing "Create Account" is what
    // leads on to the farmer / service-provider choice.
    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('National Bank Admin Access'), findsOneWidget);
  });

  testWidgets('a splash screen shows while the session is being restored', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(_PendingAuthViewModel.new),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    // Deliberately not settled: the session restore is still in flight.
    await tester.pump();

    expect(find.text('AgriChain'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LandingPage), findsNothing);
  });
}

/// Never completes, modelling a slow read from secure storage.
class _PendingAuthViewModel extends AuthViewModel {
  @override
  Future<AuthState> build() => Completer<AuthState>().future;
}
