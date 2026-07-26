import 'enums.dart';
import 'json_utils.dart';

/// Mirrors `VerificationStatus` in `app/modules/activities/models.py`.
enum HarvestStatus {
  pending('PENDING', 'Awaiting Verification'),
  verified('VERIFIED', 'Verified'),
  rejected('REJECTED', 'Rejected');

  const HarvestStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static HarvestStatus fromJson(String? value) => values.firstWhere(
    (status) => status.wireValue == value,
    orElse: () => HarvestStatus.pending,
  );
}

/// Mirrors `HarvestResponse`.
class Harvest {
  final String id;
  final String userId;
  final String cropName;
  final double quantity;
  final UnitType unitType;
  final DateTime? harvestDate;
  final String season;
  final String district;
  final HarvestStatus status;
  final DateTime? verifiedAt;
  final DateTime? createdAt;

  const Harvest({
    required this.id,
    required this.userId,
    required this.cropName,
    required this.quantity,
    required this.unitType,
    required this.season,
    required this.district,
    required this.status,
    this.harvestDate,
    this.verifiedAt,
    this.createdAt,
  });

  factory Harvest.fromJson(Map<String, dynamic> json) {
    return Harvest(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? '',
      quantity: asDouble(json['quantity']),
      unitType: UnitType.fromJson(json['unit_type'] as String?),
      harvestDate: asDateTime(json['harvest_date']),
      season: json['season'] as String? ?? '',
      district: json['district'] as String? ?? '',
      status: HarvestStatus.fromJson(json['status'] as String?),
      verifiedAt: asDateTime(json['verified_at']),
      createdAt: asDateTime(json['created_at']),
    );
  }

  bool get isVerified => status == HarvestStatus.verified;
}
