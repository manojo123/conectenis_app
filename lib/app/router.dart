import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/app/router_refresh_notifier.dart';
import 'package:conectenis_app/app/shell_scaffold.dart';
import 'package:conectenis_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:conectenis_app/features/auth/presentation/legal_acceptance_screen.dart';
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
import 'package:conectenis_app/features/challenges/presentation/edit_public_challenge_screen.dart';
import 'package:conectenis_app/features/chat/presentation/chat_list_screen.dart';
import 'package:conectenis_app/features/chat/presentation/chat_thread_screen.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/features/achievements/presentation/achievements_screen.dart';
import 'package:conectenis_app/features/home/presentation/home_dashboard_screen.dart';
import 'package:conectenis_app/features/home/presentation/home_feed_screen.dart';
import 'package:conectenis_app/features/location/presentation/location_gated_home.dart';
import 'package:conectenis_app/features/map/presentation/map_screen.dart';
import 'package:conectenis_app/features/places/presentation/court_picker_screen.dart';
import 'package:conectenis_app/features/notifications/presentation/notifications_screen.dart';
import 'package:conectenis_app/features/places/presentation/create_place_screen.dart';
import 'package:conectenis_app/features/places/presentation/places_list_screen.dart';
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

Widget _buildHomeTab() {
  if (Env.useHomeFeed) {
    return LocationGatedHome(child: const HomeFeedScreen());
  }
  return LocationGatedHome(child: const HomeDashboardScreen());
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.read(routerRefreshListenableProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final isLoading = auth.isLoading;
      final user = auth.valueOrNull;
      final loggedIn = user != null;
      final isPublicAuth = _publicAuthPaths.contains(state.matchedLocation);
      final onOnboarding = state.matchedLocation == '/onboarding';
      final onLegalAcceptance = state.matchedLocation == '/legal-acceptance';

      if (isLoading) return null;

      if (!loggedIn && !isPublicAuth && !onOnboarding && !onLegalAcceptance) {
        return '/login';
      }
      if (loggedIn && isPublicAuth) {
        if (!user.hasAcceptedLegal) return '/legal-acceptance';
        return user.profileComplete ? '/' : '/onboarding';
      }
      if (loggedIn && !user.hasAcceptedLegal && !onLegalAcceptance) {
        return '/legal-acceptance';
      }
      if (loggedIn &&
          user.hasAcceptedLegal &&
          !user.profileComplete &&
          !onOnboarding &&
          state.matchedLocation != '/profile/edit') {
        return '/onboarding';
      }
      if (loggedIn && user.profileComplete && onOnboarding) return '/';
      if (loggedIn && user.hasAcceptedLegal && onLegalAcceptance) {
        return user.profileComplete ? '/' : '/onboarding';
      }
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
      GoRoute(path: '/legal-acceptance', builder: (_, _) => const LegalAcceptanceScreen()),
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
      GoRoute(
        path: '/courts-picker',
        builder: (_, state) => CourtPickerScreen(
          selectMode: state.uri.queryParameters['select'] == 'true',
        ),
      ),
      GoRoute(
        path: '/places-search',
        builder: (_, state) => PlacesListScreen(
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
        path: '/challenges/:id/edit',
        builder: (_, state) => EditPublicChallengeScreen(
          challengeId: int.parse(state.pathParameters['id']!),
        ),
      ),
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
      GoRoute(path: '/achievements', builder: (_, _) => const AchievementsScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/ranking', builder: (_, _) => const RankingScreen()),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => _buildHomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (_, _) => LocationGatedHome(child: const MapScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/challenges', builder: (_, _) => const ChallengesWallScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/ranking-tab', builder: (_, _) => const RankingScreen())],
          ),
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
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
