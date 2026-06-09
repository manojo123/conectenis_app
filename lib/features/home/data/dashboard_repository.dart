import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/features/home/models/dashboard_matchmaking.dart';
import 'package:conectenis_app/features/home/models/dashboard_stats.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    dio: ref.watch(dioProvider),
    mock: ref.watch(mockApiServiceProvider),
  );
});

class DashboardRepository {
  DashboardRepository({
    required Dio dio,
    required MockApiService mock,
  })  : _dio = dio,
        _mock = mock;

  final Dio _dio;
  final MockApiService _mock;

  static const allowedRadiiKm = [5, 10, 25];

  Future<DashboardMatchmaking> fetchMatchmaking({required int radiusKm}) {
    return _guard(() async {
      if (!allowedRadiiKm.contains(radiusKm)) {
        throw ApiException('Raio inválido. Use 5, 10 ou 25 km.');
      }
      if (Env.useMockApi) {
        return _mock.dashboardMatchmaking(radiusKm: radiusKm);
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/dashboard/matchmaking',
        queryParameters: {'radius_km': radiusKm},
      );
      return DashboardMatchmaking.fromJson(parseJsonObject(response.data));
    });
  }

  Future<DashboardStats> fetchStats() {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.dashboardStats();
      }
      final response = await _dio.get<Map<String, dynamic>>('/dashboard/stats');
      return DashboardStats.fromJson(parseJsonObject(response.data));
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
