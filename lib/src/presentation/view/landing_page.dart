import 'package:agri/src/utils/feature_card.dart';
import 'package:agri/src/utils/primary_button.dart';
import 'package:agri/src/utils/secondary_button.dart';
import 'package:flutter/material.dart';

/// =======================
/// View (UI Layer)
/// =======================
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
              const SizedBox(height: 40),
              const Text(
                "AgriChain",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Agricultural Finance & Credit Platform",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),

              /// Features Section
              Expanded(
                child: ListView(
                  children: const [
                    FeatureCard(
                      icon: Icons.credit_score,
                      title: "Smart Agri Credit Score",
                      description:
                          "Unlock loans based on land GIS and verified yield records.",
                    ),
                    FeatureCard(
                      icon: Icons.shopping_cart,
                      title: "Instant Input Financing",
                      description:
                          "Get seed, fertilizer, and equipment vouchers instantly.",
                    ),
                    FeatureCard(
                      icon: Icons.store,
                      title: "Direct Market Connections",
                      description:
                          "Sell directly to grain mills and secure fair prices.",
                    ),
                  ],
                ),
              ),

              /// Buttons Section
              const SizedBox(height: 20),
              PrimaryButton(
                label: "Create Account",
                onPressed: () {
                  // Logic handled later
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: "sign in",
                onPressed: () {
                  // Logic handled later
                },
              ),

              const SizedBox(height: 20),
              const Text(
                "Powered by AgriChain Financial Inclusion Initiative - Material 3",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}