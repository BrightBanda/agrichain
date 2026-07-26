import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/ledger.dart';
import '../../data/repositories/blockchain_repository.dart';
import '../viewmodel/ledger_view_model.dart';
import 'widgets/ledger_widgets.dart';

/// One block in full, plus a live check of the record it attests to.
class BlockDetailPage extends ConsumerWidget {
  final LedgerBlock block;

  const BlockDetailPage({super.key, required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        title: Text(
          'Block #${block.index}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Header(block: block),
            const SizedBox(height: 18),

            if (block.isRecordVerifiable) ...[
              _RecordVerificationCard(block: block),
              const SizedBox(height: 18),
            ],

            _Section(
              title: 'Hashes',
              children: [
                _HashField(
                  label: 'Block hash',
                  hash: block.blockHash,
                  note:
                      'The SHA-256 of everything in this block, including the '
                      'previous block\'s hash.',
                ),
                _HashField(
                  label: 'Previous block',
                  hash: block.previousHash,
                  note: block.isGenesis
                      ? 'All zeroes: this is the first block in the chain.'
                      : 'Changing block #${block.index - 1} would break this link.',
                ),
                _HashField(
                  label: 'Payload hash',
                  hash: block.payloadHash,
                  note:
                      'The committed fingerprint of the event. The event data '
                      'itself is never stored on the ledger.',
                ),
              ],
            ),
            const SizedBox(height: 18),

            _Section(
              title: 'Proof of work',
              children: [
                _Row(label: 'Nonce', value: '${block.nonce}'),
                _Row(
                  label: 'Difficulty',
                  value:
                      '${block.difficulty} leading zero${block.difficulty == 1 ? '' : 's'}',
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'The nonce was searched for until the block hash started '
                    'with ${'0' * block.difficulty}. Difficulty is kept low so '
                    'mining is instant in this simulation.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),

            if (block.payloadSummary.isNotEmpty) ...[
              const SizedBox(height: 18),
              _Section(
                title: 'Public summary',
                children: [
                  for (final entry in block.payloadSummary.entries)
                    _Row(
                      label: _humanise(entry.key),
                      value: '${entry.value}',
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Non-sensitive context only. Personal details stay in the '
                      'database and never reach the ledger.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _humanise(String key) {
    final words = key.replaceAll('_', ' ');
    return words.isEmpty
        ? words
        : words.replaceRange(0, 1, words[0].toUpperCase());
  }
}

class _Header extends StatelessWidget {
  final LedgerBlock block;

  const _Header({required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cardTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              iconForEvent(block.eventType),
              color: AppColors.primaryMuted,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.eventType.label,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  block.eventType.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
                if (block.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Mined ${_formatTimestamp(block.createdAt!)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

/// Re-hashes the live database row and compares it against this block.
class _RecordVerificationCard extends ConsumerWidget {
  final LedgerBlock block;

  const _RecordVerificationCard({required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = (type: block.entityType, id: block.entityId!);
    final state = ref.watch(recordVerificationProvider(target));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${block.entityType.label} record',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Check again',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () =>
                    ref.invalidate(recordVerificationProvider(target)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          switch (state) {
            AsyncValue(hasError: true, :final error) => Text(
              '$error',
              style: const TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
            AsyncValue(hasValue: true, :final value?) => _VerificationResult(
              result: value,
            ),
            _ => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Re-hashing the stored record…',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ],
              ),
            ),
          },

          if (kDebugMode && block.isRecordVerifiable) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.science_outlined, size: 16),
                label: const Text('Tamper with this record (demo)'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _tamper(context, ref, target),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Edits the underlying row, leaving the chain untouched — the realistic
  /// attack, and the one that shows why anchoring is worth doing.
  Future<void> _tamper(
    BuildContext context,
    WidgetRef ref,
    ({LedgerEntityType type, String id}) target,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tamper with this record?'),
        content: const Text(
          'This will double a numeric field on the stored record — the kind of '
          'edit that would flatter a credit profile. The ledger is left alone, '
          'so verification should catch the change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Tamper'),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false) || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(blockchainRepositoryProvider)
          .demoTamperRecord(entityType: target.type, entityId: target.id);
      ref.invalidate(recordVerificationProvider(target));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: result.matches
                ? AppColors.primary
                : Colors.red.shade700,
            duration: const Duration(seconds: 6),
            content: Text(result.message),
          ),
        );
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('$error'),
          ),
        );
    }
  }
}

class _VerificationResult extends StatelessWidget {
  final RecordVerification result;

  const _VerificationResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final good = result.matches;
    final color = good ? AppColors.primary : Colors.red.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              good ? Icons.check_circle_outline : Icons.gpp_bad_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                good
                    ? 'Unchanged since it was anchored'
                    : result.anchored
                          ? 'Does not match the ledger'
                          : 'Not anchored',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          result.message,
          style: const TextStyle(
            fontSize: 12.5,
            color: Colors.black87,
            height: 1.35,
          ),
        ),
        // When the hashes diverge, showing both makes the mismatch concrete.
        if (!good && result.currentPayloadHash != null) ...[
          const SizedBox(height: 10),
          _HashField(
            label: 'Committed on the ledger',
            hash: result.anchoredPayloadHash ?? '',
            note: null,
          ),
          _HashField(
            label: 'Hash of the record today',
            hash: result.currentPayloadHash!,
            note: null,
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.primaryMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _HashField extends StatelessWidget {
  final String label;
  final String hash;
  final String? note;

  const _HashField({required this.label, required this.hash, this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HashText(hash: hash, copyable: true),
          ),
          if (note != null) ...[
            const SizedBox(height: 5),
            Text(
              note!,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
