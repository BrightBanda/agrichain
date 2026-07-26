import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A marketplace listing tile, sized for a two-column grid.
///
/// AgriChain has no image storage, so [imagePlaceholderIcon] draws a tinted
/// panel instead of a photo — obviously not a picture, rather than a stock image
/// pretending to be the seller's produce.
///
/// The mockup shows a star rating in the seller row. There is no ratings model,
/// and inventing a trust score would misrepresent a seller, so that slot carries
/// the seller's real KYC verification state instead.
class ProductGridCard extends StatelessWidget {
  final String productName;
  final String sellerName;
  final bool sellerVerified;
  final String district;
  final String availabilityText;
  final String priceText;
  final String unitLabel;
  final IconData imagePlaceholderIcon;
  final bool isMine;
  final VoidCallback? onBuy;
  final VoidCallback? onContact;

  const ProductGridCard({
    super.key,
    required this.productName,
    required this.sellerName,
    required this.sellerVerified,
    required this.district,
    required this.availabilityText,
    required this.priceText,
    required this.unitLabel,
    required this.imagePlaceholderIcon,
    this.isMine = false,
    this.onBuy,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImagePanel(
            icon: imagePlaceholderIcon,
            district: district,
            verified: sellerVerified,
          ),
          // Expanded + Flexible below: the grid gives every cell the same
          // height, so the text block must yield space rather than overflow it
          // when a long product name wraps or the text scale is large.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Icon(
                      sellerVerified
                          ? Icons.check_circle
                          : Icons.person_outline,
                      size: 12,
                      color: sellerVerified
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (isMine)
                      const Text(
                        'You',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Flexible(
                  child: Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeading,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    availabilityText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                // Keeps the price and actions pinned to the bottom of the cell.
                const Spacer(),
                Text(
                  priceText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '/ $unitLabel',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onBuy,
                    icon: const Icon(Icons.shopping_bag_outlined, size: 13),
                    label: const Text(
                      'Buy',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.cardBorder,
                      disabledForegroundColor: AppColors.textMuted,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.chat_bubble_outline, size: 12),
                    label: const Text(
                      'Contact Seller',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  final IconData icon;
  final String district;
  final bool verified;

  const _ImagePanel({
    required this.icon,
    required this.district,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 92,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.cardTint, AppColors.accentSoft],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 34,
              color: AppColors.primaryMuted.withValues(alpha: 0.55),
            ),
          ),
        ),
        if (verified)
          Positioned(
            top: 7,
            left: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, size: 10, color: AppColors.primary),
                  SizedBox(width: 3),
                  Text(
                    'Verified Seller',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 7,
          right: 7,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 9,
                  color: Colors.white,
                ),
                const SizedBox(width: 2),
                Text(
                  district,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
