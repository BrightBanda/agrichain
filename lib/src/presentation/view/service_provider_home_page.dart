import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import '../../utils/pill_badge.dart';
import '../../utils/section_header.dart';
import '../../utils/service_selector.dart';
import '../../utils/stat_tile.dart';
import '../../utils/responsive.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/product_list_view_model.dart';
import 'marketplace_page.dart';
import 'product_form_page.dart';
import 'widgets/app_header.dart';
import 'widgets/ledger_widgets.dart';

/// Home for a service provider (FR-11).
///
/// Deliberately narrow: a supplier lists and manages inputs. The farmer-only
/// features — lending score, loans, harvests — do not apply to this role, so
/// they are absent rather than shown disabled.
class ServiceProviderHomePage extends ConsumerWidget {
  const ServiceProviderHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = user?.supplierProfile;
    final state = ref.watch(productListViewModelProvider);

    final mine = (state.value ?? const <Product>[])
        .where((product) => product.userId == user?.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('List Product'),
        onPressed: () => _openForm(context, ref),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(productListViewModelProvider.notifier).refresh(),
          child: PageWidth(
            child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              const AppHeader(
                subtitle: 'My Shop',
                roleLabel: 'Service Provider',
              ),
              const SizedBox(height: 16),

              _BusinessCard(
                businessName: profile?.businessName ?? user?.displayName ?? '',
                district: profile?.district,
                servicesSummary: profile?.servicesSummary ?? '',
                isVerified: user?.isVerified ?? false,
              ),
              const SizedBox(height: 14),

              StatTileRow(
                tiles: [
                  StatTile(
                    label: 'My Listings',
                    value: '${mine.length}',
                    caption: mine.isEmpty ? 'Nothing listed' : 'On marketplace',
                  ),
                  StatTile(
                    label: 'Categories',
                    value: '${profile?.services.length ?? 0}',
                    caption: 'Registered services',
                  ),
                  StatTile(
                    label: 'Stock Units',
                    value: '${mine.fold<int>(0, (sum, p) => sum + p.quantityAvailable)}',
                    caption: 'Across all listings',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SectionHeader(
                title: 'What You Supply',
                actionLabel: 'Browse Market',
                actionIcon: Icons.storefront_outlined,
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MarketplacePage()),
                ),
              ),
              const SizedBox(height: 10),
              if (profile == null || profile.services.isEmpty)
                const _NoServices()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final service in profile.services)
                      PillBadge(
                        text: service.label,
                        background: AppColors.accentSoft,
                        foreground: AppColors.primary,
                        icon: iconForProductType(service),
                      ),
                  ],
                ),
              const SizedBox(height: 20),

              const SectionHeader(title: 'My Listings'),
              const SizedBox(height: 10),
              switch (state) {
                AsyncValue(hasError: true, :final error) => LedgerErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(productListViewModelProvider),
                ),
                AsyncValue(hasValue: true) => mine.isEmpty
                    ? _NoListings(onList: () => _openForm(context, ref))
                    : Column(
                        children: [
                          for (final product in mine)
                            _ListingRow(product: product),
                        ],
                      ),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              },
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProductFormPage()));
    await ref.read(productListViewModelProvider.notifier).refresh();
  }

}

class _BusinessCard extends StatelessWidget {
  final String businessName;
  final String? district;
  final String servicesSummary;
  final bool isVerified;

  const _BusinessCard({
    required this.businessName,
    required this.servicesSummary,
    required this.isVerified,
    this.district,
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
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified
                            ? Icons.verified_outlined
                            : Icons.schedule,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isVerified
                              ? 'Verified Supplier'
                              : 'Verification Pending',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            businessName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (district != null && district!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              district!,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            servicesSummary,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  final Product product;

  const _ListingRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.cardTint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              iconForProductType(product.productType),
              size: 18,
              color: AppColors.primaryMuted,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.quantityAvailable} ${product.unitType.label} • '
                  '${product.district}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMwk(product.pricePerUnit),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '/ ${product.unitType.label}',
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoServices extends StatelessWidget {
  const _NoServices();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: const Text(
        'No services registered, so you cannot list anything yet. Editing your '
        'registered categories is not built yet.',
        style: TextStyle(fontSize: 11.5, height: 1.4, color: Colors.black87),
      ),
    );
  }
}

class _NoListings extends StatelessWidget {
  final VoidCallback onList;

  const _NoListings({required this.onList});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 34, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'Nothing listed yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'List your first product so farmers can find it on the marketplace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onList,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('List Product'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
