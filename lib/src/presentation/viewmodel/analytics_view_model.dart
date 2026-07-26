import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/score_history.dart';
import '../../data/repositories/farm_repository.dart';

/// Score history for the Lending Score tab (FR-13).
///
/// Separate from the dashboard so opening Analytics does not refetch everything
/// the home screen already holds.
final scoreHistoryProvider = FutureProvider<List<ScoreHistoryEntry>>(
  (ref) => ref.read(farmRepositoryProvider).fetchScoreHistory(),
);
