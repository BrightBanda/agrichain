import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A placeholder for a destination whose backend module does not exist yet.
///
/// It names the missing capability rather than showing a vague "coming soon",
/// so the gap is obvious to anyone demoing the app.
class ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String explanation;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: AppColors.cardTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 30, color: AppColors.primaryMuted),
                ),
                const SizedBox(height: 18),
                Text(
                  '$title is not built yet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  explanation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
