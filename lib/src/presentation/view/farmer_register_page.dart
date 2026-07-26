import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/onboarding_defaults.dart';
import '../../data/models/requests.dart';
import '../../utils/verification_progress_sheet.dart';
import '../viewmodel/auth_view_model.dart';
import 'login_page.dart';
import 'widgets/app_text_field.dart';
import 'widgets/submit_button.dart';

/// `POST /auth/register/farmer`.
///
/// Sign-up asks only for what establishes an identity: name, national ID, phone
/// and a password. The remaining KYC fields the backend expects are filled from
/// [OnboardingDefaults] — read that class before relying on them.
///
/// On success the view model signs the new farmer in automatically.
class FarmerRegisterPage extends ConsumerStatefulWidget {
  const FarmerRegisterPage({super.key});

  @override
  ConsumerState<FarmerRegisterPage> createState() => _FarmerRegisterPageState();
}

class _FarmerRegisterPageState extends ConsumerState<FarmerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _nationalId = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _nationalId,
      _phone,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The checks shown while registration runs.
  ///
  /// Only three do anything: validation, the real API call, and the ledger
  /// anchoring the backend performs inside it. The identity and credit lookups
  /// demonstrate what a production integration would do, and are tagged
  /// "simulated check" on screen so nobody mistakes them for real queries.
  static const _steps = [
    VerificationStep(
      'Validating your details',
      duration: Duration(milliseconds: 700),
      isReal: true,
    ),
    VerificationStep(
      'Checking the national ID registry',
      duration: Duration(milliseconds: 1100),
    ),
    VerificationStep(
      'Checking the national banking database',
      duration: Duration(milliseconds: 1300),
    ),
    VerificationStep(
      'Screening for existing credit records',
      duration: Duration(milliseconds: 1000),
    ),
    VerificationStep(
      'Creating your AgriChain identity',
      duration: Duration(milliseconds: 600),
      isReal: true,
    ),
    VerificationStep(
      'Anchoring your record to the ledger',
      duration: Duration(milliseconds: 800),
      isReal: true,
    ),
  ];

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final request = FarmerRegisterRequest(
      fullName: _fullName.text.trim(),
      nationalIdNumber: _nationalId.text.trim(),
      phoneNumber: _phone.text.trim(),
      password: _password.text,
      confirmPassword: _confirmPassword.text,
      // Not asked for at sign-up; see OnboardingDefaults.
      gender: OnboardingDefaults.gender,
      district: OnboardingDefaults.district,
      traditionalAuthority: OnboardingDefaults.traditionalAuthority,
      village: OnboardingDefaults.village,
    );

    final created = await VerificationProgressSheet.show<bool>(
      context: context,
      steps: _steps,
      work: () async {
        final ok = await ref
            .read(authViewModelProvider.notifier)
            .registerFarmer(request);
        if (!ok) {
          // Surface the view model's message inside the sheet.
          throw ref.read(authViewModelProvider).error ??
              'Registration failed. Please try again.';
        }
        return true;
      },
    );

    if (!mounted) return;

    if (created ?? false) {
      // AuthGate swaps the root once signed in; unwind the auth screens.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final error = ref.read(authViewModelProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
            content: Text('$error'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        centerTitle: true,
        title: const Text(
          'Create Farmer Account',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const Text(
                'Just a few details to get started. Your farm and location '
                'details are added later, from your profile.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              AppTextField(
                controller: _fullName,
                label: 'Full name',
                hint: 'Kondwani Banda',
                icon: Icons.person_outline,
                validator: (value) => Validators.required(value, 'Full name'),
              ),
              AppTextField(
                controller: _nationalId,
                label: 'National ID number',
                hint: 'MW12345678ABCD',
                icon: Icons.badge_outlined,
                validator: (value) =>
                    Validators.required(value, 'National ID number'),
              ),
              AppTextField(
                controller: _phone,
                label: 'Phone number',
                hint: '+265999123456',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.required(value, 'Phone number'),
              ),
              AppTextField(
                controller: _password,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) =>
                    (value ?? '').length < 6 ? 'Use at least 6 characters' : null,
              ),
              AppTextField(
                controller: _confirmPassword,
                label: 'Confirm password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) =>
                    value != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 6),

              SubmitButton(
                label: 'Create Account',
                isLoading: auth.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 14),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Already have an account? Sign in',
                    style: TextStyle(fontSize: 12.5),
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
