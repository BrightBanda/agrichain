import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

/// Loads the public marketplace listing from `GET /products`.
class ProductListViewModel extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() {
    return ref.read(productRepositoryProvider).fetchProducts();
  }

  /// Pull-to-refresh. Keeps the current list visible while refetching.
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).fetchProducts(),
    );
  }
}

final productListViewModelProvider =
    AsyncNotifierProvider<ProductListViewModel, List<Product>>(
      ProductListViewModel.new,
    );
