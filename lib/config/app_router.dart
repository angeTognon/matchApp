import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/screens/splash_screen.dart';
import 'package:amical_club/screens/auth/login_screen.dart';
import 'package:amical_club/screens/auth/register_screen.dart';
import 'package:amical_club/screens/auth/forgot_password_screen.dart';
import 'package:amical_club/screens/main/main_screen.dart';
import 'package:amical_club/screens/match/match_detail_screen.dart';
import 'package:amical_club/screens/match/match_score_screen.dart';
import 'package:amical_club/screens/match/match_requests_screen.dart';
import 'package:amical_club/screens/team/team_profile_screen.dart';
import 'package:amical_club/screens/chat/chat_screen.dart';
import 'package:amical_club/screens/contact/contact_screen.dart';
import 'package:amical_club/screens/map/map_screen.dart';
import 'package:amical_club/screens/settings/privacy_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Page non trouvée',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'La page "${state.uri}" n\'existe pas.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/main'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/match/:id',
        builder: (context, state) => MatchDetailScreen(
          matchId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/match/:id/score',
        builder: (context, state) => MatchScoreScreen(
          matchId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/match/:id/requests',
        builder: (context, state) => MatchRequestsScreen(
          matchId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/team/:id',
        builder: (context, state) => TeamProfileScreen(
          teamId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(
          chatId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/contact/:id',
        builder: (context, state) => ContactScreen(
          teamId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
    ],
  );
}