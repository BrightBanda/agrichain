import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/enums.dart';
import '../../data/models/product.dart';
import '../../utils/app_brand_header.dart';
import '../../utils/filter_bar.dart';
import '../../utils/product_grid_card.dart';
import '../../utils/segmented_toggle.dart';
import '../../utils/service_selector.dart' show iconForProductType;
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/product_list_view_model.dart';
import 'loans_page.dart' show initialsOf;
import 'product_form_page.dart';
import 'widgets/ledger_widgets.dart';

/// The produce and livestock marketplace (FR-09).
///
/// Search, category filtering and every figure on a card come from the live
/// listings. Ordering and messaging a seller have no endpoints yet, so those
/// buttons say so rather than failing silently.
class MarketplacePage extends ConsumerStatefulWidget {
  const MarketplacePage({super.key});

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  final _searchController = TextEditingController();
  String _query = '';
  int _categoryIndex = 0;

  /// Every listing category, derived from the enum so a new backend category
  /// appears here automatically. "All" is prepended.
  static final _filters = <ProductType?>[null, ...ProductType.values];
  static final _categories = [
    'All',
    ...ProductType.values.map((type) => type.shortLabel),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ProductType? get _categoryFilter => _filters[_categoryIndex];

  List<Product> _visible(List<Product> products) {
    final category = _categoryFilter;
    return products.where((product) {
      if (category != null && product.productType != category) return false;
      return product.matchesQuery(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(productListViewModelProvider);
    final filtersActive = _query.isNotEmpty || _categoryIndex != 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(productListViewModelProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              AppBrandHeader(
                roleLabel: user?.role.label ?? 'Farmer',
                subtitle: 'Marketplace',
                avatarInitials: initialsOf(user?.displayName),
              ),
              const SizedBox(height: 16),

              SegmentedToggle(
                selectedIndex: 0,
                options: const [
                  ToggleOption(
                    label: 'Marketplace',
                    icon: Icons.storefront_outlined,
                  ),
                  ToggleOption(
                    label: 'Sell Product',
                    icon: Icons.add_circle_outline,
                  ),
                ],
                onSelected: (index) {
                  if (index == 1) _openSellForm();
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _searchController,
                      hintText: 'Search crops, livestock, sellers…',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilterIconButton(
                    active: filtersActive,
                    onTap: !filtersActive
                        ? null
                        : () => setState(() {
                            _query = '';
                            _categoryIndex = 0;
                            _searchController.clear();
                          }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              CategoryChipRow(
                categories: _categories,
                selectedIndex: _categoryIndex,
                onSelected: (index) => setState(() => _categoryIndex = index),
              ),
              const SizedBox(height: 16),

              switch (state) {
                AsyncValue(hasError: true, :final error) => LedgerErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(productListViewModelProvider),
                ),
                AsyncValue(hasValue: true, :final value?) => _Grid(
                  products: _visible(value),
                  totalCount: value.length,
                  currentUserId: user?.id,
                  onUnavailable: _notAvailable,
                ),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSellForm() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProductFormPage()));
    if (mounted) {
      await ref.read(productListViewModelProvider.notifier).refresh();
    }
  }

  void _notAvailable(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text(
            '$feature is not built yet — there is no endpoint for it.',
          ),
        ),
      );
  }
}

class _Grid extends StatelessWidget {
  final List<Product> products;
  final int totalCount;
  final String? currentUserId;
  final void Function(String feature) onUnavailable;

  const _Grid({
    required this.products,
    required this.totalCount,
    required this.currentUserId,
    required this.onUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _EmptyGrid(filtered: totalCount > 0);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // A fixed extent rather than an aspect ratio, so card height does not
        // drift with device width.
        mainAxisExtent: 320,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        final isMine = product.userId == currentUserId;

        return ProductGridCard(
          productName: product.productName,
          sellerName: product.sellerName ?? 'Unknown seller',
          sellerVerified: product.sellerVerified,
          district: product.district,
          availabilityText:
              'Available: ${product.quantityAvailable} '
              '${product.unitType.label}',
          priceText: formatMwk(product.pricePerUnit),
          unitLabel: product.unitType.label,
          imagePlaceholderIcon: iconForProductType(product.productType),
          isMine: isMine,
          onBuy: isMine ? null : () => onUnavailable('Buying'),
          onContact: isMine ? null : () => onUnavailable('Messaging a seller'),
        );
      },
    );
  }
}

class _EmptyGrid extends StatelessWidget {
  /// True when listings exist but the search or category hides them all.
  final bool filtered;

  const _EmptyGrid({required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 38, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            filtered ? 'Nothing matches your search' : 'No products listed yet',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? 'Try another word, or clear the filters.'
                : 'Tap Sell Product to list your produce on AgriChain.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
