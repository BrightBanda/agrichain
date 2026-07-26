import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
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
