import 'json_utils.dart';

/// One recalculation of the lending score. Mirrors `ScoreHistoryEntry`.
class ScoreHistoryEntry {
  final String id;
  final int previousScore;
  final int score;
  final Map<String, dynamic> factors;
  final List<String> reasons;
  final DateTime? calculatedAt;

  const ScoreHistoryEntry({
    required this.id,
    required this.previousScore,
    required this.score,
    required this.factors,
    required this.reasons,
    this.calculatedAt,
  });

  factory ScoreHistoryEntry.fromJson(Map<String, dynamic> json) {
    final factors = json['factors'];
    return ScoreHistoryEntry(
      id: json['id'] as String? ?? '',
      previousScore: asInt(json['previous_score'], fallback: 300),
      score: asInt(json['score'], fallback: 300),
      factors: factors is Map
          ? factors.cast<String, dynamic>()
          : const <String, dynamic>{},
      reasons: (json['reasons'] as List? ?? const [])
          .map((reason) => '$reason')
          .toList(),
      calculatedAt: asDateTime(json['calculated_at']),
    );
  }

  int get change => score - previousScore;
  bool get improved => change > 0;
  bool get declined => change < 0;

  /// The most informative reason, skipping the "your score changed by N" line
  /// that the delta already conveys.
  String? get headlineReason {
    for (final reason in reasons) {
      if (!reason.startsWith('Your score')) return reason;
    }
    return reasons.isEmpty ? null : reasons.first;
  }
}
