import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/address_lookup.dart';
import 'package:conectenis_app/shared/utils/postal_code.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(dio: ref.watch(dioProvider));
});

class AddressRepository {
  AddressRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<AddressLookup> lookupPostalCode(String postalCode) async {
    final digits = normalizePostalCode(postalCode);
    if (digits.length != 8) {
      throw ApiException('CEP inválido. Informe 8 dígitos.');
    }

    if (Env.useMockApi) {
      return _mockLookup(digits);
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/address/postal-code/$digits',
      );
      return AddressLookup.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallbackMessage: 'Não foi possível consultar o CEP.',
      );
    }
  }

  AddressLookup _mockLookup(String digits) {
    return AddressLookup(
      postalCode: formatPostalCode(digits),
      street: 'Avenida Paulista',
      neighborhood: 'Bela Vista',
      city: 'São Paulo',
      state: 'SP',
      stateName: 'São Paulo',
      country: 'BR',
      ddd: '11',
      ibge: '3550308',
    );
  }
}
