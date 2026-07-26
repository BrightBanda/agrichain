import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/ledger.dart';

/// Icon for each anchored event type.
IconData iconForEvent(LedgerEventType event) => switch (event) {
  LedgerEventType.genesis => Icons.flag_outlined,
  LedgerEventType.farmerRegistered => Icons.badge_outlined,
  LedgerEventType.produceListed => Icons.storefront_outlined,
  LedgerEventType.harvestRecorded => Icons.grass_outlined,
  LedgerEventType.harvestVerified => Icons.verified_outlined,
  LedgerEventType.loanAgreement => Icons.handshake_outlined,
  LedgerEventType.repaymentRecorded => Icons.payments_outlined,
  LedgerEventType.scoreUpdated => Icons.trending_up,
  LedgerEventType.unknown => Icons.help_outline,
};

/// Chain-wide counters and the simulation disclaimer.
class ChainSummaryCard extends StatelessWidget {
  final ChainStats stats;

  const ChainSummaryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'AgriChain Ledger',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (stats.isSimulation)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SIMULATION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(label: 'Blocks', value: '${stats.blockCount}'),
              _Metric(label: 'Difficulty', value: '${stats.difficulty}'),
              _Metric(
                label: 'Event types',
                value: '${stats.events.length}',
              ),
            ],
          ),
          if (stats.tipHash != null) ...[
            const SizedBox(height: 14),
            const Text(
              'CHAIN TIP',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            HashText(
              hash: stats.tipHash!,
              color: Colors.white,
              copyable: true,
            ),
          ],
          if (stats.note.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              stats.note,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Green when the chain re-hashes cleanly, red with the reasons when it does not.
class ChainIntegrityBanner extends StatelessWidget {
  final ChainIntegrity integrity;

  const ChainIntegrityBanner({super.key, required this.integrity});

  @override
  Widget build(BuildContext context) {
    final valid = integrity.valid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: valid ? AppColors.accentSoft : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: valid ? const Color(0xFFB6E3CD) : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                valid ? Icons.shield_outlined : Icons.gpp_bad_outlined,
                color: valid ? AppColors.primary : Colors.red.shade700,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valid ? 'Chain verified' : 'Tampering detected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: valid
                            ? AppColors.primary
                            : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valid
                          ? 'All ${integrity.blockCount} blocks re-hash correctly '
                                'and every link holds.'
                          : '${integrity.problems.length} problem(s) found across '
                                '${integrity.blockCount} blocks.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!valid) ...[
            const SizedBox(height: 12),
            for (final problem in integrity.problems.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${problem.index}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            problem.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            problem.detail,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black54,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// One row in the chain list.
class BlockTile extends StatelessWidget {
  final LedgerBlock block;
  final bool isBroken;
  final VoidCallback onTap;

  const BlockTile({
    super.key,
    required this.block,
    required this.onTap,
    this.isBroken = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBroken ? Colors.red.shade300 : Colors.grey.shade200,
            width: isBroken ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isBroken ? Colors.red.shade50 : AppColors.cardTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconForEvent(block.eventType),
                size: 22,
                color: isBroken ? Colors.red.shade700 : AppColors.primaryMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${block.index}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          block.eventType.label,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      if (isBroken)
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  HashText(hash: block.blockHash, short: true),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

/// A hash rendered in monospace, optionally shortened and copyable.
class HashText extends StatelessWidget {
  final String hash;
  final bool short;
  final bool copyable;
  final Color? color;

  const HashText({
    super.key,
    required this.hash,
    this.short = false,
    this.copyable = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      short ? shortenHash(hash) : hash,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: short ? 11.5 : 12,
        color: color ?? Colors.black54,
        height: 1.35,
      ),
    );

    if (!copyable) return text;

    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: hash));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Hash copied'),
              duration: Duration(seconds: 2),
            ),
          );
      },
      child: Row(
        children: [
          Expanded(child: text),
          Icon(Icons.copy, size: 14, color: color?.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

class LedgerErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LedgerErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 40, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
