import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_brand_header.dart';
import '../../viewmodel/auth_view_model.dart';
import '../blockchain_explorer_page.dart';
import '../ussd_page.dart';

/// Two initials for the avatar, from a display name.
String? initialsOf(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

/// [AppBrandHeader] with the app's standard actions wired up.
///
/// Every signed-in screen uses this rather than wiring USSD, the ledger and
/// sign-out five separate times — which is how the ledger entry point got lost
/// once already.
class AppHeader extends ConsumerWidget {
  final String subtitle;

  /// Overrides the role badge text; defaults to the signed-in user's role.
  final String? roleLabel;

  const AppHeader({super.key, required this.subtitle, this.roleLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return AppBrandHeader(
      roleLabel: roleLabel ?? user?.role.label ?? 'Farmer',
      subtitle: subtitle,
      avatarInitials: initialsOf(user?.displayName),
      onUssdTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const UssdPage())),
      onLedgerTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BlockchainExplorerPage())),
      // No notifications or i18n endpoints yet, so these say so rather than
      // appearing to work.
      onNotificationsTap: () => _notAvailable(context, 'Notifications'),
      onLanguageTap: () => _notAvailable(context, 'Language switching'),
      onAvatarTap: () => _confirmSignOut(context, ref),
    );
  }

  static void _notAvailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is not available yet.')));
  }

  static Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need your phone number and password to sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut ?? false) {
      await ref.read(authViewModelProvider.notifier).signOut();
    }
  }
}
