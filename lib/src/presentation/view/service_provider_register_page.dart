import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../data/models/requests.dart';
import '../../utils/service_selector.dart';
import '../viewmodel/auth_view_model.dart';
import 'widgets/app_text_field.dart';
import 'widgets/submit_button.dart';

/// Registers a service provider — a business selling seeds, fertilizer,
/// equipment and other inputs (FR-01, FR-11).
class ServiceProviderRegisterPage extends ConsumerStatefulWidget {
  const ServiceProviderRegisterPage({super.key});

  @override
  ConsumerState<ServiceProviderRegisterPage> createState() =>
      _ServiceProviderRegisterPageState();
}

class _ServiceProviderRegisterPageState
    extends ConsumerState<ServiceProviderRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _phone = TextEditingController();
  final _district = TextEditingController();
  final _description = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final _services = <ProductType>{};
  bool _servicesTouched = false;

  @override
  void dispose() {
    for (final controller in [
      _businessName,
      _phone,
      _district,
      _description,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);

    // Surface a failed registration without rebuilding the form state.
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.hasError && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 6),
              content: Text('${next.error}'),
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
          'Service Provider Account',
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
                'Sell seeds, fertilizer, sprays and equipment to farmers across '
                'Malawi.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              AppTextField(
                controller: _businessName,
                label: 'Business name',
                hint: 'Farmers World Malawi',
                icon: Icons.storefront_outlined,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter your business name'
                    : null,
              ),
              AppTextField(
                controller: _phone,
                label: 'Phone number',
                hint: '+265888100200',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter a phone number'
                    : null,
              ),
              AppTextField(
                controller: _district,
                label: 'District (optional)',
                hint: 'Lilongwe',
                icon: Icons.location_on_outlined,
              ),
              AppTextField(
                controller: _description,
                label: 'About your business (optional)',
                hint: 'Certified seed and fertilizer supplier since 2014.',
                maxLines: 3,
              ),

              const SizedBox(height: 4),
              ServiceSelector(
                selected: _services,
                errorText: _servicesTouched && _services.isEmpty
                    ? 'Choose at least one category'
                    : null,
                onToggle: (service) => setState(() {
                  _servicesTouched = true;
                  if (!_services.remove(service)) _services.add(service);
                }),
              ),
              const SizedBox(height: 18),

              AppTextField(
                controller: _password,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) => (value ?? '').length < 6
                    ? 'Use at least 6 characters'
                    : null,
              ),
              AppTextField(
                controller: _confirmPassword,
                label: 'Confirm password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) => value != _password.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 8),

              SubmitButton(
                label: 'Create Service Provider Account',
                isLoading: auth.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _servicesTouched = true);

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _services.isEmpty) return;

    final created = await ref
        .read(authViewModelProvider.notifier)
        .registerServiceProvider(
          ServiceProviderRegisterRequest(
            businessName: _businessName.text.trim(),
            phoneNumber: _phone.text.trim(),
            password: _password.text,
            confirmPassword: _confirmPassword.text,
            services: _services.toList(),
            district: _district.text.trim(),
            description: _description.text.trim(),
          ),
        );

    // AuthGate swaps the root once signed in; unwind the auth screens.
    if (created && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
