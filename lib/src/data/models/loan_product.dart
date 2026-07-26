import 'json_utils.dart';

/// Mirrors `LoanType` in `app/modules/loans/models.py`.
enum LoanType {
  agricultural('AGRICULTURAL', 'Agricultural'),
  microloan('MICROLOAN', 'Microloan'),
  inputFinancing('INPUT_FINANCING', 'Input Financing'),
  equipmentFinancing('EQUIPMENT_FINANCING', 'Equipment'),
  seasonal('SEASONAL', 'Seasonal');

  const LoanType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static LoanType fromJson(String? value) => values.firstWhere(
    (type) => type.wireValue == value,
    orElse: () => LoanType.agricultural,
  );
}

/// A loan offer published by an institution. Mirrors `LoanProductResponse`.
class LoanProduct {
  final String id;
  final String institutionUserId;
  final String name;
  final LoanType loanType;
  final double maxAmount;
  final double interestRate;
  final int repaymentPeriodMonths;
  final int minLendingScore;
  final String? description;
  final bool isActive;
  final String? institutionName;
  final double? monthlyFeePercent;

  const LoanProduct({
    required this.id,
    required this.institutionUserId,
    required this.name,
    required this.loanType,
    required this.maxAmount,
    required this.interestRate,
    required this.repaymentPeriodMonths,
    required this.minLendingScore,
    required this.isActive,
    this.description,
    this.institutionName,
    this.monthlyFeePercent,
  });

  factory LoanProduct.fromJson(Map<String, dynamic> json) {
    return LoanProduct(
      id: json['id'] as String? ?? '',
      institutionUserId: json['institution_user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      loanType: LoanType.fromJson(json['loan_type'] as String?),
      maxAmount: asDouble(json['max_amount']),
      interestRate: asDouble(json['interest_rate']),
      repaymentPeriodMonths: asInt(json['repayment_period_months']),
      minLendingScore: asInt(json['min_lending_score'], fallback: 300),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      institutionName: json['institution_name'] as String?,
      monthlyFeePercent: json['monthly_fee_percent'] == null
          ? null
          : asDouble(json['monthly_fee_percent']),
    );
  }

  /// Interest per month, computed locally when the API did not supply it.
  double get monthlyFee {
    if (monthlyFeePercent != null) return monthlyFeePercent!;
    if (repaymentPeriodMonths <= 0) return 0;
    return interestRate / repaymentPeriodMonths;
  }

  bool isEligible(int score) => score >= minLendingScore;

  /// How much of this product's score requirement the farmer meets.
  ///
  /// Deliberately defined as `score / required`, capped at 100 — so a farmer
  /// just short of the threshold sees "96%" and understands they nearly
  /// qualify. It is not a probability of approval; the institution still
  /// decides.
  int matchPercent(int score) {
    if (minLendingScore <= 0) return 100;
    return ((score / minLendingScore) * 100).clamp(0, 100).round();
  }

  /// Points still needed to become eligible, or zero when already eligible.
  int pointsShort(int score) =>
      score >= minLendingScore ? 0 : minLendingScore - score;

  /// Factual terms drawn from the record itself.
  ///
  /// Deliberately not the marketing copy from the mockup ("no land papers
  /// needed"): those are lending promises, and inventing them would misrepresent
  /// the institution's terms. These restate real fields instead.
  List<String> get terms => [
    'Pay back over $repaymentPeriodMonths months',
    'Borrow up to the product maximum in one application',
    'Requires a lending score of $minLendingScore or more',
  ];
}
