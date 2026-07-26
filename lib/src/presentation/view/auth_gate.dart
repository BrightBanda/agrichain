import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../viewmodel/auth_view_model.dart';
import 'AccountSelectionPage.dart';
import 'farmer_shell_page.dart';

/// Chooses the root screen from the restored session.
///
/// A failed sign-in leaves the auth state in [AsyncError]; that is still a
/// signed-out session, so it falls through to the account selection screen
/// where the form shows the error.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    if (authState.isLoading && !authState.hasValue) {
      return const _SplashScreen();
    }

    return authState.value is Authenticated
        ? const FarmerShellPage()
        : const AccountSelectionPage();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AgriChain',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white70),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
