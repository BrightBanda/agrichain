import 'package:agri/src/utils/role_card.dart';
import 'package:flutter/material.dart';

class AccountSelectionPage extends StatelessWidget {
  const AccountSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA), // Soft light background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Top Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFD2ECE0),
                        child: Text(
                          'MW',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AgriChain Malawi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2419),
                        ),
                      ),
                    ],
                  ),
                  // Language Dropdown Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.language, size: 16, color: Color(0xFF1B6B44)),
                        SizedBox(width: 6),
                        Text(
                          'English',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B6B44),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF1B6B44)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Verified Fintech Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F7ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_outlined, size: 16, color: Color(0xFF0F6838)),
                    SizedBox(width: 6),
                    Text(
                      'Verified AgriChain',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F6838),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Page Title & Subtitle
              const Text(
                'Who are you?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1C12),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Select how you want to access credit, markets, and farming services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Farmer Account Card
              RoleCard(
                tagText: '🌾 REGISTER AS FARMER',
                tagColor: const Color(0xFFE0F2E9),
                tagTextColor: const Color(0xFF0F6838),
                title: 'Farmer Account',
                description:
                    'Access seed & fertilizer loans, sell crops at good prices, track farm health.',
                actionText: 'Create Farmer Account',
                borderColor: const Color(0xFF2E7D32),
                icon: Icons.eco_outlined,
                iconBgColor: const Color(0xFFD4F3E2),
                iconColor: const Color(0xFF1B6B44),
                onTap: () {},
              ),
              const SizedBox(height: 16),

              // 5. Loan Institution Card
              RoleCard(
                tagText: '🏦 REGISTER AS LOAN INSTITUTION',
                tagColor: const Color(0xFFEEF2FF),
                tagTextColor: const Color(0xFF2563EB),
                title: 'Loan Institution Portal',
                description:
                    'Review farmer loan requests, verify yield records, disburse input vouchers.',
                actionText: 'Register Loan Institution',
                borderColor: const Color(0xFFD0E1FD),
                icon: Icons.apartment_outlined,
                iconBgColor: const Color(0xFFE0EBFF),
                iconColor: const Color(0xFF2563EB),
                onTap: () {},
              ),
              const SizedBox(height: 32),

              // 6. Sign In Section
              const Text(
                'Already have an account?',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor:Color(0xFF0F6838), // Dark navy button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign In To Your Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}