import 'package:agri/main.dart';
import 'package:agri/src/presentation/view/AccountSelectionPage.dart';
import 'package:agri/src/presentation/viewmodel/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// An [AuthViewModel] that resolves immediately, so the test never touches
/// secure storage or the network.
class _SignedOutAuthViewModel extends AuthViewModel {
  @override
  Future<AuthState> build() async => const Unauthenticated();
}

void main() {
  testWidgets('signed-out users land on the account selection screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(_SignedOutAuthViewModel.new),
        ],
        child: const MyApp(),
      ),
    );

    // Resolve the async build() of the auth view model.
    await tester.pumpAndSettle();

    expect(find.byType(AccountSelectionPage), findsOneWidget);
    expect(find.text('Who are you?'), findsOneWidget);
    expect(find.text('Sign In To Your Account'), findsOneWidget);
  });
}
