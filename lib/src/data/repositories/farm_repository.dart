import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/enums.dart';
import '../models/harvest.dart';
import '../models/lending_score.dart';
import '../models/loan.dart';
import '../models/loan_product.dart';
import '../models/score_history.dart';

/// Reads the farmer's own agricultural and financial record.
///
/// All three endpoints are authenticated and scoped to the caller by the
/// backend, so there is no user id to pass.
class FarmRepository {
  final Dio _dio;

  const FarmRepository(this._dio);

  /// `GET /harvests`
  Future<List<Harvest>> fetchHarvests() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.harvests,
      );
      final items = response.data?['harvests'] as List? ?? const [];
      return items
          .whereType<Map>()
          .map((json) => Harvest.fromJson(json.cast<String, dynamic>()))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `POST /harvests` — records a harvest and anchors it to the ledger (FR-07).
  ///
  /// The response carries the block that attests to it, which is what makes the
  /// record verifiable later.
  Future<({Harvest harvest, int? blockIndex, String? blockHash})> recordHarvest({
    required String cropName,
    required double quantity,
    required UnitType unitType,
    required DateTime harvestDate,
    required String season,
    required String district,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.harvests,
        data: {
          'crop_name': cropName,
          'quantity': quantity,
          'unit_type': unitType.wireValue,
          // The API expects a plain date, not a timestamp.
          'harvest_date': harvestDate.toIso8601String().split('T').first,
          'season': season,
          'district': district,
        },
      );
      final body = response.data ?? const {};
      final harvest = (body['harvest'] as Map?)?.cast<String, dynamic>();
      return (
        harvest: Harvest.fromJson(harvest ?? const {}),
        blockIndex: body['block_index'] as int?,
        blockHash: body['block_hash'] as String?,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `GET /loans/mine`
  Future<List<Loan>> fetchMyLoans() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.myLoans,
      );
      final items = response.data?['loans'] as List? ?? const [];
      return items
          .whereType<Map>()
          .map((json) => Loan.fromJson(json.cast<String, dynamic>()))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `GET /lending-score` — recalculated server-side on every read.
  Future<LendingScore> fetchLendingScore() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.lendingScore,
      );
      return LendingScore.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `GET /lending-score/history` — how the score moved over time (FR-13).
  Future<List<ScoreHistoryEntry>> fetchScoreHistory() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.lendingScoreHistory,
      );
      final items = response.data?['entries'] as List? ?? const [];
      return items
          .whereType<Map>()
          .map(
            (json) => ScoreHistoryEntry.fromJson(json.cast<String, dynamic>()),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `GET /loan-products` — the public loan marketplace (FR-15).
  Future<List<LoanProduct>> fetchLoanProducts() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.loanProducts,
        options: Options(extra: publicRequest),
      );
      final items = response.data?['loan_products'] as List? ?? const [];
      return items
          .whereType<Map>()
          .map((json) => LoanProduct.fromJson(json.cast<String, dynamic>()))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `POST /loans/apply` — submit an application (FR-16).
  Future<Loan> applyForLoan({
    required String loanProductId,
    required double amount,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.applyForLoan,
        data: {'loan_product_id': loanProductId, 'amount_requested': amount},
      );
      return Loan.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `GET /loans/applications` — applications against this institution's
  /// products. Requires the FINANCIAL_INSTITUTION role.
  Future<List<Loan>> fetchApplications() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.loanApplications,
      );
      final items = response.data?['loans'] as List? ?? const [];
      return items
          .whereType<Map>()
          .map((json) => Loan.fromJson(json.cast<String, dynamic>()))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `POST /loans/{id}/decision` — approve or decline (FR-18).
  ///
  /// An approval anchors the loan agreement to the ledger server-side.
  Future<Loan> decideLoan({
    required String loanId,
    required bool approve,
    double? amountApproved,
    String? note,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.loanDecision(loanId),
        data: {
          'approve': approve,
          if (amountApproved != null) 'amount_approved': amountApproved,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return Loan.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `POST /loans/{id}/repayments`
  Future<void> repayLoan({
    required String loanId,
    required double amount,
    required String reference,
    String method = 'MOBILE_MONEY',
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.loanRepayments(loanId),
        data: {
          'amount': amount,
          'method': method,
          'transaction_reference': reference,
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final farmRepositoryProvider = Provider<FarmRepository>(
  (ref) => FarmRepository(ref.watch(dioProvider)),
);
