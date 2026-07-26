/// Lenient converters for values whose JSON representation varies.
library;

/// Pydantic serialises `Decimal` as a string in JSON mode, while a plain
/// `float` field arrives as a number. Accept both.
double asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? asDateTime(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}
