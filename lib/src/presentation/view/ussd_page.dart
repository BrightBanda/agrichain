import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../utils/ussd_keypad.dart';
import '../../utils/responsive.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/farmer_dashboard_view_model.dart';
import '../viewmodel/product_list_view_model.dart';
import '../viewmodel/ussd_simulator.dart';

/// The USSD menu (FR-25), for farmers on basic phones and poor connectivity.
///
/// This is a simulation of the interaction, not a telco integration: there is no
/// short code and no aggregator gateway, so nothing here is reachable from an
/// actual handset. The menu tree, the one-digit replies and the plain-text
/// responses behave exactly as the real thing would, and every figure comes from
/// the same live API the full app uses.
class UssdPage extends ConsumerStatefulWidget {
  const UssdPage({super.key});

  @override
  ConsumerState<UssdPage> createState() => _UssdPageState();
}

class _UssdPageState extends ConsumerState<UssdPage> {
  static const _shortCode = '*384*2020#';

  String _reply = '';
  final _session = UssdSimulator();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dashboard = ref.watch(farmerDashboardProvider).value;
    final products = ref.watch(productListViewModelProvider).value ?? const [];

    // The session keeps the current screen; the data is refreshed on every
    // build so a dashboard that finishes loading later is picked up.
    final session = _session
      ..updateData(user: user, dashboard: dashboard, products: products);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        centerTitle: true,
        title: const Text(
          'USSD Menu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: PageWidth(
          child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Simulation. AgriChain has no telco short code yet, so '
                      'this cannot be dialled from a real phone — but the menu '
                      'and the data behind it are real.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            UssdDisplay(text: session.display, shortCode: _shortCode),
            const SizedBox(height: 14),

            // Reply line, mirroring the input box of a USSD dialog.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: _reply.isEmpty
                      ? AppColors.cardBorder
                      : AppColors.primary,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Reply: ',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      session.isEnded
                          ? '—'
                          : _reply.isEmpty
                                ? 'enter a number'
                                : _reply,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _reply.isEmpty
                            ? AppColors.textMuted
                            : AppColors.textHeading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (session.isEnded)
              _RestartPanel(
                onRestart: () => setState(() {
                  session.restart();
                  _reply = '';
                }),
                onClose: () => Navigator.of(context).maybePop(),
              )
            else
              UssdKeypad(
                onDigit: (digit) => setState(() {
                  // Real USSD replies are short; two digits covers "00".
                  if (_reply.length < 2) _reply += digit;
                }),
                onBackspace: () => setState(() {
                  if (_reply.isNotEmpty) {
                    _reply = _reply.substring(0, _reply.length - 1);
                  }
                }),
                onCancel: () => Navigator.of(context).maybePop(),
                onSend: _reply.isEmpty
                    ? null
                    : () => setState(() {
                        session.reply(_reply);
                        _reply = '';
                      }),
              ),
          ],
        )),
      ),
    );
  }
}

class _RestartPanel extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _RestartPanel({required this.onRestart, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: const BorderSide(color: AppColors.cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text(
              'Dial Again',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
