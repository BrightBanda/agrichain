import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/ledger.dart';
import '../viewmodel/ledger_view_model.dart';
import 'block_detail_page.dart';
import 'widgets/ledger_widgets.dart';

/// The AgriChain ledger explorer.
///
/// Shows every anchored event, re-verifies the chain on demand, and can
/// deliberately corrupt data to demonstrate that tampering is detected.
class BlockchainExplorerPage extends ConsumerWidget {
  const BlockchainExplorerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ledgerViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        title: const Text(
          'Ledger Explorer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Re-verify the chain',
            icon: const Icon(Icons.verified_outlined),
            onPressed: () => _verify(context, ref),
          ),
          if (kDebugMode)
            PopupMenuButton<String>(
              tooltip: 'Demonstrations',
              icon: const Icon(Icons.science_outlined),
              onSelected: (value) {
                if (value == 'tamper') _tamperDialog(context, ref);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'tamper',
                  child: Text('Tamper with a block…'),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          AsyncValue(hasError: true, :final error) => LedgerErrorState(
            message: '$error',
            onRetry: () => ref.invalidate(ledgerViewModelProvider),
          ),
          AsyncValue(hasValue: true, :final value?) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(ledgerViewModelProvider.notifier).refresh(),
            child: _Chain(snapshot: value),
          ),
          _ => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        },
      ),
    );
  }

  Future<void> _verify(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final integrity = await ref
        .read(ledgerViewModelProvider.notifier)
        .verifyChain();
    if (integrity == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: integrity.valid
              ? AppColors.primary
              : Colors.red.shade700,
          content: Text(
            integrity.valid
                ? 'All ${integrity.blockCount} blocks verified. The chain is intact.'
                : 'Chain broken: ${integrity.problems.length} problem(s) found.',
          ),
        ),
      );
  }

  /// Lets the demo pick a block to corrupt, so the audience sees the detection
  /// happen live rather than being told it would.
  Future<void> _tamperDialog(BuildContext context, WidgetRef ref) async {
    final blocks = ref.read(ledgerViewModelProvider).value?.blocks ?? const [];
    final candidates = blocks.where((block) => !block.isGenesis).toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anchor an event first — there is nothing to tamper with.'),
        ),
      );
      return;
    }

    final selected = await showDialog<LedgerBlock>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Corrupt which block?'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'This edits the block without re-mining it. Every block after it '
              'should then fail verification.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ),
          for (final block in candidates.take(12))
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(block),
              child: Text('#${block.index} · ${block.eventType.label}'),
            ),
        ],
      ),
    );

    if (selected == null) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final integrity = await ref
        .read(ledgerViewModelProvider.notifier)
        .demoTamperBlock(selected.index);
    if (integrity == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
          content: Text(
            'Block #${selected.index} altered. '
            '${integrity.problems.length} problem(s) detected.',
          ),
        ),
      );
  }
}

class _Chain extends StatelessWidget {
  final LedgerSnapshot snapshot;

  const _Chain({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final blocks = snapshot.blocks;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        ChainSummaryCard(stats: snapshot.stats),
        const SizedBox(height: 14),
        ChainIntegrityBanner(integrity: snapshot.integrity),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Anchored Events',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'newest first',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'The chain is empty.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          )
        else
          for (final block in blocks)
            BlockTile(
              block: block,
              isBroken: snapshot.integrity.problems.any(
                (problem) => problem.index == block.index,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlockDetailPage(block: block),
                ),
              ),
            ),
      ],
    );
  }
}
