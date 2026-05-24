import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';
import 'package:conectenis_app/core/storage/profile_storage.dart';
import 'package:conectenis_app/core/storage/token_storage.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    profileStorage: ref.watch(profileStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required Dio dio,
    required TokenStorage tokenStorage,
    required ProfileStorage profileStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _profileStorage = profileStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final ProfileStorage _profileStorage;

  Future<String?> getToken() => _tokenStorage.getToken();

  Future<UserProfile> login({
    required String email,
    required String password,
  }) {
    return _guard(
      () async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {
            'email': email,
            'password': password,
            'device_name': _deviceName,
          },
        );
        return _saveTokenAndProfile(response.data!);
      },
      fallbackMessage: 'E-mail ou senha inválidos.',
    );
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'device_name': _deviceName,
        },
      );
      return _saveTokenAndProfile(response.data!);
    });
  }

  Future<UserProfile> fetchCurrentUser() {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>('/auth/user');
      return _mergeWithLocalProfile(UserProfile.fromLaravelUser(response.data!));
    });
  }

  Future<String> forgotPassword({required String email}) {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return response.data!['message'] as String? ??
          'Se o e-mail existir, enviaremos um link para redefinir a senha.';
    });
  }

  Future<String> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return response.data!['message'] as String? ?? 'Senha redefinida com sucesso.';
    });
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    final wasComplete = profile.profileComplete;
    await _profileStorage.write(profile);

    if (!Env.useMockApi) {
      final response = await _dio.put<Map<String, dynamic>>(
        '/user/profile',
        data: profile.toJson(),
      );
      final merged = await _mergeWithLocalProfile(
        UserProfile.fromJson(response.data ?? profile.toJson()),
      );
      final result = merged.copyWith(profileComplete: wasComplete || merged.profileComplete);
      await _profileStorage.write(result);
      return result;
    }

    final complete = profile.name.isNotEmpty &&
        profile.age != null &&
        profile.age! >= 10 &&
        (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty);
    return profile.copyWith(profileComplete: wasComplete || complete);
  }

  Future<String> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post<Map<String, dynamic>>('/user/avatar', data: formData);
    return response.data!['avatar_url'] as String;
  }

  Future<UserProfile> socialLogin({
    required String provider,
    required String token,
  }) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/social/$provider',
        data: {'token': token, 'device_name': _deviceName},
      );
      return _saveTokenAndProfile(response.data!);
    });
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _tokenStorage.clearToken();
    await _profileStorage.clear();
  }

  static String get _deviceName => Platform.isAndroid
      ? 'android'
      : Platform.isIOS
          ? 'ios'
          : 'desktop';

  Future<UserProfile> _saveTokenAndProfile(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    await _tokenStorage.saveToken(token);

    final userJson = data['user'] as Map<String, dynamic>;
    final profile =
        await _mergeWithLocalProfile(UserProfile.fromLaravelUser(userJson));
    await _profileStorage.write(profile);
    return profile;
  }

  Future<UserProfile> _mergeWithLocalProfile(UserProfile profile) async {
    final local = await _profileStorage.read();
    if (local != null && local.id == profile.id) {
      return profile.copyWith(
        age: local.age,
        ntrpRating: local.ntrpRating,
        gender: local.gender,
        profession: local.profession,
        city: local.city,
        state: local.state,
        addressLine: local.addressLine,
        playStyle: local.playStyle,
        avatarUrl: local.avatarUrl ?? profile.avatarUrl,
        latitude: local.latitude,
        longitude: local.longitude,
        profileComplete: profile.profileComplete || local.profileComplete,
      );
    }
    return profile;
  }

  Future<T> _guard<T>(
    Future<T> Function() action, {
    String? fallbackMessage,
  }) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallbackMessage: fallbackMessage);
    }
  }
}
