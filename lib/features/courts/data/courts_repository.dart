import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/features/auth/data/auth_repository.dart';
import 'package:conectenis_app/shared/models/court.dart';

final courtsRepositoryProvider = Provider<CourtsRepository>((ref) {
  return CourtsRepository(
    dio: ref.watch(dioProvider),
    mock: ref.watch(mockApiServiceProvider),
  );
});

class CourtsRepository {
  CourtsRepository({required Dio dio, required MockApiService mock})
      : _dio = dio,
        _mock = mock;

  final Dio _dio;
  final MockApiService _mock;

  Future<List<Court>> list({double? lat, double? lng}) async {
    if (Env.useMockApi) return _mock.courts(lat: lat, lng: lng);
    final response = await _dio.get<List<dynamic>>(
      lat != null ? '/courts/nearby' : '/courts',
      queryParameters: lat != null ? {'lat': lat, 'lng': lng} : null,
    );
    return (response.data ?? [])
        .map((e) => Court.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Court?> byId(int id) async {
    if (Env.useMockApi) return _mock.courtById(id);
    final response = await _dio.get<Map<String, dynamic>>('/courts/$id');
    return Court.fromJson(response.data!);
  }
}
