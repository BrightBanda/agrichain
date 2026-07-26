import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/demo_accounts.dart';
import '../../../data/models/enums.dart';
import '../../viewmodel/auth_view_model.dart';

/// Signs in as one of the seeded demo accounts.
///
/// This is a shortcut past typing credentials, not past authentication: it calls
/// the same sign-in the login form does, and AuthGate then routes on the role the
/// backend returns. If the seed script has not been run the accounts do not
/// exist and sign-in fails with the backend's own message.
class DemoAccountSheet extends ConsumerStatefulWidget {
  const DemoAccountSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const DemoAccountSheet(),
    );
  }

  @override
  ConsumerState<DemoAccountSheet> createState() => _DemoAccountSheetState();
}

class _DemoAccountSheetState extends ConsumerState<DemoAccountSheet> {
  String? _signingIn;

  Future<void> _signIn(DemoAccount account) async {
    setState(() => _signingIn = account.phoneNumber);

    final ok = await ref
        .read(authViewModelProvider.notifier)
        .signIn(
          phoneNumber: account.phoneNumber,
          password: account.password,
        );

    if (!mounted) return;

    if (ok) {
      // AuthGate swaps the root; close the sheet and any auth screens behind it.
      Navigator.of(context).pop();
      return;
    }

    setState(() => _signingIn = null);
    final error = ref.read(authViewModelProvider).error;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 7),
          content: Text(
            '${error ?? 'Could not sign in.'}\n'
            'Run "python seed_demo.py" to create the demo accounts.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test accounts',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign in instantly as a pre-made account. Created by the seed '
              'script, so each one holds real data.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            for (final account in DemoAccounts.all)
              _AccountRow(
                account: account,
                isBusy: _signingIn == account.phoneNumber,
                isDisabled: _signingIn != null &&
                    _signingIn != account.phoneNumber,
                onTap: () => _signIn(account),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final DemoAccount account;
  final bool isBusy;
  final bool isDisabled;
  final VoidCallback onTap;

  const _AccountRow({
    required this.account,
    required this.isBusy,
    required this.isDisabled,
    required this.onTap,
  });

  IconData get _icon => switch (account.role) {
    UserRole.farmer => Icons.eco_outlined,
    UserRole.supplier => Icons.storefront_outlined,
    UserRole.financialInstitution => Icons.account_balance_outlined,
    _ => Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1,
      child: InkWell(
        onTap: isDisabled || isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardTint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_icon, size: 19, color: AppColors.primaryMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
