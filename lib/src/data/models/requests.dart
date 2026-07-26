import 'enums.dart';

/// Mirrors `LoginRequest`.
class LoginRequest {
  final String phoneNumber;
  final String password;

  const LoginRequest({required this.phoneNumber, required this.password});

  Map<String, dynamic> toJson() => {
    'phone_number': phoneNumber,
    'password': password,
  };
}

/// Mirrors `FarmerRegisterRequest`.
///
/// The backend re-checks that the passwords match, so [confirmPassword] is
/// part of the payload rather than a client-only field.
class FarmerRegisterRequest {
  final String fullName;
  final String nationalIdNumber;
  final Gender gender;
  final String district;
  final String traditionalAuthority;
  final String village;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String? profilePhotoUrl;
  final String? idFrontPhotoUrl;
  final String? idBackPhotoUrl;

  const FarmerRegisterRequest({
    required this.fullName,
    required this.nationalIdNumber,
    required this.gender,
    required this.district,
    required this.traditionalAuthority,
    required this.village,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    this.profilePhotoUrl,
    this.idFrontPhotoUrl,
    this.idBackPhotoUrl,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'national_id_number': nationalIdNumber,
    'gender': gender.wireValue,
    'district': district,
    'traditional_authority': traditionalAuthority,
    'village': village,
    'phone_number': phoneNumber,
    'password': password,
    'confirm_password': confirmPassword,
    if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
    if (idFrontPhotoUrl != null) 'id_front_photo_url': idFrontPhotoUrl,
    if (idBackPhotoUrl != null) 'id_back_photo_url': idBackPhotoUrl,
  };
}

/// Mirrors `OrganizationRegisterRequest` for the service-provider case.
///
/// [services] is required by the backend for SUPPLIER accounts and must contain
/// only supply categories.
class ServiceProviderRegisterRequest {
  final String businessName;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final List<ProductType> services;
  final String? district;
  final String? description;
  final String? email;

  const ServiceProviderRegisterRequest({
    required this.businessName,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.services,
    this.district,
    this.description,
    this.email,
  });

  Map<String, dynamic> toJson() => {
    'display_name': businessName,
    'role': UserRole.supplier.wireValue,
    'phone_number': phoneNumber,
    'password': password,
    'confirm_password': confirmPassword,
    'services': services.map((service) => service.wireValue).toList(),
    if (district != null && district!.isNotEmpty) 'district': district,
    if (description != null && description!.isNotEmpty)
      'description': description,
    if (email != null && email!.isNotEmpty) 'email': email,
  };
}

/// Mirrors `ProductCreateRequest`.
class ProductCreateRequest {
  final ProductType productType;
  final String productName;
  final UnitType unitType;
  final String district;
  final double pricePerUnit;
  final int quantityAvailable;
  final String? description;

  const ProductCreateRequest({
    required this.productType,
    required this.productName,
    required this.unitType,
    required this.district,
    required this.pricePerUnit,
    required this.quantityAvailable,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'product_type': productType.wireValue,
    'product_name': productName,
    'unit_type': unitType.wireValue,
    'district': district,
    'price_per_unit': pricePerUnit,
    'quantity_available': quantityAvailable,
    if (description != null && description!.isNotEmpty)
      'description': description,
  };
}
