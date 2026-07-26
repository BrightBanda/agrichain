import 'enums.dart';
import 'json_utils.dart';

/// Mirrors `FarmerProfileResponse` in `app/modules/auth/schemas.py`.
class FarmerProfile {
  final String id;
  final String fullName;
  final String nationalIdNumber;
  final Gender gender;
  final String district;
  final String traditionalAuthority;
  final String village;
  final String? profilePhotoUrl;
  final String? idFrontPhotoUrl;
  final String? idBackPhotoUrl;
  final int lendingScore;

  const FarmerProfile({
    required this.id,
    required this.fullName,
    required this.nationalIdNumber,
    required this.gender,
    required this.district,
    required this.traditionalAuthority,
    required this.village,
    required this.lendingScore,
    this.profilePhotoUrl,
    this.idFrontPhotoUrl,
    this.idBackPhotoUrl,
  });

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    return FarmerProfile(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      nationalIdNumber: json['national_id_number'] as String? ?? '',
      gender: Gender.fromJson(json['gender'] as String?),
      district: json['district'] as String? ?? '',
      traditionalAuthority: json['traditional_authority'] as String? ?? '',
      village: json['village'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      idFrontPhotoUrl: json['id_front_photo_url'] as String?,
      idBackPhotoUrl: json['id_back_photo_url'] as String?,
      lendingScore: asInt(json['lending_score'], fallback: 300),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'national_id_number': nationalIdNumber,
    'gender': gender.wireValue,
    'district': district,
    'traditional_authority': traditionalAuthority,
    'village': village,
    'profile_photo_url': profilePhotoUrl,
    'id_front_photo_url': idFrontPhotoUrl,
    'id_back_photo_url': idBackPhotoUrl,
    'lending_score': lendingScore,
  };

  /// First name only, for greetings.
  String get shortName => fullName.split(' ').first;
}
