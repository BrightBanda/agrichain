import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ledger.dart';
import '../../data/repositories/blockchain_repository.dart';

/// Everything the explorer shows in one load: the blocks, the counters, and the
/// current integrity verdict.
class LedgerSnapshot {
  final List<LedgerBlock> blocks;
  final ChainStats stats;
  final ChainIntegrity integrity;

  const LedgerSnapshot({
    required this.blocks,
    required this.stats,
    required this.integrity,
  });

  LedgerSnapshot copyWith({
    List<LedgerBlock>? blocks,
    ChainStats? stats,
    ChainIntegrity? integrity,
  }) {
    return LedgerSnapshot(
      blocks: blocks ?? this.blocks,
      stats: stats ?? this.stats,
      integrity: integrity ?? this.integrity,
    );
  }
}

/// View model for the blockchain explorer.
class LedgerViewModel extends AsyncNotifier<LedgerSnapshot> {
  BlockchainRepository get _repository => ref.read(blockchainRepositoryProvider);

  @override
  Future<LedgerSnapshot> build() => _load();

  Future<LedgerSnapshot> _load() async {
    // Independent reads, so fetch them together rather than in sequence.
    final results = await Future.wait([
      _repository.fetchChain(limit: 100),
      _repository.fetchStats(),
      _repository.verifyChain(),
    ]);

    return LedgerSnapshot(
      blocks: results[0] as List<LedgerBlock>,
      stats: results[1] as ChainStats,
      integrity: results[2] as ChainIntegrity,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// Re-run only the integrity check, keeping the block list on screen.
  Future<ChainIntegrity?> verifyChain() async {
    final current = state.value;
    if (current == null) {
      await refresh();
      return state.value?.integrity;
    }

    final result = await AsyncValue.guard(() => _repository.verifyChain());
    if (result.hasError) {
      state = AsyncValue.error(result.error!, result.stackTrace!);
      return null;
    }

    final integrity = result.value!;
    state = AsyncValue.data(current.copyWith(integrity: integrity));
    return integrity;
  }

  /// Corrupt a block, then reload so the explorer shows the damage.
  Future<ChainIntegrity?> demoTamperBlock(int index) async {
    final result = await AsyncValue.guard(
      () => _repository.demoTamperBlock(index),
    );
    if (result.hasError) {
      state = AsyncValue.error(result.error!, result.stackTrace!);
      return null;
    }
    await refresh();
    return result.value;
  }
}

final ledgerViewModelProvider =
    AsyncNotifierProvider<LedgerViewModel, LedgerSnapshot>(
      LedgerViewModel.new,
    );

/// Verifies one anchored record against the chain, keyed by the block showing it.
final recordVerificationProvider = FutureProvider.family
    .autoDispose<RecordVerification, ({LedgerEntityType type, String id})>((
      ref,
      target,
    ) {
      return ref
          .read(blockchainRepositoryProvider)
          .verifyRecord(entityType: target.type, entityId: target.id);
    });
