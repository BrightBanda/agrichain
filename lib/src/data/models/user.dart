import 'enums.dart';
import 'farmer_profile.dart';
import 'json_utils.dart';

/// Mirrors `UserRegisterResponse` in `app/modules/auth/schemas.py`.
class User {
  final String id;
  final String phoneNumber;
  final UserRole role;
  final bool isVerified;
  final DateTime? createdAt;
  final FarmerProfile? farmerProfile;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.role,
    required this.isVerified,
    this.createdAt,
    this.farmerProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final profile = json['farmer_profile'];
    return User(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      role: UserRole.fromJson(json['role'] as String?),
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: asDateTime(json['created_at']),
      farmerProfile: profile is Map<String, dynamic>
          ? FarmerProfile.fromJson(profile)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone_number': phoneNumber,
    'role': role.wireValue,
    'is_verified': isVerified,
    'created_at': createdAt?.toIso8601String(),
    'farmer_profile': farmerProfile?.toJson(),
  };

  /// Falls back to the phone number for roles that have no profile yet.
  String get displayName => farmerProfile?.fullName ?? phoneNumber;
}
