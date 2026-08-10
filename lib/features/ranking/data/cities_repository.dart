import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/city.dart';

final citiesRepositoryProvider = Provider<CitiesRepository>((ref) {
  return CitiesRepository(dio: ref.watch(dioProvider));
});

/// Backend endpoint requested but not shipped yet - see
/// docs/BACKEND_PROMPT_RANKING_MAP_NOTIFICATIONS.md §3.
class CitiesRepository {
  CitiesRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<City>> search(String query) async {
    if (Env.useMockApi) {
      const mock = [
        City(id: 1, name: 'Jundiaí', state: 'SP'),
        City(id: 2, name: 'Cerquilho', state: 'SP'),
        City(id: 3, name: 'Campinas', state: 'SP'),
        City(id: 4, name: 'São Paulo', state: 'SP'),
      ];
      if (query.trim().isEmpty) return mock;
      final q = query.trim().toLowerCase();
      return mock.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    try {
      final response = await _dio.get<List<dynamic>>(
        '/cities',
        queryParameters: {if (query.trim().isNotEmpty) 'search': query.trim()},
      );
      return (response.data ?? [])
          .map((e) => City.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
