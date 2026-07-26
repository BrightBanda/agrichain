import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/product.dart';
import '../models/requests.dart';

/// Talks to `/products`.
class ProductRepository {
  final Dio _dio;

  const ProductRepository(this._dio);

  /// `GET /products` — public listing.
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.products,
        options: Options(extra: publicRequest),
      );
      final items = response.data?['products'] as List? ?? const [];
      return items
          .whereType<Map>()
          .map((json) => Product.fromJson(json.cast<String, dynamic>()))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `POST /products` — requires a bearer token.
  Future<Product> createProduct(ProductCreateRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.products,
        data: request.toJson(),
      );
      return Product.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(dioProvider)),
);
