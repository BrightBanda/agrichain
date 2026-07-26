import 'enums.dart';
import 'farmer_profile.dart';
import 'json_utils.dart';
import 'supplier_profile.dart';

/// Mirrors `UserRegisterResponse` in `app/modules/auth/schemas.py`.
class User {
  final String id;
  final String phoneNumber;

  /// Organisation name. Null for farmers, who carry a name on their profile.
  final String? organizationName;
  final UserRole role;
  final bool isVerified;
  final DateTime? createdAt;
  final FarmerProfile? farmerProfile;
  final SupplierProfile? supplierProfile;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.role,
    required this.isVerified,
    this.organizationName,
    this.createdAt,
    this.farmerProfile,
    this.supplierProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final profile = json['farmer_profile'];
    final supplier = json['supplier_profile'];
    return User(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      organizationName: json['display_name'] as String?,
      role: UserRole.fromJson(json['role'] as String?),
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: asDateTime(json['created_at']),
      farmerProfile: profile is Map<String, dynamic>
          ? FarmerProfile.fromJson(profile)
          : null,
      supplierProfile: supplier is Map<String, dynamic>
          ? SupplierProfile.fromJson(supplier)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone_number': phoneNumber,
    'display_name': organizationName,
    'role': role.wireValue,
    'is_verified': isVerified,
    'created_at': createdAt?.toIso8601String(),
    'farmer_profile': farmerProfile?.toJson(),
    'supplier_profile': supplierProfile?.toJson(),
  };

  /// A farmer's own name, an organisation's name, or the phone number.
  String get displayName =>
      farmerProfile?.fullName ?? organizationName ?? phoneNumber;

  bool get isFarmer => role == UserRole.farmer;
  bool get isServiceProvider => role == UserRole.supplier;

  /// What this account may list on the marketplace.
  ///
  /// A farmer sells produce and livestock; a service provider sells only the
  /// inputs it registered. The backend enforces the same rule, so this is for
  /// showing the right choices, not for security.
  List<ProductType> get listableProductTypes {
    if (isFarmer) return ProductType.farmProduce;
    if (isServiceProvider) return supplierProfile?.services ?? const [];
    return const [];
  }

  bool get canListProducts => listableProductTypes.isNotEmpty;
}
