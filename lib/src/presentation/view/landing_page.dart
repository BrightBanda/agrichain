import 'package:agri/src/utils/feature_card.dart';
import 'package:agri/src/utils/primary_button.dart';
import 'package:agri/src/utils/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/demo_accounts.dart';
import '../viewmodel/auth_view_model.dart';
import 'AccountSelectionPage.dart';
import 'login_page.dart';
import 'widgets/demo_account_sheet.dart';

/// The unauthenticated entry point.
///
/// Three ways in: create an account (the next screen asks farmer or service
/// provider), sign in, or the bank admin route used to verify loans.
class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  /// Signs in as the seeded bank admin and lets AuthGate route to the portal.
  ///
  /// "Directly" means without typing credentials, not without authenticating:
  /// the loan endpoints require a FINANCIAL_INSTITUTION token, so there is a
  /// real sign-in behind this.
  Future<void> _openAdminPortal(BuildContext context, WidgetRef ref) async {
    final account = DemoAccounts.bankAdmin;
    final ok = await ref.read(authViewModelProvider.notifier).signIn(
      phoneNumber: account.phoneNumber,
      password: account.password,
    );

    if (ok || !context.mounted) return;

    // No seeded admin: fall back to the form rather than failing silently.
    final error = ref.read(authViewModelProvider).error;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 7),
          content: Text(
            '${error ?? 'Could not sign in.'}\n'
            'Run "python seed_demo.py", or sign in with an institution account.',
          ),
        ),
      );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginPage(
          title: 'National Bank Admin Access',
          subtitle:
              'Sign in with your institution account to review and verify '
              'farmer loan applications.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F5234),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text(
                'AgriChain',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Agricultural Finance & Credit Platform',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: ListView(
                  children: const [
                    FeatureCard(
                      icon: Icons.credit_score,
                      title: 'Smart Agri Credit Score',
                      description:
                          'Unlock loans based on verified harvests and '
                          'repayment history.',
                    ),
                    FeatureCard(
                      icon: Icons.shopping_cart,
                      title: 'Instant Input Financing',
                      description:
                          'Get seed, fertilizer, and equipment vouchers '
                          'instantly.',
                    ),
                    FeatureCard(
                      icon: Icons.store,
                      title: 'Direct Market Connections',
                      description:
                          'Sell directly to grain mills and secure fair prices.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Create Account',
                // The next screen chooses farmer or service provider.
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountSelectionPage(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Sign In',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),
              if (DemoAccounts.enabled) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => DemoAccountSheet.show(context),
                  icon: const Icon(Icons.science_outlined, size: 16),
                  label: const Text(
                    'Use a test account',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),

              // Staff route into the same credentials flow. The role on the
              // account decides what appears after sign-in, so this is a
              // labelled shortcut rather than a separate authority.
              TextButton.icon(
                onPressed: () => _openAdminPortal(context, ref),
                icon: const Icon(
                  Icons.account_balance_outlined,
                  size: 14,
                  color: Colors.white60,
                ),
                label: const Text(
                  'National Bank Admin Access',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white60,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38,
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.white60),
              ),

              const SizedBox(height: 6),
              const Text(
                'Powered by the AgriChain Financial Inclusion Initiative',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
