import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/session_provider.dart';
import 'package:conectenis_app/core/storage/profile_storage.dart';
import 'package:conectenis_app/core/storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final profileStorageProvider = Provider<ProfileStorage>((ref) => ProfileStorage());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(tokenStorageProvider).getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await ref.read(tokenStorageProvider).clearToken();
          final onUnauthorized = ref.read(onUnauthorizedProvider);
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
