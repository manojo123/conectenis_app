import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/app/shell_scaffold.dart';
import 'package:conectenis_app/features/auth/presentation/login_screen.dart';
import 'package:conectenis_app/features/auth/presentation/onboarding_screen.dart';
import 'package:conectenis_app/features/auth/presentation/register_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = auth.isLoading;
      final user = auth.valueOrNull;
      final loggedIn = user != null;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final onOnboarding = state.matchedLocation == '/onboarding';

      if (isLoading) return null;

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) {
        return user.profileComplete ? '/' : '/onboarding';
      }
      if (loggedIn && !user.profileComplete && !onOnboarding) {
        return '/onboarding';
      }
      if (loggedIn && user.profileComplete && onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: '/chat',
        builder: (_, __) => const ChatListScreen(),
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
      GoRoute(path: '/matches/log', builder: (_, __) => const LogMatchScreen()),
      GoRoute(
        path: '/matches/history',
        builder: (_, __) => const MatchHistoryScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const MapScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/players',
                builder: (_, __) => const PlayersListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/courts',
                builder: (_, __) => const CourtsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
