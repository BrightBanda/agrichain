import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/lending_score.dart';
import '../../utils/score_ring.dart';

/// The "See Details" screen behind the score card (FR-14).
///
/// Shows every reason the engine gave, plus the point contribution of each
/// factor, so a farmer can see exactly what to do to improve.
class ScoreDetailsPage extends StatelessWidget {
  final LendingScore score;

  const ScoreDetailsPage({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final points = score.factors['points'];
    final breakdown = points is Map ? points.cast<String, dynamic>() : const {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        title: const Text(
          'Farmer Money Score',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.scoreTop, AppColors.scoreBottom],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${score.score} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          score.tier.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Indicative borrowing headroom\n'
                          '${formatMwk(score.borrowCapacity)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScoreRing(progress: score.progress, size: 74),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Scored from ${LendingScore.minScore} to '
                '${LendingScore.maxScore}. Headroom is indicative only — each '
                'institution makes its own lending decision.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Why your score is what it is',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  for (final reason in score.reasons)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            reason.contains('decreased')
                                ? Icons.arrow_downward
                                : reason.startsWith('Record')
                                      ? Icons.lightbulb_outline
                                      : Icons.check_circle_outline,
                            size: 16,
                            color: reason.contains('decreased')
                                ? AppColors.danger
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (breakdown.isNotEmpty) ...[
              const Text(
                'Points by factor',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _FactorRow(
                      label: 'Base score',
                      value: '${LendingScore.minScore}',
                    ),
                    for (final entry in breakdown.entries)
                      _FactorRow(
                        label: _label(entry.key),
                        value: _signed(entry.value),
                        muted: '${entry.value}' == '0',
                      ),
                    const Divider(height: 20),
                    _FactorRow(
                      label: 'Total',
                      value: '${score.score}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _label(String key) => switch (key) {
    'verified_harvests' => 'Verified harvests',
    'produce_listings' => 'Produce listings',
    'repayments_made' => 'Repayments made',
    'loans_fully_repaid' => 'Loans fully repaid',
    'loans_rejected' => 'Declined applications',
    _ => key.replaceAll('_', ' '),
  };

  static String _signed(dynamic value) {
    final number = value is num ? value : num.tryParse('$value') ?? 0;
    if (number > 0) return '+${number.toInt()}';
    return '${number.toInt()}';
  }
}

class _FactorRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool muted;

  const _FactorRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textMuted : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: muted ? AppColors.textMuted : AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}
