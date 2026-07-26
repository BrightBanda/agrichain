import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'score_ring.dart';

/// The lending score card — the centrepiece of the farmer home screen.
///
/// Everything shown here is derived from the credit engine, including
/// [strengths], so the "why" can never contradict the number.
class MoneyScoreCard extends StatelessWidget {
  final int score;
  final double progress;
  final String tierSummary;
  final String borrowCapacityText;
  final List<String> strengths;
  final int change;
  final VoidCallback? onSeeDetails;

  const MoneyScoreCard({
    super.key,
    required this.score,
    required this.progress,
    required this.tierSummary,
    required this.borrowCapacityText,
    required this.strengths,
    this.change = 0,
    this.onSeeDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.scoreTop, AppColors.scoreBottom],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, size: 12, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Farmer Money Score',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'pts',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (change != 0) ...[
                          const SizedBox(width: 8),
                          _ChangeChip(change: change),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$tierSummary • You can borrow up to',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    Text(
                      borrowCapacityText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ScoreRing(progress: progress, size: 62),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  strengths.isEmpty
                      ? 'Record and verify farm work to build your score'
                      : 'Why: ${strengths.join(' • ')}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
              if (onSeeDetails != null)
                InkWell(
                  onTap: onSeeDetails,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          'See Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  final int change;

  const _ChangeChip({required this.change});

  @override
  Widget build(BuildContext context) {
    final rose = change > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rose ? Colors.white24 : AppColors.danger,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rose ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            '${change.abs()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
