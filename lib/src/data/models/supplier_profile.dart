import 'enums.dart';

/// A service provider's business details. Mirrors `SupplierProfileResponse`.
class SupplierProfile {
  final String id;
  final String businessName;
  final String? district;
  final String? description;

  /// The input categories this business registered to sell.
  final List<ProductType> services;

  const SupplierProfile({
    required this.id,
    required this.businessName,
    required this.services,
    this.district,
    this.description,
  });

  factory SupplierProfile.fromJson(Map<String, dynamic> json) {
    final raw = json['services'] as List? ?? const [];
    return SupplierProfile(
      id: json['id'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      district: json['district'] as String?,
      description: json['description'] as String?,
      // Unknown values are dropped rather than crashing an older app build
      // against a newer backend.
      services: raw
          .map((value) => ProductType.fromJson('$value'))
          .where((type) => type.isSupply)
          .toSet()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_name': businessName,
    'district': district,
    'description': description,
    'services': services.map((service) => service.wireValue).toList(),
  };

  bool mayList(ProductType type) => services.contains(type);

  String get servicesSummary =>
      services.isEmpty
      ? 'No services registered'
      : services.map((service) => service.shortLabel).join(' • ');
}
