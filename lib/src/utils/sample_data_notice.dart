import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Marks a section whose figures are illustrative rather than measured.
///
/// AgriChain records harvests, listings, loans and repayments, but has no sales
/// or purchase ledger yet, so income and spending cannot be computed. Rather
/// than present invented totals as real reporting, the sections that depend on
/// them carry this notice.
class SampleDataNotice extends StatelessWidget {
  final String explanation;

  const SampleDataNotice({super.key, required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 15,
            color: AppColors.warning,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Sample figures. ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  TextSpan(text: explanation),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small inline "SAMPLE" tag for a single value.
class SampleTag extends StatelessWidget {
  const SampleTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'SAMPLE',
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
