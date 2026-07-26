import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/ledger.dart';

/// Talks to `/blockchain/*`.
///
/// Every read is public: the point of a ledger is that anybody can audit it
/// without holding a token.
class BlockchainRepository {
  final Dio _dio;

  const BlockchainRepository(this._dio);

  /// `GET /blockchain/chain` — newest block first.
  Future<List<LedgerBlock>> fetchChain({int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.chain,
        queryParameters: {'limit': limit, 'offset': offset},
        options: Options(extra: publicRequest),
      );
      final blocks = response.data?['blocks'] as List? ?? const [];
      return blocks
          .whereType<Map>()
          .map((json) => LedgerBlock.fromJson(json.cast<String, dynamic>()))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `GET /blockchain/chain/stats`
  Future<ChainStats> fetchStats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.chainStats,
        options: Options(extra: publicRequest),
      );
      return ChainStats.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `GET /blockchain/verify` — re-hashes every block and checks every link.
  Future<ChainIntegrity> verifyChain() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.chainVerify,
        options: Options(extra: publicRequest),
      );
      return ChainIntegrity.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `POST /blockchain/verify-record` — re-hashes a live row against the chain.
  Future<RecordVerification> verifyRecord({
    required LedgerEntityType entityType,
    required String entityId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.verifyRecord,
        data: {'entity_type': entityType.wireValue, 'entity_id': entityId},
        options: Options(extra: publicRequest),
      );
      return RecordVerification.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `GET /blockchain/records/{type}/{id}` — a record's on-chain audit trail.
  Future<List<LedgerBlock>> fetchRecordBlocks({
    required LedgerEntityType entityType,
    required String entityId,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.recordBlocks(entityType.wireValue, entityId),
        options: Options(extra: publicRequest),
      );
      return (response.data ?? const [])
          .whereType<Map>()
          .map((json) => LedgerBlock.fromJson(json.cast<String, dynamic>()))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Demo: corrupt a block so the integrity check has something to catch.
  Future<ChainIntegrity> demoTamperBlock(int index) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.demoTamperBlock(index),
        options: Options(extra: publicRequest),
      );
      return ChainIntegrity.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Demo: quietly edit a database row, leaving the chain itself intact.
  Future<RecordVerification> demoTamperRecord({
    required LedgerEntityType entityType,
    required String entityId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.demoTamperRecord,
        data: {'entity_type': entityType.wireValue, 'entity_id': entityId},
        options: Options(extra: publicRequest),
      );
      return RecordVerification.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final blockchainRepositoryProvider = Provider<BlockchainRepository>(
  (ref) => BlockchainRepository(ref.watch(dioProvider)),
);
