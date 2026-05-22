import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/play_invitation.dart';

final playInvitationsRepositoryProvider = Provider<PlayInvitationsRepository>((ref) {
  return PlayInvitationsRepository(
    dio: ref.watch(dioProvider),
    mock: ref.watch(mockApiServiceProvider),
  );
});

class PlayInvitationsRepository {
  PlayInvitationsRepository({required Dio dio, required MockApiService mock})
      : _dio = dio,
        _mock = mock;

  final Dio _dio;
  final MockApiService _mock;

  Future<List<PlayInvitation>> list({InvitationListRole role = InvitationListRole.all}) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.playInvitations(role: role);
      final response = await _dio.get<List<dynamic>>(
        '/play-invitations',
        queryParameters: {'role': role.value},
      );
      return (response.data ?? [])
          .map((e) => PlayInvitation.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<PlayInvitation> byId(int id) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.playInvitationById(id);
      final response = await _dio.get<Map<String, dynamic>>('/play-invitations/$id');
      return PlayInvitation.fromJson(response.data!);
    });
  }

  Future<PlayInvitation> create({
    required int inviteeId,
    required int placeId,
    required DateTime scheduledAt,
    String? message,
  }) {
    return _guard(() async {
      if (Env.useMockApi) {
        return _mock.createPlayInvitation(
          inviteeId: inviteeId,
          placeId: placeId,
          scheduledAt: scheduledAt,
          message: message,
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/play-invitations',
        data: {
          'invitee_id': inviteeId,
          'place_id': placeId,
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );
      return PlayInvitation.fromJson(response.data!);
    });
  }

  Future<PlayInvitation> accept(int id) => _action(id, 'accept');

  Future<PlayInvitation> decline(int id) => _action(id, 'decline');

  Future<PlayInvitation> cancel(int id) => _action(id, 'cancel');

  Future<PlayInvitation> complete(int id) => _action(id, 'complete');

  Future<String> ratePlayer({
    required int id,
    required int stars,
    String? comment,
  }) {
    return _guard(() async {
      if (Env.useMockApi) return 'Avaliação salva.';
      final response = await _dio.post<Map<String, dynamic>>(
        '/play-invitations/$id/rate-player',
        data: {
          'stars': stars,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return response.data!['message'] as String? ?? 'Avaliação salva.';
    });
  }

  Future<String> reportPlayer({
    required int id,
    required UserReportReason reason,
    String? details,
  }) {
    return _guard(() async {
      if (Env.useMockApi) return 'Denúncia enviada.';
      final response = await _dio.post<Map<String, dynamic>>(
        '/play-invitations/$id/report-player',
        data: {
          'reason': reason.value,
          if (details != null) 'details': details,
        },
      );
      return response.data!['message'] as String? ?? 'Denúncia enviada.';
    });
  }

  Future<PlayInvitation> _action(int id, String action) {
    return _guard(() async {
      if (Env.useMockApi) return _mock.playInvitationAction(id, action);
      final response = await _dio.post<Map<String, dynamic>>(
        '/play-invitations/$id/$action',
      );
      return PlayInvitation.fromJson(response.data!);
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
