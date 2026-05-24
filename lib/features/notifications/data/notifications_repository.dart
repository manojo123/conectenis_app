import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(dio: ref.watch(dioProvider));
});

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.challengeId,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final String message;
  final int? challengeId;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: json['id'] as String? ?? '',
      type: data['type'] as String? ?? json['type'] as String? ?? '',
      message: data['message'] as String? ?? '',
      challengeId: data['challenge_id'] as int?,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}

class NotificationsRepository {
  NotificationsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<AppNotification>> list() async {
    if (Env.useMockApi) {
      return const [
        AppNotification(
          id: '1',
          type: 'challenge_received',
          message: 'Você recebeu um novo desafio.',
          challengeId: 1,
        ),
      ];
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>('/notifications');
      final list = response.data?['data'] as List<dynamic>? ?? [];
      return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markRead(String id) async {
    if (Env.useMockApi) return;
    try {
      await _dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
