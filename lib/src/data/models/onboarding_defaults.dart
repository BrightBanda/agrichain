import 'enums.dart';

/// Placeholder KYC details for the fields sign-up does not ask for.
///
/// Sign-up collects only what is needed to establish an identity — name,
/// national ID, phone and password. The backend still requires gender and the
/// district/traditional-authority/village hierarchy, so these stand in.
///
/// **These values are hashed into the FARMER_REGISTERED ledger block**, which
/// means they become part of the anchored KYC record a lender would verify.
/// Replace this with a real onboarding step (or make the fields nullable
/// backend-side) before any live deployment. Everything is in one place so that
/// swap is a single edit.
class OnboardingDefaults {
  const OnboardingDefaults._();

  /// Least assertive option: sign-up never asks, so nothing is claimed about
  /// the person.
  static const Gender gender = Gender.other;

  static const String district = 'Lilongwe';
  static const String traditionalAuthority = 'T/A Kalolo';
  static const String village = 'Not yet provided';

  /// True when a profile still carries the placeholders, so a screen can prompt
  /// the farmer to complete their details rather than showing them as final.
  static bool looksPlaceholder({String? village}) =>
      village == null || village == OnboardingDefaults.village;
}
