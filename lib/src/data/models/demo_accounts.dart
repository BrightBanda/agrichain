import 'enums.dart';

/// A pre-made account for demonstrations.
class DemoAccount {
  final String label;
  final String description;
  final String phoneNumber;
  final String password;
  final UserRole role;

  const DemoAccount({
    required this.label,
    required this.description,
    required this.phoneNumber,
    required this.password,
    required this.role,
  });
}

/// Sign-in shortcuts for demos, matching the accounts `seed_demo.py` creates.
///
/// **These are real credentials compiled into the app**, and [enabled] defaults
/// to true so they work in a hosted demo build. Turn them off for anything
/// resembling production:
///
/// ```
/// flutter build web --release --dart-define=DEMO_ACCOUNTS=false
/// ```
///
/// Nothing here bypasses the backend: each entry performs an ordinary sign-in
/// and the account's own role decides what the user then sees. The accounts only
/// exist if the seed script has been run.
class DemoAccounts {
  const DemoAccounts._();

  /// Shared by every seeded account. Mirrors `DEMO_ACCOUNT_PASSWORD` in `.env`.
  static const String password = 'Password123!';

  static const DemoAccount farmer = DemoAccount(
    label: 'Farmer — established',
    description:
        'Verified harvest, produce listed, a loan repaid. Qualifies for credit.',
    phoneNumber: '+265991000001',
    password: password,
    role: UserRole.farmer,
  );

  /// A brand-new farmer with no activity.
  ///
  /// Their score sits at 300, which is the credit engine's floor — scores cannot
  /// go below it. What makes this account useful is that 300 fails the minimum
  /// on most loan products, so the "not yet eligible" path is demonstrable.
  static const DemoAccount newFarmer = DemoAccount(
    label: 'Farmer — no score yet',
    description:
        'No verified activity, so the score sits at the 300 floor and most '
        'loans are out of reach.',
    phoneNumber: '+265991000004',
    password: password,
    role: UserRole.farmer,
  );

  static const DemoAccount serviceProvider = DemoAccount(
    label: 'Service provider',
    description: 'Sells seeds and fertilizer on the marketplace.',
    phoneNumber: '+265991000005',
    password: password,
    role: UserRole.supplier,
  );

  static const DemoAccount bankAdmin = DemoAccount(
    label: 'National bank admin',
    description: 'Reviews, approves and declines farmer loan applications.',
    phoneNumber: '+265991000003',
    password: password,
    role: UserRole.financialInstitution,
  );

  static const List<DemoAccount> all = [
    farmer,
    newFarmer,
    serviceProvider,
    bankAdmin,
  ];

  /// Whether the picker is offered at all. On by default for demo builds.
  static const bool enabled = bool.fromEnvironment(
    'DEMO_ACCOUNTS',
    defaultValue: true,
  );
}
