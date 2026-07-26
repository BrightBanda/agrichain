import 'package:flutter/material.dart';

/// The palette already in use across the AgriChain screens, named once so new
/// screens stop re-declaring the same hex values.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF0F6838);
  static const Color primaryDark = Color(0xFF0F5234);
  static const Color primaryMuted = Color(0xFF1B6B44);
  static const Color accentSoft = Color(0xFFE2F7ED);
  static const Color cardTint = Color(0xFFD4F3E2);
  static const Color background = Color(0xFFF7F9FA);
  static const Color textDark = Color(0xFF0D1C12);
  static const Color textHeading = Color(0xFF0F2419);
  static const Color institution = Color(0xFF2563EB);
  static const Color institutionSoft = Color(0xFFEEF2FF);

  /// Score card gradient, brighter than [primaryDark] so it leads the page.
  static const Color scoreTop = Color(0xFF13804C);
  static const Color scoreBottom = Color(0xFF0B5533);

  // Pending / attention states.
  static const Color warning = Color(0xFF9A6700);
  static const Color warningSoft = Color(0xFFFFF7E0);
  static const Color warningBorder = Color(0xFFF5E0A3);

  // Farmer tier badges.
  static const Color gold = Color(0xFF8A5A00);
  static const Color goldSoft = Color(0xFFFFDF8E);

  // Amounts owed and overdue dates.
  static const Color danger = Color(0xFFC62828);
  static const Color dangerSoft = Color(0xFFFDECEC);

  /// Positive deltas, e.g. "+18% harvest".
  static const Color positive = Color(0xFF15803D);

  static const Color cardBorder = Color(0xFFE7EBEE);
  static const Color surfaceMuted = Color(0xFFF3F6F8);
  static const Color textMuted = Color(0xFF667085);
}
