import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/models/requests.dart';
import '../../data/repositories/product_repository.dart';
import 'product_list_view_model.dart';

/// Submission state for the "list a product" form.
///
/// Holds the created [Product] on success, null before the first submission.
class ProductFormViewModel extends AsyncNotifier<Product?> {
  @override
  Product? build() => null;

  Future<bool> submit(ProductCreateRequest request) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard<Product?>(
      () => ref.read(productRepositoryProvider).createProduct(request),
    );
    state = result;

    if (!result.hasError) {
      // The new listing belongs in the marketplace immediately.
      await ref.read(productListViewModelProvider.notifier).refresh();
      return true;
    }
    return false;
  }

  void reset() => state = const AsyncValue.data(null);
}

final productFormViewModelProvider =
    AsyncNotifierProvider<ProductFormViewModel, Product?>(
      ProductFormViewModel.new,
    );
