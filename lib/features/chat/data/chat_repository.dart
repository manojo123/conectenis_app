import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/features/chat/data/delete_message_scope.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/json_parsers.dart';
import 'package:conectenis_app/shared/models/message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    dio: ref.watch(dioProvider),
    mock: ref.watch(mockApiServiceProvider),
  );
});

class ChatRepository {
  ChatRepository({required Dio dio, required MockApiService mock})
      : _dio = dio,
        _mock = mock;

  final Dio _dio;
  final MockApiService _mock;

  Future<List<Conversation>> conversations() async {
    if (Env.useMockApi) return _mock.conversations();
    try {
      final response = await _dio.get<dynamic>('/conversations');
      return parseJsonList(response.data)
          .map(Conversation.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Conversation?> conversationById(int id) async {
    final list = await conversations();
    for (final conversation in list) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  Future<Conversation> start(int otherUserId, String otherName) async {
    if (Env.useMockApi) return _mock.startConversation(otherUserId, otherName);
    try {
      final response = await _dio.post<dynamic>(
        '/conversations',
        data: {'user_id': otherUserId},
      );
      return Conversation.fromJson(parseJsonObject(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Message>> messages(int conversationId, {int? currentUserId}) async {
    if (Env.useMockApi) {
      return _mock.messages(conversationId, currentUserId: currentUserId);
    }
    try {
      final response =
          await _dio.get<dynamic>('/conversations/$conversationId/messages');
      return parseJsonList(response.data)
          .map((json) => Message.fromJson(json, currentUserId: currentUserId))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Message> send({
    required int conversationId,
    required int userId,
    required String body,
  }) async {
    if (Env.useMockApi) {
      return _mock.sendMessage(
        conversationId: conversationId,
        userId: userId,
        body: body,
      );
    }
    try {
      final response = await _dio.post<dynamic>(
        '/messages',
        data: {'conversation_id': conversationId, 'body': body},
      );
      return Message.fromJson(parseJsonObject(response.data), currentUserId: userId);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteConversation(int id) async {
    if (Env.useMockApi) {
      await _mock.deleteConversation(id);
      return;
    }
    try {
      await _dio.delete('/conversations/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteMessage(int id, {required DeleteMessageScope scope}) async {
    if (Env.useMockApi) {
      await _mock.deleteMessage(id, scope: scope);
      return;
    }
    try {
      await _dio.delete('/messages/$id', data: {'scope': scope.value});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
