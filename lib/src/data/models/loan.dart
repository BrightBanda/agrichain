import 'json_utils.dart';

/// Mirrors `LoanStatus` in `app/modules/loans/models.py`.
enum LoanStatus {
  pending('PENDING', 'Awaiting Decision'),
  rejected('REJECTED', 'Declined'),
  active('ACTIVE', 'Active'),
  repaid('REPAID', 'Fully Repaid');

  const LoanStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static LoanStatus fromJson(String? value) => values.firstWhere(
    (status) => status.wireValue == value,
    orElse: () => LoanStatus.pending,
  );
}

/// Mirrors `LoanResponse`.
class Loan {
  final String id;
  final String loanProductId;
  final double amountRequested;
  final double? amountApproved;
  final double interestRate;
  final double? totalPayable;
  final double amountRepaid;
  final double outstandingBalance;
  final LoanStatus status;
  final int lendingScoreAtApplication;
  final String? decisionNote;
  final DateTime? appliedAt;
  final DateTime? decidedAt;
  final int? repaymentPeriodMonths;
  final DateTime? dueDate;

  /// Joined by the API so a reviewing institution sees a person, not a UUID.
  final String? farmerName;
  final String? farmerPhone;

  const Loan({
    required this.id,
    required this.loanProductId,
    required this.amountRequested,
    required this.interestRate,
    required this.amountRepaid,
    required this.outstandingBalance,
    required this.status,
    required this.lendingScoreAtApplication,
    this.amountApproved,
    this.totalPayable,
    this.decisionNote,
    this.appliedAt,
    this.decidedAt,
    this.repaymentPeriodMonths,
    this.dueDate,
    this.farmerName,
    this.farmerPhone,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String? ?? '',
      loanProductId: json['loan_product_id'] as String? ?? '',
      amountRequested: asDouble(json['amount_requested']),
      amountApproved: json['amount_approved'] == null
          ? null
          : asDouble(json['amount_approved']),
      interestRate: asDouble(json['interest_rate']),
      totalPayable: json['total_payable'] == null
          ? null
          : asDouble(json['total_payable']),
      amountRepaid: asDouble(json['amount_repaid']),
      outstandingBalance: asDouble(json['outstanding_balance']),
      status: LoanStatus.fromJson(json['status'] as String?),
      lendingScoreAtApplication: asInt(
        json['lending_score_at_application'],
        fallback: 300,
      ),
      decisionNote: json['decision_note'] as String?,
      appliedAt: asDateTime(json['applied_at']),
      decidedAt: asDateTime(json['decided_at']),
      repaymentPeriodMonths: json['repayment_period_months'] == null
          ? null
          : asInt(json['repayment_period_months']),
      dueDate: asDateTime(json['due_date']),
      farmerName: json['farmer_name'] as String?,
      farmerPhone: json['farmer_phone'] as String?,
    );
  }

  bool get isActive => status == LoanStatus.active;

  bool get isPending => status == LoanStatus.pending;

  /// What the institution would commit to if it approved as requested.
  double get projectedTotalPayable =>
      amountRequested + amountRequested * interestRate / 100;

  /// 0.0 – 1.0 of the total repaid so far.
  double get repaymentProgress {
    final total = totalPayable ?? 0;
    if (total <= 0) return 0;
    return (amountRepaid / total).clamp(0.0, 1.0);
  }

  bool get isOverdue =>
      isActive && dueDate != null && dueDate!.isBefore(DateTime.now());

  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }
}
