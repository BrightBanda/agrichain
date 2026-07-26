/// Dart mirrors of the backend enums in `app/modules/*/models.py`.
///
/// [wireValue] is what travels over the API; [label] is what a user reads.
library;

enum UserRole {
  farmer('FARMER', 'Farmer'),
  financialInstitution('FINANCIAL_INSTITUTION', 'Financial Institution'),
  supplier('SUPPLIER', 'Supplier'),
  produceBuyer('PRODUCE_BUYER', 'Produce Buyer'),
  cooperative('COOPERATIVE', 'Cooperative'),
  admin('ADMIN', 'Administrator');

  const UserRole(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static UserRole fromJson(String? value) => values.firstWhere(
    (role) => role.wireValue == value,
    orElse: () => UserRole.farmer,
  );
}

enum Gender {
  male('MALE', 'Male'),
  female('FEMALE', 'Female'),
  other('OTHER', 'Other');

  const Gender(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static Gender fromJson(String? value) => values.firstWhere(
    (gender) => gender.wireValue == value,
    orElse: () => Gender.other,
  );
}

enum ProductType {
  cropsProduce('CROPS_PRODUCE', 'Crops & Produce'),
  livestockAnimals('LIVESTOCK_ANIMALS', 'Livestock & Animals');

  const ProductType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static ProductType fromJson(String? value) => values.firstWhere(
    (type) => type.wireValue == value,
    orElse: () => ProductType.cropsProduce,
  );
}

enum UnitType {
  bag50kg('BAG_50KG', '50 kg Bag'),
  bag25kg('BAG_25KG', '25 kg Bag'),
  bag10kg('BAG_10KG', '10 kg Bag'),
  kilogram('KILOGRAM', 'Kilogram'),
  piece('PIECE', 'Piece'),
  liter('LITER', 'Liter'),
  bunch('BUNCH', 'Bunch'),
  crate('CRATE', 'Crate');

  const UnitType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static UnitType fromJson(String? value) => values.firstWhere(
    (unit) => unit.wireValue == value,
    orElse: () => UnitType.kilogram,
  );
}
