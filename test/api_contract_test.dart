import 'dart:convert';

import 'package:agri/src/core/network/api_exception.dart';
import 'package:agri/src/data/models/auth_session.dart';
import 'package:agri/src/data/models/enums.dart';
import 'package:agri/src/data/models/product.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payloads captured from the running FastAPI backend, so the models are
/// tested against what the API actually sends rather than what we assume.
void main() {
  group('AuthSession.fromJson', () {
    test('parses a real POST /auth/login response', () {
      final json =
          jsonDecode('''
{"access_token":"eyJhbGciOiJIUzI1NiJ9.abc.def","token_type":"bearer",
"user":{"id":"6abde022-0c01-488a-8e2f-f63cad45e7b6","phone_number":"1234",
"role":"FARMER","is_verified":true,"created_at":"2026-07-25T19:25:35.772880",
"farmer_profile":{"id":"1f88b20e-43ec-4137-8ed0-8c93bd63e605",
"full_name":"mosh mosh","national_id_number":"TEST12345678ABCD","gender":"MALE",
"district":"Test District","traditional_authority":"Test Authority",
"village":"Test Village","profile_photo_url":null,"id_front_photo_url":null,
"id_back_photo_url":null,"lending_score":300}}}
''')
              as Map<String, dynamic>;

      final session = AuthSession.fromJson(json);

      expect(session.accessToken, isNotEmpty);
      expect(session.user.phoneNumber, '1234');
      expect(session.user.role, UserRole.farmer);
      expect(session.user.isVerified, isTrue);
      expect(session.user.createdAt?.year, 2026);
      expect(session.user.farmerProfile?.fullName, 'mosh mosh');
      expect(session.user.farmerProfile?.gender, Gender.male);
      expect(session.user.farmerProfile?.lendingScore, 300);
    });

    test('round-trips through the secure-storage cache', () {
      const raw = {
        'id': 'abc',
        'phone_number': '1234',
        'role': 'FARMER',
        'is_verified': true,
        'created_at': '2026-07-25T19:25:35.772880',
        'farmer_profile': {
          'id': 'p1',
          'full_name': 'Kondwani Banda',
          'national_id_number': 'MW1',
          'gender': 'FEMALE',
          'district': 'Lilongwe',
          'traditional_authority': 'T/A Kalolo',
          'village': 'Msinja',
          'profile_photo_url': null,
          'id_front_photo_url': null,
          'id_back_photo_url': null,
          'lending_score': 420,
        },
      };

      final session = AuthSession.fromJson({
        'access_token': 't',
        'user': raw,
      });
      // What TokenStorage writes must parse back identically.
      final restored = AuthSession.fromJson({
        'access_token': 't',
        'user': jsonDecode(jsonEncode(session.user.toJson())),
      }).user;

      expect(restored.id, 'abc');
      expect(restored.farmerProfile?.gender, Gender.female);
      expect(restored.farmerProfile?.lendingScore, 420);
      expect(restored.displayName, 'Kondwani Banda');
    });
  });

  group('Product.fromJson', () {
    test('parses price_per_unit sent as a string by Pydantic', () {
      final json =
          jsonDecode('''
{"id":"424374d3-ad21-45d7-8dcf-15e5ce6b8c03",
"user_id":"6abde022-0c01-488a-8e2f-f63cad45e7b6","product_type":"CROPS_PRODUCE",
"product_name":"Dry White Hybrid Maize","unit_type":"BAG_50KG",
"district":"Lilongwe","price_per_unit":"45000.00","quantity_available":25,
"description":"High quality verified farm product direct from farm.",
"created_at":"2026-07-25T21:15:32.970797","updated_at":"2026-07-25T21:15:32.970797"}
''')
              as Map<String, dynamic>;

      final product = Product.fromJson(json);

      expect(product.pricePerUnit, 45000.0);
      expect(product.productType, ProductType.cropsProduce);
      expect(product.unitType, UnitType.bag50kg);
      expect(product.quantityAvailable, 25);
      expect(product.formattedPrice, 'MK 45,000.00');
    });

    test('also accepts a numeric price', () {
      final product = Product.fromJson({
        'id': 'x',
        'user_id': 'y',
        'product_type': 'LIVESTOCK_ANIMALS',
        'product_name': 'Goat',
        'unit_type': 'PIECE',
        'district': 'Mzuzu',
        'price_per_unit': 1250.5,
        'quantity_available': 3,
      });

      expect(product.pricePerUnit, 1250.5);
      expect(product.formattedPrice, 'MK 1,250.50');
      expect(product.productType, ProductType.livestockAnimals);
    });
  });

  group('ApiException', () {
    test('reads FastAPI HTTPException detail', () {
      final error = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 400,
            data: const {
              'detail': 'A user with this phone number is already registered.',
            },
          ),
        ),
      );

      expect(error.statusCode, 400);
      expect(error.message, contains('already registered'));
    });

    test('flattens a 422 validation detail list', () {
      final error = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/products'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/products'),
            statusCode: 422,
            data: const {
              'detail': [
                {
                  'type': 'missing',
                  'loc': ['body', 'product_type'],
                  'msg': 'Field required',
                },
                {
                  'type': 'missing',
                  'loc': ['body', 'product_name'],
                  'msg': 'Field required',
                },
              ],
            },
          ),
        ),
      );

      expect(error.message, contains('product_type: Field required'));
      expect(error.message, contains('product_name: Field required'));
    });

    test('reports an unreachable server plainly', () {
      final error = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/products'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(error.message, contains('Cannot reach'));
    });
  });
}
