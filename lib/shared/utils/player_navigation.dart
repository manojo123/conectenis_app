import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';

void openPlayerProfile(BuildContext context, WidgetRef ref, int playerId) {
  final currentUserId = ref.read(authStateProvider).value?.id;
  if (currentUserId != null && currentUserId == playerId) {
    context.go('/profile');
    return;
  }
  context.push('/players/$playerId');
}
