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
import 'package:conectenis_app/features/chat/presentation/chat_list_screen.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/features/courts/presentation/court_detail_screen.dart';
import 'package:conectenis_app/features/courts/presentation/courts_list_screen.dart';
import 'package:conectenis_app/features/map/presentation/map_screen.dart';
import 'package:conectenis_app/features/matches/presentation/log_match_screen.dart';
import 'package:conectenis_app/features/matches/presentation/match_history_screen.dart';
import 'package:conectenis_app/features/players/presentation/player_detail_screen.dart';
import 'package:conectenis_app/features/players/presentation/players_list_screen.dart';
import 'package:conectenis_app/features/profile/presentation/profile_screen.dart';

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
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
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
        path: '/chat',
        builder: (_, _) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => ChatThreadScreen(
              conversationId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/players/:id',
        builder: (_, state) => PlayerDetailScreen(
          playerId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/courts/:id',
        builder: (_, state) => CourtDetailScreen(
          courtId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/matches/log', builder: (_, _) => const LogMatchScreen()),
      GoRoute(
        path: '/matches/history',
        builder: (_, _) => const MatchHistoryScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const MapScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/players',
                builder: (_, _) => const PlayersListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/courts',
                builder: (_, _) => const CourtsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
