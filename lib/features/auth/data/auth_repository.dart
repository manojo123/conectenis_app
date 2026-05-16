import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/data/mock_api_service.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/core/storage/profile_storage.dart';
import 'package:conectenis_app/core/storage/token_storage.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

final mockApiServiceProvider = Provider<MockApiService>((ref) => MockApiService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    profileStorage: ref.watch(profileStorageProvider),
    mockApi: ref.watch(mockApiServiceProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required Dio dio,
    required TokenStorage tokenStorage,
    required ProfileStorage profileStorage,
    required MockApiService mockApi,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _profileStorage = profileStorage,
        _mockApi = mockApi;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final ProfileStorage _profileStorage;
  final MockApiService _mockApi;

  Future<String?> getToken() => _tokenStorage.getToken();

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sanctum/token',
      data: {
        'email': email,
        'password': password,
        'device_name': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : 'desktop',
      },
    );

    final token = response.data!['token'] as String;
    await _tokenStorage.saveToken(token);

    return fetchCurrentUser();
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (Env.useMockApi) {
      final profile = await _mockApi.registerMock(
        name: name,
        email: email,
        password: password,
      );
      await _tokenStorage.saveToken('mock_token_${profile.id}');
      await _profileStorage.write(profile);
      return profile;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    final token = response.data!['token'] as String;
    await _tokenStorage.saveToken(token);
    return fetchCurrentUser();
  }

  Future<UserProfile> fetchCurrentUser() async {
    final token = await _tokenStorage.getToken();
    if (token != null && token.startsWith('mock_token_')) {
      final local = await _profileStorage.read();
      if (local != null) return local;
    }

    final response = await _dio.get<Map<String, dynamic>>('/user');
    var profile = UserProfile.fromLaravelUser(response.data!);

    final local = await _profileStorage.read();
    if (local != null && local.id == profile.id) {
      profile = profile.copyWith(
        age: local.age,
        skillLevel: local.skillLevel,
        playStyle: local.playStyle,
        avatarUrl: local.avatarUrl,
        latitude: local.latitude,
        longitude: local.longitude,
        profileComplete: local.profileComplete,
      );
    }
    return profile;
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    final complete = profile.name.isNotEmpty &&
        profile.age != null &&
        profile.age! > 0;

    final updated = profile.copyWith(profileComplete: complete);
    await _profileStorage.write(updated);

    if (!Env.useMockApi) {
      try {
        await _dio.put('/user/profile', data: updated.toJson());
      } catch (_) {
        // API endpoint not live yet — local storage is enough for MVP.
      }
    }
    return updated;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (_) {}
    await _tokenStorage.clearToken();
    await _profileStorage.clear();
  }
}
