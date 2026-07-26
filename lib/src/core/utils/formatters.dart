/// Number and date formatting shared across the app.
///
/// Hand-rolled rather than via `intl` so the app keeps its current dependency
/// set; swap these for `NumberFormat`/`DateFormat` if localisation lands.
library;

/// `185000` -> `185,000`
String groupDigits(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// `185000` -> `MWK 185,000`, or `MWK 185,000.50` when [decimals] is true.
String formatMwk(num amount, {bool decimals = false}) {
  final whole = amount.abs().floor();
  final grouped = groupDigits(amount < 0 ? -whole : whole);
  if (!decimals) return 'MWK $grouped';

  final cents = ((amount.abs() - whole) * 100).round().toString().padLeft(2, '0');
  return 'MWK $grouped.$cents';
}

/// `2500000` -> `MWK 2.5M`, for tight spaces like the score card.
String formatMwkCompact(num amount) {
  if (amount >= 1000000) {
    final millions = amount / 1000000;
    final text = millions >= 10
        ? millions.round().toString()
        : millions.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return 'MWK ${text}M';
  }
  if (amount >= 1000) {
    final thousands = amount / 1000;
    final text = thousands >= 10
        ? thousands.round().toString()
        : thousands.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return 'MWK ${text}K';
  }
  return formatMwk(amount);
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `2027-04-26` -> `Apr 26`
String formatShortDate(DateTime date) => '${_months[date.month - 1]} ${date.day}';

/// `2027-04-26` -> `26 Apr 2027`
String formatFullDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// `2026-07-24` -> `2 days ago`
String formatRelativeDate(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  if (days < 30) {
    final weeks = days ~/ 7;
    return weeks == 1 ? 'Last week' : '$weeks weeks ago';
  }
  return formatFullDate(date);
}

/// Drops a trailing `.00` so quantities read as `120` not `120.00`.
String formatQuantity(num value) {
  if (value == value.roundToDouble()) return groupDigits(value.round());
  return value.toStringAsFixed(2);
}
