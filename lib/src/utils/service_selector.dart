import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/enums.dart';

/// Icon for each listing category, shared by the selector and the marketplace.
IconData iconForProductType(ProductType type) => switch (type) {
  ProductType.cropsProduce => Icons.grass_outlined,
  ProductType.livestockAnimals => Icons.pets_outlined,
  ProductType.seeds => Icons.spa_outlined,
  ProductType.fertilizer => Icons.science_outlined,
  ProductType.pesticides => Icons.sanitizer_outlined,
  ProductType.equipment => Icons.agriculture_outlined,
  ProductType.irrigation => Icons.water_drop_outlined,
  ProductType.livestockFeed => Icons.grain_outlined,
};

/// Multi-select list of the input categories a service provider supplies.
///
/// The backend requires at least one and rejects anything outside the supply
/// categories, so only those are offered here.
class ServiceSelector extends StatelessWidget {
  final Set<ProductType> selected;
  final ValueChanged<ProductType> onToggle;
  final String? errorText;

  const ServiceSelector({
    super.key,
    required this.selected,
    required this.onToggle,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you supply?',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose every category you sell. You will only be able to list these '
          'on the marketplace.',
          style: TextStyle(
            fontSize: 11.5,
            color: AppColors.textMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        for (final service in ProductType.supplies)
          _ServiceRow(
            service: service,
            selected: selected.contains(service),
            onTap: () => onToggle(service),
          ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(fontSize: 11.5, color: Colors.red.shade700),
          ),
        ],
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final ProductType service;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceRow({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconForProductType(service),
                size: 17,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                service.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected
                      ? AppColors.textHeading
                      : AppColors.textMuted,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? AppColors.primary : AppColors.cardBorder,
            ),
          ],
        ),
      ),
    );
  }
}
