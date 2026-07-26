import 'json_utils.dart';

/// The score bands the app shows as a farmer "tier".
///
/// Derived from the score rather than stored, so it can never drift out of sync
/// with what the credit engine calculated.
enum FarmerTier {
  bronze('Bronze Farmer', 'Building your record'),
  silver('Silver Farmer', 'Good standing'),
  gold('Gold Farmer', 'Very good score'),
  platinum('Platinum Farmer', 'Excellent score');

  const FarmerTier(this.label, this.summary);

  final String label;
  final String summary;

  static FarmerTier forScore(int score) {
    if (score >= 700) return FarmerTier.platinum;
    if (score >= 550) return FarmerTier.gold;
    if (score >= 400) return FarmerTier.silver;
    return FarmerTier.bronze;
  }
}

/// Mirrors `LendingScoreResponse` in `app/modules/credit_engine/schemas.py`.
class LendingScore {
  /// The engine clamps scores to this range, so the ring is drawn against it.
  static const int minScore = 300;
  static const int maxScore = 850;

  /// Indicative borrowing headroom per point earned above the floor.
  static const int mwkPerPoint = 5000;

  final int score;
  final int previousScore;
  final int change;
  final Map<String, dynamic> factors;
  final List<String> reasons;

  const LendingScore({
    required this.score,
    required this.previousScore,
    required this.change,
    required this.factors,
    required this.reasons,
  });

  factory LendingScore.fromJson(Map<String, dynamic> json) {
    final factors = json['factors'];
    return LendingScore(
      score: asInt(json['score'], fallback: minScore),
      previousScore: asInt(json['previous_score'], fallback: minScore),
      change: asInt(json['change']),
      factors: factors is Map
          ? factors.cast<String, dynamic>()
          : const <String, dynamic>{},
      reasons: (json['reasons'] as List? ?? const [])
          .map((reason) => '$reason')
          .toList(),
    );
  }

  /// A fresh farmer sits at the floor with nothing recorded yet.
  factory LendingScore.initial() => const LendingScore(
    score: minScore,
    previousScore: minScore,
    change: 0,
    factors: {},
    reasons: [
      'Record a harvest and have it verified by your cooperative to start '
          'building your score.',
    ],
  );

  /// 0.0 – 1.0 across the engine's range, for the progress ring.
  double get progress =>
      ((score - minScore) / (maxScore - minScore)).clamp(0.0, 1.0);

  int get percent => (progress * 100).round();

  FarmerTier get tier => FarmerTier.forScore(score);

  /// Indicative headroom, not a commitment: the institution still decides.
  double get borrowCapacity =>
      ((score - minScore) * mwkPerPoint).clamp(0, double.infinity).toDouble();

  bool get improved => change > 0;
  bool get declined => change < 0;

  int _factor(String key) => asInt(factors[key]);

  int get verifiedHarvests => _factor('verified_harvests');
  int get produceListings => _factor('produce_listings');
  int get repaymentsMade => _factor('repayments_made');
  int get loansFullyRepaid => _factor('loans_fully_repaid');

  /// Short labels for the "Why high" line — only the factors actually earning
  /// points, so the explanation is never misleading.
  List<String> get strengths => [
    if (verifiedHarvests > 0) 'Verified Harvests',
    if (produceListings > 0) 'Crop Sales',
    if (loansFullyRepaid > 0) 'Fast Payback',
    if (repaymentsMade > 0 && loansFullyRepaid == 0) 'On-time Repayments',
  ];

  /// The reasons list minus the leading "your score changed by N" sentence,
  /// which the card already conveys visually.
  List<String> get detailedReasons =>
      reasons.where((reason) => !reason.startsWith('Your score')).toList();
}
