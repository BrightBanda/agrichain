/// Form validators shared by the auth and product forms.
class Validators {
  const Validators._();

  static String? required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? phone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Phone number is required';
    if (trimmed.length < 4) return 'Enter a valid phone number';
    return null;
  }

  /// The backend enforces `min_length=6`; fail fast on the client too.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? positiveNumber(String? value, String field) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$field is required';
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return '$field must be a number';
    if (parsed <= 0) return '$field must be greater than zero';
    return null;
  }

  static String? positiveInteger(String? value, String field) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$field is required';
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return '$field must be a whole number';
    if (parsed <= 0) return '$field must be greater than zero';
    return null;
  }
}
