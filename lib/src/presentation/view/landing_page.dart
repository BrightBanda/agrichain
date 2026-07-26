import 'package:agri/src/utils/feature_card.dart';
import 'package:agri/src/utils/primary_button.dart';
import 'package:agri/src/utils/secondary_button.dart';
import 'package:flutter/material.dart';

import 'AccountSelectionPage.dart';
import 'login_page.dart';

/// The unauthenticated entry point.
///
/// Three ways in: create an account (the next screen asks farmer or service
/// provider), sign in, or the bank admin route used to verify loans.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 4),

              // Staff route into the same credentials flow. The role on the
              // account decides what appears after sign-in, so this is a
              // labelled shortcut rather than a separate authority.
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(
                      title: 'National Bank Admin Access',
                      subtitle:
                          'Sign in with your institution account to review and '
                          'verify farmer loan applications.',
                    ),
                  ),
                ),
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
