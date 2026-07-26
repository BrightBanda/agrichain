import 'enums.dart';
import 'json_utils.dart';

/// Mirrors `ProductResponse` in `app/modules/products/schemas.py`.
class Product {
  final String id;
  final String userId;
  final ProductType productType;
  final String productName;
  final UnitType unitType;
  final String district;
  final double pricePerUnit;
  final int quantityAvailable;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Seller details denormalised by the API so the grid needs one call.
  final String? sellerName;
  final bool sellerVerified;

  const Product({
    required this.id,
    required this.userId,
    required this.productType,
    required this.productName,
    required this.unitType,
    required this.district,
    required this.pricePerUnit,
    required this.quantityAvailable,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.sellerName,
    this.sellerVerified = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      productType: ProductType.fromJson(json['product_type'] as String?),
      productName: json['product_name'] as String? ?? '',
      unitType: UnitType.fromJson(json['unit_type'] as String?),
      district: json['district'] as String? ?? '',
      pricePerUnit: asDouble(json['price_per_unit']),
      quantityAvailable: asInt(json['quantity_available']),
      description: json['description'] as String?,
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
      sellerName: json['seller_name'] as String?,
      sellerVerified: json['seller_verified'] as bool? ?? false,
    );
  }

  /// Matches a free-text search across the fields a farmer would type.
  bool matchesQuery(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return productName.toLowerCase().contains(needle) ||
        district.toLowerCase().contains(needle) ||
        (sellerName ?? '').toLowerCase().contains(needle) ||
        (description ?? '').toLowerCase().contains(needle);
  }

  /// e.g. `MK 45,000.00 / 50 kg Bag`
  String get formattedPrice {
    final whole = pricePerUnit.floor();
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    final cents = ((pricePerUnit - whole) * 100).round().toString().padLeft(2, '0');
    return 'MK $buffer.$cents';
  }
}
