import 'package:flutter/material.dart';

class AuthFooterButtons extends StatelessWidget {
  final VoidCallback onRegisterTap;
  final VoidCallback onResetPinTap;

  const AuthFooterButtons({
    super.key,
    required this.onRegisterTap,
    required this.onResetPinTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Don't have an account? Register Here →
        TextButton(
          onPressed: onRegisterTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "Don't have an account? Register Here →",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF135D39), // Dark Green accent
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Forgot Password / Reset PIN?
        TextButton(
          onPressed: onResetPinTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot Password / Reset PIN?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5A6978), // Muted grey
            ),
          ),
        ),
      ],
    );
  }
}