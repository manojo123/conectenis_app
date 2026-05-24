import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/network/session_provider.dart';
import 'package:conectenis_app/features/auth/data/auth_repository.dart';
import 'package:conectenis_app/features/auth/data/google_auth_service.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserProfile?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    ref.onDispose(() {
      ref.read(onUnauthorizedProvider.notifier).state = null;
    });

    // Register after build — Riverpod forbids modifying other providers during build().
    Future.microtask(() {
      ref.read(onUnauthorizedProvider.notifier).state = () {
        state = const AsyncData(null);
      };
    });

    final token = await ref.read(authRepositoryProvider).getToken();
    if (token == null) return null;
    try {
      return await ref.read(authRepositoryProvider).fetchCurrentUser();
    } catch (_) {
      await ref.read(authRepositoryProvider).logout();
      return null;
    }
  }

  Future<void> loginWithGoogle() async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      final idToken = await ref.read(googleAuthServiceProvider).signInForIdToken();
      if (idToken == null) {
        state = AsyncData(previous);
        return;
      }
      final user = await ref.read(authRepositoryProvider).socialLogin(
            provider: 'google',
            token: idToken,
          );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation,
          ),
    );
  }

  Future<String> forgotPassword(String email) async {
    return ref.read(authRepositoryProvider).forgotPassword(email: email);
  }

  Future<String> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return ref.read(authRepositoryProvider).resetPassword(
          token: token,
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
        );
  }

  Future<void> refreshUser() async {
    final user = await ref.read(authRepositoryProvider).fetchCurrentUser();
    state = AsyncData(user);
  }

  Future<void> updateProfile(UserProfile profile) async {
    final updated = await ref.read(authRepositoryProvider).saveProfile(profile);
    state = AsyncData(updated);
  }

  Future<void> logout() async {
    await ref.read(googleAuthServiceProvider).signOut();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
