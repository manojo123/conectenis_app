import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
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
    final response = await _dio.get<List<dynamic>>('/conversations');
    return (response.data ?? [])
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> start(int otherUserId, String otherName) async {
    if (Env.useMockApi) return _mock.startConversation(otherUserId, otherName);
    final response = await _dio.post<Map<String, dynamic>>(
      '/conversations',
      data: {'user_id': otherUserId},
    );
    return Conversation.fromJson(response.data!);
  }

  Future<List<Message>> messages(int conversationId, {int? currentUserId}) async {
    if (Env.useMockApi) {
      return _mock.messages(conversationId, currentUserId: currentUserId);
    }
    final response =
        await _dio.get<List<dynamic>>('/conversations/$conversationId/messages');
    return (response.data ?? [])
        .map(
          (e) => Message.fromJson(
            e as Map<String, dynamic>,
            currentUserId: currentUserId,
          ),
        )
        .toList();
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
    final response = await _dio.post<Map<String, dynamic>>(
      '/messages',
      data: {'conversation_id': conversationId, 'body': body},
    );
    return Message.fromJson(response.data!, currentUserId: userId);
  }
}
