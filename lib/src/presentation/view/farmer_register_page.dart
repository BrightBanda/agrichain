import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/enums.dart';
import '../../data/models/requests.dart';
import '../viewmodel/auth_view_model.dart';
import 'login_page.dart';
import 'widgets/app_text_field.dart';
import 'widgets/submit_button.dart';

/// `POST /auth/register/farmer` — identity, KYC and location details.
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
  final _district = TextEditingController();
  final _traditionalAuthority = TextEditingController();
  final _village = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  Gender _gender = Gender.male;

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _nationalId,
      _district,
      _traditionalAuthority,
      _village,
      _phone,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final request = FarmerRegisterRequest(
      fullName: _fullName.text.trim(),
      nationalIdNumber: _nationalId.text.trim(),
      gender: _gender,
      district: _district.text.trim(),
      traditionalAuthority: _traditionalAuthority.text.trim(),
      village: _village.text.trim(),
      phoneNumber: _phone.text.trim(),
      password: _password.text,
      confirmPassword: _confirmPassword.text,
    );

    final registered = await ref
        .read(authViewModelProvider.notifier)
        .registerFarmer(request);

    if (registered && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${next.error}'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        title: const Text(
          'Farmer Registration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create your farmer account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'These details verify your identity so lenders can assess '
                  'your credit profile.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 22),

                _sectionLabel('Personal Details'),
                AppTextField(
                  controller: _fullName,
                  label: 'Full Name',
                  hint: 'Kondwani Banda',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  validator: (value) =>
                      Validators.required(value, 'Full name'),
                ),
                AppTextField(
                  controller: _nationalId,
                  label: 'National ID Number',
                  hint: 'MW12345678ABCD',
                  icon: Icons.badge_outlined,
                  validator: (value) =>
                      Validators.required(value, 'National ID number'),
                ),
                AppDropdownField<Gender>(
                  label: 'Gender',
                  value: _gender,
                  icon: Icons.wc_outlined,
                  items: Gender.values
                      .map(
                        (gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _gender = value ?? Gender.other),
                ),

                _sectionLabel('Location'),
                AppTextField(
                  controller: _district,
                  label: 'District',
                  hint: 'Lilongwe',
                  icon: Icons.map_outlined,
                  validator: (value) => Validators.required(value, 'District'),
                ),
                AppTextField(
                  controller: _traditionalAuthority,
                  label: 'Traditional Authority',
                  hint: 'T/A Kalolo',
                  icon: Icons.account_balance_outlined,
                  validator: (value) =>
                      Validators.required(value, 'Traditional authority'),
                ),
                AppTextField(
                  controller: _village,
                  label: 'Village',
                  hint: 'Msinja Village',
                  icon: Icons.home_outlined,
                  validator: (value) => Validators.required(value, 'Village'),
                ),

                _sectionLabel('Login Credentials'),
                AppTextField(
                  controller: _phone,
                  label: 'Phone Number',
                  hint: '+265999123456',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: Validators.password,
                ),
                AppTextField(
                  controller: _confirmPassword,
                  label: 'Confirm Password',
                  icon: Icons.lock_reset_outlined,
                  obscureText: true,
                  validator: (value) {
                    if (value != _password.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                SubmitButton(
                  label: 'Create Farmer Account',
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            ref.read(authViewModelProvider.notifier)
                                .clearError();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                    child: const Text(
                      'Already registered? Sign in',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.primaryMuted,
        ),
      ),
    );
  }
}
