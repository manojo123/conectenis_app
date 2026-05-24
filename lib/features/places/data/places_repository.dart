import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/place.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepository(
    dio: ref.watch(dioProvider),
    mock: ref.watch(mockApiServiceProvider),
  );
});

class PlacesRepository {
  PlacesRepository({required Dio dio, required MockApiService mock})
      : _dio = dio,
        _mock = mock;

  final Dio _dio;
  final MockApiService _mock;

  Future<List<Place>> nearby({
    required double lat,
    required double lng,
    double radiusKm = 50,
    String? name,
  }) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.places(lat: lat, lng: lng, name: name);
      final response = await _dio.get<List<dynamic>>(
        '/places/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radiusKm,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );
      return (response.data ?? [])
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Place> create({
    required String name,
    required double latitude,
    required double longitude,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.createPlace(name: name, latitude: latitude, longitude: longitude);
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/places',
        data: {'name': name, 'latitude': latitude, 'longitude': longitude},
      );
      return Place.fromJson(response.data!);
    });
  }

  Future<Place?> byId(int id) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.placeById(id);
      final response = await _dio.get<Map<String, dynamic>>('/places/$id');
      return Place.fromJson(response.data!);
    });
  }

  Future<Place> update({
    required int id,
    String? name,
    double? latitude,
    double? longitude,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.updatePlace(
          id: id,
          name: name,
          latitude: latitude,
          longitude: longitude,
        );
      }
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      final response = await _dio.put<Map<String, dynamic>>(
        '/places/$id',
        data: data,
      );
      return Place.fromJson(response.data!);
    });
  }

  Future<String> rate({
    required int id,
    required int stars,
    String? comment,
  }) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.ratePlace(id: id, stars: stars, comment: comment);
      final response = await _dio.post<Map<String, dynamic>>(
        '/places/$id/ratings',
        data: {
          'stars': stars,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return response.data!['message'] as String? ?? 'Avaliação salva.';
    });
  }

  Future<String> report({
    required int id,
    required PlaceReportReason reason,
    String? details,
  }) {
    return _guard(() async {
      if (Env.useMockApi) return 'Denúncia registrada.';
      final response = await _dio.post<Map<String, dynamic>>(
        '/places/$id/reports',
        data: {
          'reason': reason.value,
          'details': ?details,
        },
      );
      return response.data!['message'] as String? ?? 'Denúncia enviada.';
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
