import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/app/shell_scaffold.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/presentation/login_screen.dart';
import 'package:conectenis_app/features/auth/presentation/onboarding_screen.dart';
import 'package:conectenis_app/features/auth/presentation/register_screen.dart';
import 'package:conectenis_app/features/auth/presentation/reset_password_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/features/challenges/presentation/challenge_detail_screen.dart';
import 'package:conectenis_app/features/challenges/presentation/challenge_evaluation_screen.dart';
import 'package:conectenis_app/features/challenges/presentation/challenges_wall_screen.dart';
import 'package:conectenis_app/features/challenges/presentation/create_direct_challenge_screen.dart';
import 'package:conectenis_app/features/challenges/presentation/create_public_challenge_screen.dart';
import 'package:conectenis_app/features/chat/presentation/chat_list_screen.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/features/map/presentation/map_screen.dart';
import 'package:conectenis_app/features/notifications/presentation/notifications_screen.dart';
import 'package:conectenis_app/features/places/presentation/create_place_screen.dart';
import 'package:conectenis_app/features/places/presentation/place_detail_screen.dart';
import 'package:conectenis_app/features/players/presentation/player_detail_screen.dart';
import 'package:conectenis_app/features/players/presentation/players_list_screen.dart';
import 'package:conectenis_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:conectenis_app/features/profile/presentation/profile_screen.dart';
import 'package:conectenis_app/features/ranking/presentation/ranking_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

const _publicAuthPaths = {
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
};

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = auth.isLoading;
      final user = auth.valueOrNull;
      final loggedIn = user != null;
      final isPublicAuth = _publicAuthPaths.contains(state.matchedLocation);
      final onOnboarding = state.matchedLocation == '/onboarding';

      if (isLoading) return null;

      if (!loggedIn && !isPublicAuth) return '/login';
      if (loggedIn && isPublicAuth) {
        return user.profileComplete ? '/' : '/onboarding';
      }
      if (loggedIn && !user.profileComplete && !onOnboarding) {
        return '/onboarding';
      }
      if (loggedIn && user.profileComplete && onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(token: token, email: email);
        },
      ),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/players/:id',
        builder: (_, state) => PlayerDetailScreen(playerId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/players-search',
        builder: (_, state) => PlayersListScreen(
          selectMode: state.uri.queryParameters['select'] == 'true',
        ),
      ),
      GoRoute(path: '/places/new', builder: (_, _) => const CreatePlaceScreen()),
      GoRoute(
        path: '/places/:id',
        builder: (_, state) => PlaceDetailScreen(placeId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/challenges/new/direct',
        builder: (_, state) => CreateDirectChallengeScreen(
          opponentId: int.tryParse(state.uri.queryParameters['playerId'] ?? ''),
        ),
      ),
      GoRoute(path: '/challenges/new/public', builder: (_, _) => const CreatePublicChallengeScreen()),
      GoRoute(
        path: '/challenges/:id/evaluation',
        builder: (_, state) => ChallengeEvaluationScreen(
          challengeId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/challenges/:id',
        builder: (_, state) => ChallengeDetailScreen(
          challengeId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/ranking', builder: (_, _) => const RankingScreen()),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const MapScreen())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (_, _) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) {
                      final conversation = state.extra as Conversation?;
                      return ChatThreadScreen(
                        conversationId: int.parse(state.pathParameters['id']!),
                        otherUserId: conversation?.otherUserId,
                        otherUserName: conversation?.otherUserName,
                        otherAvatarUrl: conversation?.otherAvatarUrl,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/challenges', builder: (_, _) => const ChallengesWallScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});
