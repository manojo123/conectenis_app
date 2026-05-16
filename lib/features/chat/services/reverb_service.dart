import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';

final reverbServiceProvider = Provider<ReverbService>((ref) {
  return ReverbService(ref.watch(dioProvider));
});

class ReverbService {
  ReverbService(this._dio);

  final Dio _dio;
  PusherChannelsFlutter? _pusher;

  bool get isConfigured => Env.reverbEnabled;

  Future<void> subscribeToConversation({
    required int conversationId,
    required void Function(Map<String, dynamic> payload) onMessage,
  }) async {
    if (!isConfigured) return;

    _pusher ??= PusherChannelsFlutter.getInstance();
    await _pusher!.init(
      apiKey: Env.reverbAppKey,
      cluster: '',
      onAuthorizer: (channelName, socketId, options) async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/broadcasting/auth',
          data: {
            'socket_id': socketId,
            'channel_name': channelName,
          },
        );
        return response.data ?? {};
      },
    );
    await _pusher!.connect();
    await _pusher!.subscribe(
      channelName: 'private-conversation.$conversationId',
      onEvent: (event) {
        if (event.eventName == 'MessageSent') {
          onMessage(Map<String, dynamic>.from(event.data as Map));
        }
      },
    );
  }

  Future<void> disconnect() async {
    await _pusher?.disconnect();
    _pusher = null;
  }
}
